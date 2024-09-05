---
layout: post
title:  "Contributing to Airflow"
date:   2023-06-16 00:00:00
categories: python
---

When deploying Apache Airflow to remote environments, the application container first needs to check whether Airflow's backend database can be reached before launching whichever component (webserver, scheduler, worker, etc.) it needs to launch. The first draft of this database (written by the data engineer before me) check logic uses the `psql` CLI app to attempt connection with retries, which works well *enough*, but has two major drawbacks:

- Using `psql` means this database check is vendor-specific. If we one day switch to using MySQL or else, we will need to write another function that uses a different CLI command
- While the retry logic is not complex, handwriting it in shell script is still unpleasant, and the resulting code is ugly

When my team upgraded our Airflow setup to version 2.5, we started using the Airflow CLI command `airflow db check` for performing database check. Using Airflow's CLI addresses the lack of portability to other database backends (thanks to Python DB API 2.0 and SQL Alchemy), but we still need handwrite the retry logic by hand using shell script:

```bash
# Repeatedly run "airflow db check" until either the command succeeds or
# the retries are exhausted
#
# Usage: airflow_db_check 10 1
airflow_db_check() {
    local retries=$1 delay=$2
    airflow db check
    if [[ $? == "0" ]]; then
        return 0
    fi

    while [[ $retries -gt "0" ]]; do
        sleep $delay
        
        airflow db check
        if [[ $? == "0" ]]; then
            return 0
        retries=$(($retries - 1))
        echo "$retries retries remaining; will retry in $delay sec"
    done

    echo "Could not connect to Airflow's backend"
    return 1
```

Knowing that shell script is probably not average web developer's favorite turing complete programming language and motivated by getting some covetted "open source contribution" street creds, I decided to submit a feature request on the `apache/airflow` repository.

To my surprise, the next day a committer responded by acknowledging the usefulness of incorporating retry logic into the Airflow CLI command itself, and encouraged me to submit a pull request. Hence begin my quest to become a contributor to the Airflow project.

# Setup
Apache Airflow is a genuinely massive project in no small part because it is both a library for writing workflow into DAGs and a full-stack application. Consequently, even setting up the development environment including the test suite is a non-trivial task.

This is not the first time I tried trying to set up Airflow's development environment: in my previously attempt a few months ago, I had trouble installing the dependencies, and when the CI/CD utility `breeze` presents me with a shell prompt with `root`, I was spooked and immediately wiped the local copy clean. Knowing that `breeze` uses Docker Compose on the backend to spawn a complete Airflow cluster, and suspecting that the virtual environment setup could have irreversible consequence on my laptop, my first instinct is to take development to the a remote server.

## With Codespace
GitHub conveniently offers a free tier on its Cloud IDE Codespace, and it is listed as one of the officially supported development setup on the contribution guide, making it my first choice.

Something that I did not understand until later was that each Codespace instance is not a virtual machine, but a container that was given virtual hardware limitations (most notably CPU cores, RAM, and disk). This means that just like every other containers, exceeding the memory constraint will get your Codespace instance killed without warning (thanks `containerd`!). This is what happened when I tried to run `breeze shell` and Breeze tried to spawn a gazillion other containers with Docker Compose, and I simply could not resurrect my Codespace instance after it died (trying to restart the instance results will fail with unhelpful message "oops something went wrong")

Another issue I had with developing Airflow on Codespace is that the devcontainer has a setup that is not very transparent nor "standard." After the Codespace instance starts, the terminal always starts shell session with a `root` prompt (which makes `pip` very unhappy about installing Python packages into a root account). Again I only learned later that the dev container is configured to drop me straight into a Breeze shell (hence the `root` prompt), which I find too opinionated and inflexible for a dev container setup.

## With local setup
After struggling with Codespace for a few attempts, I decided to revert back to doing development locally, and luckily because of the limited scope of change needed for my code change as you will see later, the setup process is not too involved.

I manage my Python installation with `pyenv`, and I use `venv` for my virtual environment needs, so the first steps are to setup those up first:

```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
```

Then, we need to install the local copy of Airflow:

```bash
# celery and postgres are needed later
pip install -e ".[devel,celery,postgres]"
```

During the installation process, on some machines I ran into an issue with `pygraphviz`, which has a C library dependencies that need to be installed with `brew install graphviz`, and that might require additional `CFLAG="-I/path/to/graphviz/include"` for `pip` to be able to compile `pygraphviz` using `graphviz`. I could not consistently reproduce the same error on my other laptops, so this issue will not be disussed further.

Finally, we need to install `pipx` and use `pipx` to setup Breeze:

```bash
# The --user flag is not necessary since we are in a virtual environment
pip install pipx
pipx ensurepath  # after this, restart shell, or source ~/.zshrc
pipx install -e ./dev/breeze
```

The steps above will install the `breeze` script into `~/.local/bin`, which can be removed simply by deleting it.

To validate the setup, run `breeze` (which is a short hand for the command `breeze shell`). Breeze will spawn a container that uses sqlite for Airflow's backend and give you a shell to interact with that container. From the shell, we can run `pytest tests/cli` to roughly validate that the setup works, after which we exit the shell and stop the Airflow cluster with `breeze down`.

Static checks are run with using the `pre-commit` program, which should have been installed when we run `pip install` already. We can validate that the static checks can also execute correctly with:

```bash
pre-commit run --all-files
```

The first run will be slow as `pre-commit` needs to set up a lot of things, but subsequent runs should be faster, and with subsequent runs we will only run static checks against staged files (after `git add` but before `git commit`).

# Development
## Scope of change
The `airflow db` subcommands are defined in `airflow/cli/commands/db_command.py`. The original implementation of the `airflow db check` command is as follows:

```python
# airflow.cli.commands.db_command
@cli_utils.action_cli(check_db=False)
def check(_):
    """Runs a check command that checks if db is available."""
    db.check()
```

Within which the `db.check` function is implemented within `airflow/utils/db.py`:

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

Since we need to add two additional arguments for the `airflow db check` command, we will also need to modify `airflow/cli/cli_config.py` to add those two arguments:

```python
# Add the two Arg tuples
ARG_DB_RETRY = Arg(
    ("--retry",),
    default=0,
    type=positive_int(allow_zero=True),
    help="Retry database check upon failure",
)
ARG_DB_RETRY_DELAY = Arg(
    ("--retry-delay",),
    default=1,
    type=positive_int(allow_zero=False),
    help="Wait time between retries in seconds",
)

# Add these two arguments to the `db check` command
DB_COMMANDS = (
    # ... other commands ...
    ActionCommand(
        name="check",
        help="Check if the database can be reached",
        func=lazy_load_command("airflow.cli.commands.db_command.check"),
        args=(ARG_VERBOSE, ARG_DB_RETRY, ARG_DB_RETRY_DELAY),
    ),
    # ... other commands ...
)
```

## Proposed change
My first try at the implementation is to write the retry logic by myself. Since `utils.db.check` indicates failure to connect by letting `session.execute` raise unhandled exception, each check's logic can get rather ugly:

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

With `airflow.utils.db.check`, unit testing is straightforward: the function has three possible outcomes:

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

# Conclusion
This is all the code change that happened, and all there remains to do is to submit the pull request and to wait for the committer to approve your change.