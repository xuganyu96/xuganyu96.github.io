---
layout: post
title: "Airflow scheduler race condition"
date: 2023-06-24
categories: python
---

While working on upgrading the Airflow cluster at my company, I encountered a strange problem: when the number of DAGs turned on is small, they run just fine, but when there are ~70 DAGs running at the same time with about ~500 tasks scheduled at any given moment, the tasks start failing. When the task instance is manually clared, they will succeed upon subsequent runs.

The task logs showed that the task instance terminated itself:

```log
[2023-06-21, 16:55:15 UTC] {local_task_job_runner.py:291} WARNING - State of this instance has been externally set to None. Terminating instance.
[2023-06-21, 16:55:15 UTC] {process_utils.py:131} INFO - Sending Signals.SIGTERM to group 28. PIDs of all processes in the group: [28]
[2023-06-21, 16:55:15 UTC] {process_utils.py:86} INFO - Sending the signal Signals.SIGTERM to group 28
[2023-06-21, 16:55:15 UTC] {taskinstance.py:1517} ERROR - Received SIGTERM. Terminating subprocesses.
```

Resolving this issue led me to dig a bit deeper into Airflow's source code, and I would like share what I learned with this post.

# Context
WIP

# The troubleshooting process

## Airflow Job heartbeat
My first clue came from the log message:

> State of this instance as been externally set to None. Terminating instance

Searchin through [Airflow's code base](https://github.dev/apache/airflow/tree/2.6.2/airflow), we can find the location [where](https://github.com/apache/airflow/blob/d2f0d100dac4a95d664309d7b04a6a6110367446/airflow/jobs/local_task_job_runner.py#L236) this log message is created, which is the `heartbeat_callback` method within the `airflow.jobs.local_task_job_runner.LocalJobRunner` class. The `heartbeat_callback` method is called within the `airflow.jobs.job.perform_heartbeat` function, whose implementation looks like [this](https://github.com/apache/airflow/blob/d2f0d100dac4a95d664309d7b04a6a6110367446/airflow/jobs/job.py#L325):

```python
def perform_heartbeat(
    job: Job | JobPydantic, heartbeat_callback: Callable[[Session], None], only_if_necessary: bool
) -> None:
    """
    Performs heartbeat for the Job passed to it,optionally checking if it is necessary.

    :param job: job to perform heartbeat for
    :param heartbeat_callback: callback to run by the heartbeat
    :param only_if_necessary: only heartbeat if it is necessary (i.e. if there are things to run for
        triggerer for example)
    """
    # The below assert is a temporary one, to make MyPy happy with partial AIP-44 work - we will remove it
    # once final AIP-44 changes are completed.
    assert not isinstance(job, JobPydantic), "Job should be ORM object not Pydantic one here (AIP-44 WIP)"
    seconds_remaining: float = 0.0
    if job.latest_heartbeat and job.heartrate:
        seconds_remaining = job.heartrate - (timezone.utcnow() - job.latest_heartbeat).total_seconds()
    if seconds_remaining > 0 and only_if_necessary:
        return
    with create_session() as session:
        job.heartbeat(heartbeat_callback=heartbeat_callback, session=session)
```

From here I learned that each `Job` instance has a `heartbeat` method, which, depending on the implementation, is called to prove to someone (but who?) that the job itself is still alive. While it does not provide an immediate solution to the task termination problem, this piece of information came handy when reading through other implementations of `Job`, particularly the `SchedulerJob`.

## Setting task instance state
One of the first suspicion I had while thinking through possible causes is the new mini scheduler introduced in Airflow 2. Since I am not running a second scheduler, and the log message is heavily implying a race condition in which competing writes caused a running task's state to be set to `None`, the only other place that could produce a competing write is the mini scheduler, which, according to Airflow' website:

> Should the Task supervisor process perform a “mini scheduler” to attempt to schedule more tasks of the same DAG. Leaving this on will mean tasks in the same DAG execute quicker, but might starve out other DAGs in some circumstances.

Meaning that task instances will try to change the state of some other task instances, causing potential race conditions.

The code for the mini scheduler is fairly easy to find, since the mini scheduler is configured by `AIRFLOW__SCHEDULER__SCHEDULE_AFTER_TASK_EXECUTION`. A quick search for `schedule_after_task_execution` yielded the source code that uses this config:

```python
# https://github.com/apache/airflow/blob/2.6.2/airflow/jobs/local_task_job_runner.py
def handle_task_exit(self, return_code: int) -> None:
    """
    Handle case where self.task_runner exits by itself or is externally killed.

    Don't run any callbacks.
    """
    # Without setting this, heartbeat may get us
    self.terminating = True
    self._log_return_code_metric(return_code)
    is_deferral = return_code == TaskReturnCode.DEFERRED.value
    if is_deferral:
        self.log.info("Task exited with return code %s (task deferral)", return_code)
        _set_task_deferred_context_var()
    else:
        self.log.info("Task exited with return code %s", return_code)

    if not self.task_instance.test_mode and not is_deferral:
        if conf.getboolean("scheduler", "schedule_after_task_execution", fallback=True):
            self.task_instance.schedule_downstream_tasks()
```

Which can be traced back to the following source code:

```python
# https://github.com/apache/airflow/blob/2.6.2/airflow/models/taskinstance.py
@Sentry.enrich_errors
@provide_session
def schedule_downstream_tasks(self, session: Session = NEW_SESSION) -> None:
    #  ... more code ...
        num = dag_run.schedule_tis(schedulable_tis, session=session)
    #  ... more code ...
```

```python
# https://github.com/apache/airflow/blob/2.6.2/airflow/models/dagrun.py
@provide_session
def schedule_tis(self, schedulable_tis: Iterable[TI], session: Session = NEW_SESSION) -> int:
    # ... more code ...
    if schedulable_ti_ids:
        count += (
            session.query(TI)
            .filter(
                TI.dag_id == self.dag_id,
                TI.run_id == self.run_id,
                tuple_in_condition((TI.task_id, TI.map_index), schedulable_ti_ids),
            )
            .update({TI.state: State.SCHEDULED}, synchronize_session=False)
        )
    # ... more code ...
```

The `schedule_tis` method of the `DagRun` class indeed updates the state of a task instance, but it is probably not the root cause since the task instance state is set to `Scheduled` instead of `None`. However, this provides additional clues in the format of the code that I should search for, namely the statement that sets `TI.state = State.None`.

Searching for this statement in Airflow's code base, there are three places where task instance's state is set to `None`:

1. In `backfill_job_runner.py`
2. In `scheduler_job_runner.py`
3. In `dagrun.py`

Option 1 is not likely since I am not backfilling DAG runs. Option 3 is also not likely since the statement is made in a method called `__check_for_removed_or_restored_tasks`, which also does not apply to this situation. For `scheduler_job_runn.py`, the statement is made in a function named `adopt_or_reset_orphaned_tasks`, which I find to be a plausible cause. This is further confirmed when I grep'ed the scheduler log for the keyword "orphan", which produced many lines of:

> Resetting orphaned tasks for active dag runs

So what is orphaned tasks and what happen to them?

## Orphaned tasks
The key insight about orphaned tasks came from how they are identified:

```python
def adopt_or_reset_orphaned_tasks(self, session: Session = NEW_SESSION) -> int:
    # ... more code ...
        num_failed = (
            session.query(Job)
            .filter(
                Job.job_type == "SchedulerJob",
                Job.state == State.RUNNING,
                Job.latest_heartbeat < (timezone.utcnow() - timedelta(seconds=timeout)),
            )
            .update({"state": State.FAILED})
        )

    # ... more code ...
        query = (
            session.query(TI)
            .filter(TI.state.in_(resettable_states))
            # outerjoin is because we didn't use to have queued_by_job
            # set, so we need to pick up anything pre upgrade. This (and the
            # "or queued_by_job_id IS NONE") can go as soon as scheduler HA is
            # released.
            .outerjoin(TI.queued_by_job)
            .filter(or_(TI.queued_by_job_id.is_(None), Job.state != State.RUNNING))
            .join(TI.dag_run)
            .filter(
                DagRun.run_type != DagRunType.BACKFILL_JOB,
                DagRun.state == State.RUNNING,
            )
            .options(load_only(TI.dag_id, TI.task_id, TI.run_id))
        )
    
    # ... more code ...
```

First, dead scheduler jobs are identified by querying scheduler jobs whose last heartbeat is more than `timeout` seconds ago. Then, find task instances scheduled by these dead scheduler jobs, and set their status to `None` (note that there is also a call to "adopt" but adoption is not implemented by the base executor not the one that we use in production). The timeout is set using the configuration `AIRFLOW__SCHEDULER__SCHEDULER_HEALTH_CHECK_THRESHOLD`, which by default is set to 30 seconds.

The `adopt_or_reset_orphaned_tasks` method is called in the `_run_scheduler_loop` method. More specifically, it is invoked by another util class `EventScheduler`, which uses Python's `sched` module to periodically invoke the input function. In our situation, `adopt_or_reset_orphaned_tasks` is called every 300 seconds.

After reading through these, I started having a rough idea of how things went wrong: every 300 seconds, the `adopt_or_reset_orphaned_tasks` checks the state of scheduler jobs, but incorrectly identified some ongoing scheduler jobs' as "dead" and set their child task instances to `None`, which caused the task then to terminate itself. To confirm my hypothesis, I set the scheduler log level to `DEBUG`, which allowed the `_run_scheduler_loop` method to report scheduler loop duration. Here is a snippet of some logs:

```
... skipped logs messages ...
[18:10:20.872] {scheduler_job_runner.py:986} INFO - Ran scheduling loop in 43.56 seconds
[18:10:43.822] {scheduler_job_runner.py:1553} INFO - Resetting orphaned tasks for active dag runs
[18:10:43.863] {scheduler_job_runner.py:986} INFO - Ran scheduling loop in 22.99 seconds
... skipped logs messages ...[18:16:07.298] {scheduler_job_runner.py:1553} INFO - Resetting orphaned tasks for active dag runs
... skipped logs messages ...
[18:21:11.104] {scheduler_job_runner.py:1553} INFO - Resetting orphaned tasks for active dag runs
[18:21:15.195] {scheduler_job_runner.py:1617} INFO - Reset the following 85 orphaned TaskInstances:
... skipped logs messages ...
[18:26:25.419] {scheduler_job_runner.py:1553} INFO - Resetting orphaned tasks for active dag runs
[18:26:29.251] {scheduler_job_runner.py:1617} INFO - Reset the following 64 orphaned TaskInstances:
[18:26:33.933] {scheduler_job_runner.py:986} INFO - Ran scheduling loop in 47.18 seconds
... skipped logs messages ...
```

What I found from the log above is that every time `adopt_or_reset_orphaned_tasks` actually reset task instances, it is followed by a scheduling loop that ran over the health check threshold, which confirmed my suspicion that it is the `adopt_or_reset_orphaned_tasks` function that prematurely identifies scheduler jobs to be dead.

The fix is then pretty straightforward: setting the health check threshold to a larger value to accommodate for longer-running scheduler jobs.

# Some additional notes

- Why is it happening now? We never ran into this issue wiht Airflow 1.10
    - It's mostly because of the introduction of highly available scheduler
- Is this a legitimate issue?
    - Some [issue](https://github.com/apache/airflow/issues/31957) has already been raised to request increased Airflow telemetry such as the scheduler loop duration