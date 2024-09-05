---
layout: post
title:  "The peril of try-catch"
date:   2023-07-19 00:00:00
categories: python
---

While learning the Rust programming language, one of the key distinction made in the book was that Rust handles errors by treating error has return values: functions that could fail will return a `Result<T, U>` enum where `T` is the return value when the function succeds, and `U` is the error type when the function fails. This was touted as the superior method of handling errors when compared to "raising exception," which is the more popular paradigm as implemented in Python, Java, Ruby, etc. One argument for the superiority of treating errors as return values is the preservation of the program's control flow: with an exception, the control flow becomes unpredictable, while with error-as-values, control flow can be statically analyzed so that errors are guaranteed to be handled. While the argument made sense, I never appreciated how true it was until last weekend, when the unpredictable control flow of throwing an exception caused a production outage.

My team uses Apache Airflow to orchestrate the numerous data pipelines so that data ingestion and processing are executed at the appropriate time, which is usually midnight in this context. The process that schedules and sends tasks to be executed is called the scheduler, and the scheduler crashed on Saturday night because of database maintenance, which temporarily shut down Airflow's backend database and disconnected the scheduler.

This was not supposed to be a big deal. After all, the scheduler process was actually monitored by a parent program called `supervisord`. If the scheduler crashed, the `supervisor` should be able to detect the failure, and repeatedly spawn new scheduler process, which should have addressed the issue in this case because the database shutdown was only temporary. However, `supervisord` did not detect the crash and continued to treat the scheduler as if it is still running correctly. This caused our Airflow cluster to suffer a prolonged outage, and many critical data processing tasks were not scheduled until the next day when someone discovered the outage manually.

After some digging, the root cause was found to be the way the `airflow scheduler` command was implemented. Here is the source code of the scheduler command:

```python
# For some context, we enabled `serve_logs` but disabled `health_checks`

def _run_scheduler_job(job_runner: SchedulerJobRunner, *, skip_serve_logs: bool) -> None:
    InternalApiConfig.force_database_direct_access()
    enable_health_check = conf.getboolean("scheduler", "ENABLE_HEALTH_CHECK")
    with _serve_logs(skip_serve_logs), _serve_health_check(enable_health_check):
        run_job(job=job_runner.job, execute_callable=job_runner._execute)

@contextmanager
def _serve_logs(skip_serve_logs: bool = False):
    """Starts serve_logs sub-process."""
    from airflow.utils.serve_logs import serve_logs

    sub_proc = None
    executor_class, _ = ExecutorLoader.import_default_executor_cls()
    if executor_class.serve_logs:
        if skip_serve_logs is False:
            sub_proc = Process(target=serve_logs)
            sub_proc.start()
    yield
    if sub_proc:
        sub_proc.terminate()


@contextmanager
def _serve_health_check(enable_health_check: bool = False):
    """Starts serve_health_check sub-process."""
    sub_proc = None
    if enable_health_check:
        sub_proc = Process(target=serve_health_check)
        sub_proc.start()
    yield
    if sub_proc:
        sub_proc.terminate()
```

When the `airflow scheduler` command is executed, the `_run_scheduler_job` function is called. Two sub-processes are spawned using the `@contextmanager` functions. When the scheduler exits gracefully, the context managers will call `sub_proc.terminate()` to gracefully terminate the subprocesses.

All hell breaks loose, however, when the `run_job` function raises unhandled exception. In the context of last weekend's outage, when the database shut down, the scheduler loop correctly handled the disconnect, but `airflow.jobs.Job.complete_execution`, which was called to update the (dead) database about the scheduler job failure, did not handle its SQL Alchemy session disconnect, which is then propagated up the call stack to the `run_job` function. When the `run_job` function raises unhandled exception, the exception took over the control flow and since there was no higher level handling, Python started shutting down itself. This is problematic because when the exception took over the control flow, the context managers did not get to execute their "exit" statements, so the sub-processes are never terminated. When Python tries to gracefully shut itself down, it waits for all its child processes by calling `.join()` on them, but since the context managers never terminated these child processes, the `join()` function call will simply hang indefinitely. This causes the `airflow scheduler` process to crash but fails to exit, ultimately becoming a zombie.

Here is a snippet that reproduce the undesirable behavior in which a context manager's exit statements are skipped when an exception takes over the control flow:

```python
from multiprocessing import Process
from contextlib import contextmanager
import time

def busybox():
    time.sleep(24 * 3600)  # the entire day

@contextmanager
def some_resource():
    subproc = Process(target=busybox)
    subproc.start()
    print(f"Sub-process {subproc} started")
    yield
    subproc.terminate()
    subproc.join()
    print(f"Sub-process {subproc} terminated")

def main():
    with some_resource():
        raise Exception("Oops")


if __name__ == "__main__":
    main()
```