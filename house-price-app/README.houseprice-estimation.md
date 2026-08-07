
From xAI Grok GenAI tool

Here's a step-by-step guide to building a simple Java web application with 
Docker-Compose, including services for NGINX as a reverse proxy, your Java 
web app, a MySQL database, and JMeter for load testing:

This setup will:

Serve your Java application via NGINX, 

Connect to a MySQL database,

Allow load testing with JMeter.

If unfamiliar, read additional notes in this order
1. docs/directions/README.tools.txt
2. docs/directions/README.maven.txt
3. docs/directions/README.Docker.txt
4. docs/directions/README.Docker-Compose.txt
5. docs/directions/README.nginx.conf.txt
6. docs/directions/README.JMeter.txt

Pre-Requisites
--------------
1. Install Docker Desktop 
   https://docs.docker.com/desktop/setup/install/mac-install/
2. Start Docker Desktop
% open -a Docker # start Docker Desktop for MacOS
% launchctl list | grep docker # confirm app is running

Build Directions
----------------
% cd myapp
% docker-compose build
% docker-compose up
