# Deploying a Flask application to RPi with NginX and uWSGI
This guide describes the process by which a dummy Flask application is created, copied to a Raspberry Pi on a local network, run behind a uWSGI server, and an NginX reverse proxy is set up to run as an edge server in front of the uWSGI server that runs the Flask application.

This guide assumes that the reader has a UNIX-like local development environment and understands simple Python and the command line.

## Prepare the Flask application 
Our project will take on the following file structure:
```
project_root_dir/
    myapp/
        __init__.py
        myapp.py
    wsgi.py
    uwsgi.ini
    requirements.txt
```

For now, `__init__.py` and `uwsgi.ini` will be left empty; we will fill up `uwsgi.ini` in later sections

For demonstration purposes, `requirements.txt` only needs the following two packages:
```
flask==1.1.2
uwsgi==2.0.19
```

`myapp.py` will implement a simple route.
```python
from flask import Flask

app = Flask(__name__)

@app.route('/debug/can_connect')
def can_connect():
    return """
    <h1>You are connected to MyApp</h1>
    """

if __name__ == "__main__":
    app.run(host="127.0.0.1")
```

`wsgi.py` will import the `app` callable and run it:
```python
from myapp.myapp import app

if __name__ == "__main__":
    app.run()
```

Confirm that the app works correctly by changing the working directory to be at the project root directory, and running the `wsgi.py` directly:
```bash
python wsgi.py
```
WSGI defaults to port 5000, so use any browser and try to access `http://localhost:5000/debug/can_connect`. If the app works correctly, `You are connected to MyApp` should be displayed on the page.

## Set up Raspberry Pi 
This guide assumes that the Raspberry Pi is correctly set up to run Raspberry Pi OS (formerly Raspbian) and has Python 3.7 accessible through the `python3` command. It is also assumed that the reader can SSH into the Raspberry Pi as a non-root user `pi` with a home directory at `/home/pi`, and that the project files above have been copied to `/home/pi/project`.

First we need to create a virtual environment. Unfortunately there is no official support for conda on Raspberry Pi due to processor architecture compatibility; therefore, we will use Python's built-in `venv` package for virtual environment (`venv` is recommended for Python 3.6 and later; earlier versions of Python might use `virtualenv` or `pyenv`):
```bash
python3 -m venv ~/.venv/myapp
```

The command above will create a directory at `~/.venv/app` and initialize the virtual environment inside. Actiavte the virtual environment using the following command:
```bash
source ~/.venv/myapp/bin/activate

# to deactivate:
# deactivate
# The virtual environment can be deleted by removing the directory `~/.venv/myapp`.
```
Confirm that the environment is active by checking that `python` and `pip` both point to the symlink within the virtual environment's directory
```bash
which python
# /home/pi/.venv/myapp/bin/python

which pip
# /home/pi/.venv/wslite/bin/pip
```

Finally, change directory into the project root directory and install the python libraries:
```bash
pip install -r requirements.txt
# Confirm that uwsgi can be recognized:
# which uwsgi
# /home/pi/.venv/myapp/bin/uwsgi
```

## uWSGI: initial test run
In this use case, `uwsgi` (pronounced "mew-whiskey") works as the origin server (later on we will add NginX as an edge server).

Begin by testing if `uwsgi` works correctly:
```bash
# cd /home/pi/project
uwsgi --socket 0.0.0.0:8000 --module wsgi:app --protocol http
# use --socket 0.0.0.0:8000 to allow traffic from all IP addresses
# use --module to specify the python module and the callable object from that module to run
# use --protocol to enforce the use of HTTP; otherwise uwsgi will default to the WSGI procotol which will be incompatible with the HTTP request sent from a browser
```

Once `uwsgi` is up and running, use a browser to try to access `http://<rpi_ip_address>:8000/debug/can_connect` and confirm that the page displays correctly.

## NginX: installation 
Installing `NginX` on Raspberry Pi OS takes exactly one command
```bash
# sudo apt-get update
sudo apt-get install nginx

# Confirm nginx is running:
sudo systemctl status nginx
```

Confirm NginX works correctly by going to `http://<rpi_ip_address>`; there should be a default page served by NginX.

NginX comes with a default reverse proxy configuration that we will remove:
```bash
sudo rm /etc/nginx/sites-enabled/default
```

Create our own reverse proxy configuration and link it to where NginX can read it
```bash
sudo touch /etc/nginx/sites-available/myapp_proxy
sudo ln -s /etc/nginx/sites-available/myapp_proxy /etc/nginx/sites-enabled
```

Two useful commands to know for validating nginx configurations and for restarting nginx:
```bash
# For validating configurations
sudo nginx -t
# For restarting nginx
sudo systemctl restart nginx
```

From this point on, we will repeat the following cycle:
1. Edit `/etc/nginx/sites-available/myapp_proxy`
2. Edit `/home/pi/project/uwsgi.ini`
3. Validate NginX config and restart NginX
4. Start `uwsgi` server by `uwsgi --ini ~/project/uwsgi.ini`
5. Confirm that `http://<rpi_ip_address>/debug/can_connect` displays correctly

## Three ways of connecting NginX to uwsgi
There are three ways of connecting NgiNX to uwsgi: 
* through generic HTTP over TCP
* through uwsgi over TCP
* through uwsgi over a UNIX socket

### Through HTTP over TCP
note: This is not recommended because HTTP is a bit slower than WSGI protocole

If choosing to route traffic using HTTP over TCP, your nginx config should look like
```
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:8000;
    }
}
```

And your `uwsgi.ini` should look like
```ini
[uwsgi]
chdir = /home/pi/project
module = wsgi:app

master = true

protocol = http
socket = 127.0.0.1:8000

virtualenv = /home/pi/.venv/myapp
```

### Through WSGI over TCP
NginX config:
```
server {
    listen 80;
    server_name localhost;

    location / {
        include uwsgi_params;
        uwsgi_pass 127.0.0.1:8000;
    }
}
```
`uwsgi.ini`
```ini
[uwsgi]
chdir = /home/pi/project
module = wsgi:app

master = true

socket = 127.0.0.1:8000

virtualenv = /home/pi/.venv/wslite
```

### Through WSGI over unix socket
NginX config
```
server {
    listen 80;
    server_name localhost;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/tmp/wslite.sock;
    }
}
```
`uwsgi.ini`
```ini
[uwsgi]
chdir = /home/pi/project
module = wsgi:app

master = true

socket = /tmp/wslite.sock
chmod-socket = 666
uid = www-data
gid = www-data
vacuum = true

die-on-term = true

virtualenv = /home/pi/.venv/wslite
```

* Need to explain `666` and `uid` and `gid`
* Keep `uwsgi` running with `uwsgi --ini uwsgi.ini &>/dev/null &`
