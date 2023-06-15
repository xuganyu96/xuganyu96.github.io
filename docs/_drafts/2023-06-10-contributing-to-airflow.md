---
layout: post
title:  "Contributing to Airflow"
date:   2023-06-10 00:00:00
categories: python
---

# Setup

# Development
## Updated proposal
Thanks to the [feedback](https://github.com/apache/airflow/pull/31836#discussion_r1227648936) from other contributor(s), I've learned that the Apache Airflow project actually uses retry logic from another more mature project called [tenacity](https://github.com/jd/tenacity).

The core data structure of `tenacity` is the `Retrying` object, which can be instantiated alone or be created through the `retry` decorator. `tenacity` uses unhandled exceptions as indication for whether a function call succeeds or not, so I reverted my code change on `airflow.utils.db.check` back to its original implementation. This has the nice effect of reducing the amount of unit tests that I have to write.

In the end, my updated code change only affects `airflow.cli.commands.db_command.check`:

```python
@cli_utils.action_cli(check_db=False)
def check(args):
    """Runs a check command that checks if db is available."""
    retries: int = args.retry
    retry_delay: int = args.retry_delay

    def _warn_remaining_retries(retrystate: RetryCallState):
        remain = retries - retrystate.attempt_number
        log.warning(f"{remain} retries remain, will retry after {retry_delay} seconds")

    for attempt in Retrying(
        stop=stop_after_attempt(1 + retries),
        wait=wait_fixed(retry_delay),
        reraise=True,
        before_sleep=_warn_remaining_retries,
    ):
        with attempt:
            db.check()
```

And my unit tests still mock `sleep` and `airflow.utils.db.check` to count the number of times they are called and the arguments they are called with:

```python
def test_check(self):
    retry, retry_delay = 6, 9  # arbitrary but distinct number
    args = self.parser.parse_args(
        ["db", "check", "--retry", str(retry), "--retry-delay", str(retry_delay)])
    sleep = MagicMock()
    always_pass = Mock()
    always_fail = Mock(side_effect=OperationalError("", None, None))

    with patch("time.sleep", new=sleep), patch("airflow.utils.db.check", new=always_pass):
        db_command.check(args)
        always_pass.assert_called_once()
        sleep.assert_not_called()

    with patch("time.sleep", new=sleep), patch("airflow.utils.db.check", new=always_fail):
        with pytest.raises(OperationalError):
            db_command.check(args)
        # With N retries there are N+1 total checks, hence N sleeps
        always_fail.assert_has_calls([call()] * (retry + 1))
        sleep.assert_has_calls([call(retry_delay)] * retry)
```

## Original proposal
Here are the two functions, before I made the code change:

```python
# airflow.utils.db
@provide_session
def check(session: Session = NEW_SESSION):
    """
    Checks if the database works.

    :param session: session of the sqlalchemy
    """
    session.execute(text("select 1 as is_alive;"))
    log.info("Connection successful.")
```

```python
# airflow.cli.commands.db_command
@cli_utils.action_cli(check_db=False)
def check(_):
    """Runs a check command that checks if db is available."""
    db.check()
```

## Proposed change
The key change is adding the retry logic, which largely looks like this:

```
def check():
    initial_check()

    while has_retries:
        sleep(retry_delay)
        check_again() and exit if successful
        decrement the retries remaining
```

Since `utils.db.check` indicates failure to connect by letting `session.execute` raise unhandled exception, each check's logic can get rather ugly:

```python
def check():
    try:
        db.check()
    except:
        pass
    
    while has_retries:
        sleep(...)
        try:
            db.check()
        except:
            pass
        retries -= 1
    
    # Now what? Re-raise the last exception? SystemExit?
```

Hence, I've decided to also refactor the `utils.db.check` function so that it catches the `OperationalError` that `session.execute` could throw, and returns a boolean to indicate the status of the database check:

```python
# airflow.utils.db
@provide_session
def check(session: Session = NEW_SESSION) -> bool:
    try:
        session.execute(text("select 1 as is_alive;"))
        log.info("Connection successful.")
        return True
    except OperationalError as e:
        log.debug(e)
    return False
```

With that, the CLI command implementation also becomes a lot cleaner:

```python
@cli_utils.action_cli(check_db=False)
def check(args):
    """Runs a check command that checks if db is available."""
    retries: int = args.retry
    retry_delay: int = args.retry_delay

    if db.check():
        raise SystemExit(0)

    while retries > 0:
        time.sleep(retry_delay)
        if db.check():
            raise SystemExit(0)
        retries -= 1
        print(f"Warning: will retry in {retry_delay} seconds. {retries} retries left")
    raise SystemExit(1)
```

Note that we used `raise SystemExit` because this is how other CLI commands force the program to exit, as well. Also, it makes testing a bit easier since we can used `pytest.raises` to catch `SystemExit` while still retaining the early exit of the function.

## Unit tests
With this development I made change to `airflow.utils.db.check` and `airflow.cli.commands.db_commands.check`, so customarily I am responsible for writing the unit tests for the logic that I implemented.

With `airflow.utils.db.check`, the tests are relatively straightforward: the function has three possible outcomes:

1. Return `True` when the session successfully executes the trivial query
2. Return `False` when the session raises `sqlalchemy.exc.OperationalError` at query execution
3. Raise any other exceptions that `session` raises

This means to mock a session whose `execute` method either runs without issues, raises `OperationalError`, or raise some other error:

```python
def test_check(...):
    session_mock = MagicMock()
    assert check(session_mock)
    session_mock.execute = mock.Mock(side_effect=OperationalError("FOO", None, None))
    assert not check(session_mock)
    session_mock.execute = mock.Mock(side_effect=DatabaseError("BAR", None, None))
    with pytest.raises(DatabaseError, match="BAR"):
        check(session_mock)
```

The test case for `db_commands.check` is more involved, in no small part because this function makes call to `time.sleep`, and `exit`, both which I will need to mock, patch, then check whether they are called with the correct argument for the correct number of times, without invoking the actual functions, the first of which will make the test very slow, and the latter of which will simply cause the test session to exit.

Patching functions is achieved using the `patch` function within the `unittest.mock` module, with the target being a valid import path:

```python
def check():
    ...
    time.sleep(x)
    ...

def test_check():
    with patch("time.sleep"):
        # The "time.sleep" call is patched with a call to a mock
        check()
```

A `new` argument can be supplied with a named mock variable, which can then be used for call assertion:

```python
def test_check():
    mock_sleep = MagicMock()
    with patch("time.sleep", new=mock_sleep):
        check()
    mock_sleep.assert_called()
```

A particularly neat method in the `mock` module is `assert_calls`, which can be used to assert successive calls:

```python
from unitttest.mock import patch, call, MagicMock

def check():
    time.sleep(1)
    time.sleep(2)
    time.sleep(3)
    time.sleep(4)

def test_check():
    mock_sleep = MagicMock()
    with patch("time.sleep", new=mock_sleep):
        check()
    mock_sleep.assert_calls([
        call(1), call(2), call(3), call(4)
    ])
```