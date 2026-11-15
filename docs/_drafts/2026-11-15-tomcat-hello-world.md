---
layout:     post
title:      Apache Tomcat hello world
date:       2026-11-15 17:28:48 -0500
categories: miscellaneous
---

- [ ] `curl http://localhost:9000/hello` should return 200 and "Hello, world"

My environment:

- MacOS 27.2.1, Homebrew
- javac 25.0.5.0.3
- openjdk 25.0.5.0.3 2026-10-24
- OpenJDK Runtime Environment Homebrew (build 25.0.5.0.3)
- OpenJDK 64-Bit Server VM Homebrew (build 25.0.5.0.3, mixed mode, sharing)

Download the binary distribution and unzip the archive. Instructions for getting
started can be found in `RUNNING.txt`.

```bash
wget -O ~/Downloads/apache-tomcat-11.0.29.tar.gz \
    https://dlcdn.apache.org/tomcat/tomcat-11/v11.0.29/bin/apache-tomcat-11.0.29.tar.gz
cd ~/Downloads
tar xvfz apache-tomcat-11.0.29.tar.gz
cd apache-tomcat-11.0.29
less RUNNING.txt
```

Tomcat startup scripts require environment variable `CATALINA_HOME` (required)
and `CATALINA_BASE` (optional, defaults to the same as `CATALINA_HOME`). Start
with setting them to `apache-tomcat-11.0.29`:

```bash
export CATALINA_HOME="${HOME}/Downloads/apache-tomcat-11.0.29"
export CATALINA_BASE=${CATALINA_HOME}
```

In my environment, `JAVA_HOME` is already set with Homebrew's OpenJDK. No need
to set `JRE_HOME` separately. I will skip setting up `CATALINA_PID` though it
seems helpful. Run the startup script to start the default application. Confirm
with `curl`, then shutdown with the shutdown script.

```bash
$CATALINA_HOME/bin/startup.sh
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
$CATALINA_HOME/bin/shutdown.sh
```

The `catalina.sh` script offers a `run` command that runs the server in the
foreground and that can be shut down using SIGINT. This is probably the preferred
way for development.
