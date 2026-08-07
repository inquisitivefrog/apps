
See https://linuxiac.com/how-to-install-docker-on-ubuntu-24-04-lts/

sre@ubuntu:~/simple_app/myapp$ dpkg -l | grep docker
sre@ubuntu:~/simple_app/myapp$ sudo apt update
Hit:1 http://repo.percona.com/prel/apt noble InRelease
Hit:2 http://repo.percona.com/ps-80/apt noble InRelease                                                       
Hit:3 http://repo.percona.com/telemetry/apt noble InRelease                                                                                     
Hit:4 http://repo.percona.com/tools/apt noble InRelease                                                                                         
Hit:5 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                                                       
Hit:6 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease                 
Get:7 http://security.ubuntu.com/ubuntu noble-security InRelease [126 kB]
Hit:8 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Get:9 http://security.ubuntu.com/ubuntu noble-security/main amd64 Components [8,956 B]
Get:10 http://security.ubuntu.com/ubuntu noble-security/restricted amd64 Components [212 B]
Get:11 http://security.ubuntu.com/ubuntu noble-security/universe amd64 Components [52.0 kB]
Get:12 http://security.ubuntu.com/ubuntu noble-security/multiverse amd64 Components [212 B]
Fetched 187 kB in 2s (110 kB/s)     
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
166 packages can be upgraded. Run 'apt list --upgradable' to see them.
sre@ubuntu:~/simple_app/myapp$ sudo apt install apt-transport-https curl
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
curl is already the newest version (8.5.0-2ubuntu10.6).
The following NEW packages will be installed:
  apt-transport-https
0 upgraded, 1 newly installed, 0 to remove and 166 not upgraded.
Need to get 3,974 B of archives.
After this operation, 35.8 kB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 apt-transport-https all 2.7.14build2 [3,974 B]
Fetched 3,974 B in 0s (25.5 kB/s)        
Selecting previously unselected package apt-transport-https.
(Reading database ... 89172 files and directories currently installed.)
Preparing to unpack .../apt-transport-https_2.7.14build2_all.deb ...
Unpacking apt-transport-https (2.7.14build2) ...
Setting up apt-transport-https (2.7.14build2) ...
Scanning processes...                                                                                                                            
Scanning candidates...                                                                                                                           
Scanning linux images...                                                                                                                         

Running kernel seems to be up-to-date.

Restarting services...

Service restarts being deferred:
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
sre@ubuntu:~/simple_app/myapp$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sre@ubuntu:~/simple_app/myapp$ curl - fsSL https: //download.docker.com/linux/ubuntu/gpg | sudo gpg - -dearmor -o /etc/apt/keyrings/docker.gpg
curl: option -: is unknown
curl: try 'curl --help' or 'curl --manual' for more information
gpg: directory '/root/.gnupg' created
gpg: keybox '/root/.gnupg/pubring.kbx' created
gpg: WARNING: no command supplied.  Trying to guess what you mean ...
usage: gpg [options] [filename]
sre@ubuntu:~/simple_app/myapp$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sre@ubuntu:~/simple_app/myapp$ 


sre@ubuntu:~/simple_app/myapp$ sudo apt update
Hit:1 http://repo.percona.com/prel/apt noble InRelease
Get:2 https://download.docker.com/linux/ubuntu noble InRelease [48.8 kB]                                                              
Hit:3 http://repo.percona.com/ps-80/apt noble InRelease                                                                               
Hit:4 http://repo.percona.com/telemetry/apt noble InRelease                                                                           
Hit:5 http://repo.percona.com/tools/apt noble InRelease                                                                                         
Hit:6 http://security.ubuntu.com/ubuntu noble-security InRelease                                                                                
Get:7 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages [18.9 kB]
Hit:8 http://us.archive.ubuntu.com/ubuntu noble InRelease
Get:9 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease [126 kB]
Get:10 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease [126 kB]
Get:11 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 Components [151 kB]
Get:12 http://us.archive.ubuntu.com/ubuntu noble-updates/restricted amd64 Components [212 B]
Get:13 http://us.archive.ubuntu.com/ubuntu noble-updates/universe amd64 Components [363 kB]
Get:14 http://us.archive.ubuntu.com/ubuntu noble-updates/multiverse amd64 Components [940 B]
Get:15 http://us.archive.ubuntu.com/ubuntu noble-backports/main amd64 Components [208 B]
Get:16 http://us.archive.ubuntu.com/ubuntu noble-backports/restricted amd64 Components [216 B]
Get:17 http://us.archive.ubuntu.com/ubuntu noble-backports/universe amd64 Components [17.6 kB]
Get:18 http://us.archive.ubuntu.com/ubuntu noble-backports/multiverse amd64 Components [216 B]
Fetched 853 kB in 3s (341 kB/s)                                               
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
166 packages can be upgraded. Run 'apt list --upgradable' to see them.

sre@ubuntu:~/simple_app/myapp$ sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  docker-ce-rootless-extras libltdl7 libslirp0 pigz slirp4netns
Suggested packages:
  aufs-tools cgroupfs-mount | cgroup-lite
The following NEW packages will be installed:
  containerd.io docker-buildx-plugin docker-ce docker-ce-cli docker-ce-rootless-extras docker-compose-plugin libltdl7 libslirp0 pigz
  slirp4netns
0 upgraded, 10 newly installed, 0 to remove and 166 not upgraded.
Need to get 127 MB of archives.
After this operation, 458 MB of additional disk space will be used.
Get:1 https://download.docker.com/linux/ubuntu noble/stable amd64 containerd.io amd64 1.7.25-1 [29.6 MB]
Get:2 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 pigz amd64 2.8-1 [65.6 kB]
Get:3 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libltdl7 amd64 2.4.7-7build1 [40.3 kB]
Get:4 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libslirp0 amd64 4.7.0-1ubuntu3 [63.8 kB]
Get:5 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 slirp4netns amd64 1.2.1-1build2 [34.9 kB]
Get:6 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-buildx-plugin amd64 0.20.0-1~ubuntu.24.04~noble [33.2 MB]
Get:7 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-ce-cli amd64 5:27.5.1-1~ubuntu.24.04~noble [15.2 MB]                   
Get:8 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-ce amd64 5:27.5.1-1~ubuntu.24.04~noble [26.1 MB]                       
Get:9 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-ce-rootless-extras amd64 5:27.5.1-1~ubuntu.24.04~noble [9,601 kB]      
Get:10 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-compose-plugin amd64 2.32.4-1~ubuntu.24.04~noble [12.8 MB]            
Fetched 127 MB in 23s (5,427 kB/s)                                                                                                              
Selecting previously unselected package pigz.
(Reading database ... 89176 files and directories currently installed.)
Preparing to unpack .../0-pigz_2.8-1_amd64.deb ...
Unpacking pigz (2.8-1) ...
Selecting previously unselected package containerd.io.
Preparing to unpack .../1-containerd.io_1.7.25-1_amd64.deb ...
Unpacking containerd.io (1.7.25-1) ...
Selecting previously unselected package docker-buildx-plugin.
Preparing to unpack .../2-docker-buildx-plugin_0.20.0-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-buildx-plugin (0.20.0-1~ubuntu.24.04~noble) ...
Selecting previously unselected package docker-ce-cli.
Preparing to unpack .../3-docker-ce-cli_5%3a27.5.1-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-ce-cli (5:27.5.1-1~ubuntu.24.04~noble) ...
Selecting previously unselected package docker-ce.
Preparing to unpack .../4-docker-ce_5%3a27.5.1-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-ce (5:27.5.1-1~ubuntu.24.04~noble) ...
Selecting previously unselected package docker-ce-rootless-extras.
Preparing to unpack .../5-docker-ce-rootless-extras_5%3a27.5.1-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-ce-rootless-extras (5:27.5.1-1~ubuntu.24.04~noble) ...
Selecting previously unselected package docker-compose-plugin.
Preparing to unpack .../6-docker-compose-plugin_2.32.4-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-compose-plugin (2.32.4-1~ubuntu.24.04~noble) ...
Selecting previously unselected package libltdl7:amd64.
Preparing to unpack .../7-libltdl7_2.4.7-7build1_amd64.deb ...
Unpacking libltdl7:amd64 (2.4.7-7build1) ...
Selecting previously unselected package libslirp0:amd64.
Preparing to unpack .../8-libslirp0_4.7.0-1ubuntu3_amd64.deb ...
Unpacking libslirp0:amd64 (4.7.0-1ubuntu3) ...
Selecting previously unselected package slirp4netns.
Preparing to unpack .../9-slirp4netns_1.2.1-1build2_amd64.deb ...
Unpacking slirp4netns (1.2.1-1build2) ...
Setting up docker-buildx-plugin (0.20.0-1~ubuntu.24.04~noble) ...
Setting up containerd.io (1.7.25-1) ...
Created symlink /etc/systemd/system/multi-user.target.wants/containerd.service → /usr/lib/systemd/system/containerd.service.
Setting up docker-compose-plugin (2.32.4-1~ubuntu.24.04~noble) ...
Setting up libltdl7:amd64 (2.4.7-7build1) ...
Setting up docker-ce-cli (5:27.5.1-1~ubuntu.24.04~noble) ...
Setting up libslirp0:amd64 (4.7.0-1ubuntu3) ...
Setting up pigz (2.8-1) ...
Setting up docker-ce-rootless-extras (5:27.5.1-1~ubuntu.24.04~noble) ...
Setting up slirp4netns (1.2.1-1build2) ...
Setting up docker-ce (5:27.5.1-1~ubuntu.24.04~noble) ...
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
Created symlink /etc/systemd/system/sockets.target.wants/docker.socket → /usr/lib/systemd/system/docker.socket.
Processing triggers for man-db (2.12.0-4build2) ...
Processing triggers for libc-bin (2.39-0ubuntu8.4) ...
Scanning processes...                                                                                                                            
Scanning candidates...                                                                                                                           
Scanning linux images...                                                                                                                         

Running kernel seems to be up-to-date.

Restarting services...

Service restarts being deferred:
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
sre@ubuntu:~/simple_app/myapp$ 

sre@ubuntu:~/simple_app/myapp$ sudo systemctl is-active docker
active

sre@ubuntu:~/simple_app/myapp$ which docker
/usr/bin/docker
sre@ubuntu:~/simple_app/myapp$ docker info
Client:
 Version:    27.2.0
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.16.1
    Path:     /usr/libexec/docker/cli-plugins/docker-buildx
  compose: Docker Compose (Docker Inc.)
    Version:  v2.20.3
    Path:     /usr/libexec/docker/cli-plugins/docker-compose

Server:
ERROR: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.47/info": dial unix /var/run/docker.sock: connect: permission denied
errors pretty printing info

sre@ubuntu:~/simple_app/myapp$ sudo docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
e6590344b1a5: Pull complete 
Digest: sha256:d715f14f9eca81473d9112df50457893aa4d099adeb4729f679006bf5ea12407
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

sre@ubuntu:~/simple_app/myapp$ 

sre@ubuntu:~/simple_app/myapp$ sudo usermod -aG docker ${USER}
sre@ubuntu:~/simple_app/myapp$ docker info
Client:
 Version:    27.2.0
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.16.1
    Path:     /usr/libexec/docker/cli-plugins/docker-buildx
  compose: Docker Compose (Docker Inc.)
    Version:  v2.20.3
    Path:     /usr/libexec/docker/cli-plugins/docker-compose

Server:
ERROR: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.47/info": dial unix /var/run/docker.sock: connect: permission denied
errors pretty printing info
sre@ubuntu:~/simple_app/myapp$ sudo docker info
Client: Docker Engine - Community
 Version:    27.5.1
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.20.0
    Path:     /usr/libexec/docker/cli-plugins/docker-buildx
  compose: Docker Compose (Docker Inc.)
    Version:  v2.32.4
    Path:     /usr/libexec/docker/cli-plugins/docker-compose

Server:
 Containers: 1
  Running: 0
  Paused: 0
  Stopped: 1
 Images: 1
 Server Version: 27.5.1
 Storage Driver: overlay2
  Backing Filesystem: extfs
  Supports d_type: true
  Using metacopy: false
  Native Overlay Diff: true
  userxattr: false
 Logging Driver: json-file
 Cgroup Driver: systemd
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
 Swarm: inactive
 Runtimes: runc io.containerd.runc.v2
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: bcc810d6b9066471b0b6fa75f557a15a1cbf31bb
 runc version: v1.2.4-0-g6c52b3f
 init version: de40ad0
 Security Options:
  apparmor
  seccomp
   Profile: builtin
  cgroupns
 Kernel Version: 6.8.0-52-generic
 Operating System: Ubuntu 24.04 LTS
 OSType: linux
 Architecture: x86_64
 CPUs: 1
 Total Memory: 1.922GiB
 Name: ubuntu
 ID: da438529-c265-4823-8394-96316b504411
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Experimental: false
 Insecure Registries:
  127.0.0.0/8
 Live Restore Enabled: false

sre@ubuntu:~/simple_app/myapp$ 

sre@ubuntu:~/simple_app/myapp$ docker ps
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.47/containers/json": dial unix /var/run/docker.sock: connect: permission denied
sre@ubuntu:~/simple_app/myapp$ sudo docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES


NOTE: docker cmd should work now after logout; login

