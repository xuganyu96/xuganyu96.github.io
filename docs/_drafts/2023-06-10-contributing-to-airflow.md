---
layout: post
title:  "Contributing to Airflow"
date:   2023-06-10 00:00:00
categories: python
---

# Setup

# Development
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