# Standalone SQLAlchemy in Flask
Although there are mature packages like `Flask-SQLAlchemy` that handle the messy backend details of managing database resources, there are still use cases in which you would like to use the standalone `SQLAlchemy` package, such as when your project includes other modules that reuse the ORM models but don't run under the Flask application context (e.g. Airflow's scheduler and webserver). Unfortunately, the documentation on how to integrate a standalone `SQLAlchemy` into your project is lacking, so this guide is intended to serve as a compilation of best practices.

When working with SQLAlchemy's ORM, we usually first create an `engine` instance, then pass the `engine` instance to the `sessionmaker` class, which returns a pre-configured session factory in the form of a `Session` class, and then instantiate a `session` instance from the `Session` class. However, Flask application is capable of handling HTTP requests concurrently, which creates the question of what should and should not be shared across different requests. 

## Preliminary knowledge
There are some appetizer to be had before we move on to the meat, but rest assured that these vocabularies will make subsequent material much more easily digested, and you will find this knowledge useful in other context as well.

### SQLAlchemy engine and connection pool 

### ORM Session, Database Transaction

### Handling multiple HTTP requests

## SQLAlchemy best practices
* Create 1 `engine` instance per URI string for the entire application life cycle
* Create 1 session factory per engine for the entire application life cycle
* Use `scoped_session` and `scope_func = _app_ctx_stack.__ident_func` to ensure that each HTTP request gets its own ORM session
