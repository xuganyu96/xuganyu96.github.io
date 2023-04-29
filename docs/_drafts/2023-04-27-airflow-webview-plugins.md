---
layout: post
title:  "Airflow plugins with Flask-AppBuilder"
date:   2023-04-27 00:00:00
categories: python
---

# Hello, world
We begin with a simple "Hello, world":

```python
# airflow/plugins/example.py
from airflow.plugins_manager import AirflowPlugin
from flask_appbuilder import expose, BaseView as AppBuilderBaseView

class ExampleView(AppBuilderBaseView):
    default_view = "index"

    @expose("/")
    def index(self):
        return "Hello, world"

example_view = {
    "view": ExampleView()
}

class ExamplePlugin(AirflowPlugin):
    name = "example_plugin"
    appbuilder_views = [example_view]

```

With the code above, when we launch `airflow webserver`, we can navigate to `localhost:8080/exampleview` (even without logging in!) and see the greeting message.

# HTML Templating
We can piggyback off Airflow's existing frontend structure by using Jinja templating. First, use a Flask blueprint to declare some folder contain templated HTMLs:

```python
from flask import Blueprint

bp = Blueprint(
    "example_bp",
    __name__,
    template_folder="templates",
)

class ExamplePlugin(AirflowPlugin):
    # ..
    flask_blueprints = [bp]
```

Then, modify the `index` method of the example view by returning `self.render_template()` instead of plaintext:

```python
@expose("/")
def index(self):
    return self.render_template("index.html")
```

With the two pieces of code above, we have declared `airflow/plugins/templates` to contain templated HTMLs, and we've implemented the index route to render and then return the `index.html` file located under the template folder we just declared:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <h1>Hi, mom</h1>
</body>
</html>
```

We don't want to write the entire HTML document from scratch for every route, and we want to share the top navigation bar, the footer, and the CSS settings all with the rest of the Airflow web views. To do this we will extend some templates:

```html
{% raw %}
{% extends base_template %}

{% block page_title %} Hi, mom {% endblock %}

{% block content %}
<h1>Hi, mom!</h1>
<div class="container">
    <div class="row">
        <div class="col-md-6"><h2>Column 1</h2></div>
        <div class="col-md-6"><h2>Column 2</h2></div>
    </div>
</div>
{% endblock %}
{% endraw %}
```

The `page_title` block corresponds with the `<title>` tag, wile the `content` block will be the between the top menu and the footer. Note that with Airflow 2.5.3, the corresponding version of Flask-Appbuilder ships with Bootstrap 3, so Bootstrap's CSS and JS will work out-of-the-box.

Another thing that works out of the box is `flask.flash`:

```python
from flask import flash

class ExampleView(BaseView):
    def index(self):
        flash("Some message")
```

## Upgrading to Bootstrap 5
While `Flask-Appbuilder` is shipped with Bootstrap 3, the CSS and JS components are neatly packaged in blocks that I can override.

TODO: Need to figure out how

# Form

`Flask-AppBuilder` is shipped with `Flask-WTF`, which can be used to declare HTML forms. We will begin with a simple form with a few common fields:

```python
from flask import request
from flask_wtf import FlaskForm
from wtforms import IntegerField, StringField, SelectField, SubmitField

class ExampleForm(FlaskForm):
    count = IntegerField("Count")
    text = StringField("Free text")
    select = SelectField("Choices", choices=[("foo", "bar")])
    submit = SubmitField("Go")

def index(self):
    form = ExampleForm(request.form)

    return self.render_template(..., form=form)
```

For the template:

```html
{% raw %}
<form method="POST">
    {{ form.csrf_token }}
    <div class="input-group">
        <div>{{ form.count.label }} {{ form.count() }}</div>
        <div>{{ form.text.label }} {{ form.text() }}</div>
        <div>{{ form.select.label }} {{ form.select() }}</div>
        <div>{{ form.submit() }}</div>
    </div>
</form>
{% endraw %}
```

Without specifying the `action` attribute in the form tag, form data is submitted back into the route it came from. To allow data submission, the route needs to allow the `POST` method:

```python
@expose("/", methods=("GET", "POST"))
def index(self):
    # ...
```

There are many ways to parse and validate form data. The paradigm that I prefer is to use `request.method` and `form.validate` so as to not depend on `flask` and `wtforms` instead of `flask-wtf`:

```python
@expose("/", methods=("GET", "POST"))
def index(self):
    form = ExampleForm(request.form)
    
    if request.method == "POST" and form.validate():
        # .. process form data ...
    
    # ... rest of the stuff ...
```

## The select widget



# Query string

# SQLAlchemy session

# Access control