---
layout: post
title:  "Parameterize Airflow DAG for better DAG triggering"
date:   2023-05-05 00:00:00
categories: python
---

In my work environment, there are two main use cases for triggering an Airflow DAG with a configuration:

1. Non-periodic workflow that is also too compute-intense to be done on the web server
2. Debugging workflow

As of Airflow 2.5.3, triggering a DAG with a JSON-based configuration is not a satisfactory experience, in no small part because the triggering process does not tell the user anything about what kind of JSON needs to be supplied. If the user has access to the source code, the workflow will be tedious; if the user does not have access to the source code, then the situation becomes completely hopeless.

# Static wrapper for parametrizing DAG runs
One solution to the problem above is to wrap or inject the DAG object with some kind of additional structure that allows developers who specify what information is obtained from `dag_run.conf`. This structure can then be used to generate HTML forms to be integrated into some web view plugins and/or to be used for a REST API.

```python
from airflow import DAG

with DAG(...) as dag:
    # ... build out the dag ...
    # ... build out the parametrization ...
    pass

#  ... in a web plugin ...
def some_view():
    from flask import request
    form = dag.generate_html_form(request.form)
    with request.method == "POST" and form.validate_on_submit():
        conf = form.generate_dagrun_conf()
        dag.create_dagrun(
            # ... other arguments
            conf=conf
        )
```

# What are the features?
* Validating JSON inputs at trigger
* Generate HTML forms that can then be used to generate valid DAG run config

# Limitations
## Parameterization is static
In this context, "static" means that the developer specifies the "triggering" parameters separately from templating some of the operator arguments with `dag_run.conf["foo"]`, which consequently means that if the DAG changes, the parameterization will not "dynamically" adapt. Instead, it is the developer's responsibility to keep the DAG and its parameterization in sync.

## Data type limitation
Even though the parameterization and forms can have rich data types, the native DAG triggering workflow only specifies configurations using JSON, and so we will be limited to using UTF-8 strings, integers, floats, booleans, arrays, and maps.
