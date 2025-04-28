

sre@ubuntu:~/java_projects/simple_app$ sudo apt -y update
[sudo] password for sre: 
Hit:1 http://repo.percona.com/prel/apt noble InRelease
Hit:2 http://repo.percona.com/ps-80/apt noble InRelease                                                                   
Hit:3 http://repo.percona.com/telemetry/apt noble InRelease                                                               
Hit:4 http://repo.percona.com/tools/apt noble InRelease                                                                   
Hit:5 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                                 
Hit:6 http://security.ubuntu.com/ubuntu noble-security InRelease                  
Hit:7 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:8 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
All packages are up to date.

sre@ubuntu:~/java_projects/simple_app$ sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
ca-certificates is already the newest version (20240203).
ca-certificates set to manually installed.
curl is already the newest version (8.5.0-2ubuntu10.6).
curl set to manually installed.
software-properties-common is already the newest version (0.99.49.1).
software-properties-common set to manually installed.
The following package was automatically installed and is no longer required:
  python3-netifaces
Use 'sudo apt autoremove' to remove it.
The following NEW packages will be installed:
  apt-transport-https gnupg-agent
0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
Need to get 8646 B of archives.
After this operation, 63.5 kB of additional disk space will be used.
Get:1 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 apt-transport-https all 2.7.14build2 [3974 B]
Get:2 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 gnupg-agent all 2.4.4-2ubuntu17 [4672 B]
Fetched 8646 B in 0s (33.6 kB/s)      
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package apt-transport-https.
(Reading database ... 92241 files and directories currently installed.)
Preparing to unpack .../apt-transport-https_2.7.14build2_all.deb ...
Unpacking apt-transport-https (2.7.14build2) ...
Selecting previously unselected package gnupg-agent.
Preparing to unpack .../gnupg-agent_2.4.4-2ubuntu17_all.deb ...
Unpacking gnupg-agent (2.4.4-2ubuntu17) ...
Setting up apt-transport-https (2.7.14build2) ...
Setting up gnupg-agent (2.4.4-2ubuntu17) ...
Scanning processes...                                                                                                      
Scanning candidates...                                                                                                     
Scanning linux images...                                                                                                   

Running kernel seems to be up-to-date.

Restarting services...

Service restarts being deferred:
 /etc/needrestart/restart.d/dbus.service
 systemctl restart getty@tty1.service
 systemctl restart getty@tty6.service
 systemctl restart systemd-logind.service
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

User sessions running outdated binaries:
 sre @ user manager service: systemd[6205]

No VM guests are running outdated hypervisor (qemu) binaries on this host.

sre@ubuntu:~/java_projects/simple_app$ sudo apt remove docker docker-engine docker.io containerd runc
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Package 'docker' is not installed, so not removed
E: Unable to locate package docker-engine
sre@ubuntu:~/java_projects/simple_app$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
sre@ubuntu:~/java_projects/simple_app$ sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
Repository: 'deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable'
Description:
Archive for codename: noble components: stable
More info: https://download.docker.com/linux/ubuntu
Adding repository.
Press [ENTER] to continue or Ctrl-c to cancel.
Adding deb entry to /etc/apt/sources.list.d/archive_uri-https_download_docker_com_linux_ubuntu-noble.list
Adding disabled deb-src entry to /etc/apt/sources.list.d/archive_uri-https_download_docker_com_linux_ubuntu-noble.list
Get:1 https://download.docker.com/linux/ubuntu noble InRelease [48.8 kB]
Hit:2 http://repo.percona.com/prel/apt noble InRelease                                        
Hit:3 http://repo.percona.com/ps-80/apt noble InRelease                                       
Hit:4 http://repo.percona.com/telemetry/apt noble InRelease 
Hit:5 http://repo.percona.com/tools/apt noble InRelease                                                                   
Hit:6 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                                 
Hit:7 http://security.ubuntu.com/ubuntu noble-security InRelease                                                          
Get:8 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages [18.9 kB]
Hit:9 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:10 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Fetched 67.7 kB in 1s (61.6 kB/s)
Reading package lists... Done

sre@ubuntu:~/java_projects/simple_app$ sudo apt update
Hit:1 https://download.docker.com/linux/ubuntu noble InRelease
Hit:2 http://repo.percona.com/prel/apt noble InRelease                                                                    
Hit:3 http://repo.percona.com/ps-80/apt noble InRelease                                                                   
Hit:4 http://repo.percona.com/telemetry/apt noble InRelease                                                               
Hit:5 http://repo.percona.com/tools/apt noble InRelease                                                                   
Hit:6 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                                 
Hit:7 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease                 
Hit:8 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:9 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
All packages are up to date.

sre@ubuntu:~/java_projects/simple_app$ sudo apt install -y docker-ce docker-ce-cli containerd.io
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following package was automatically installed and is no longer required:
  python3-netifaces
Use 'sudo apt autoremove' to remove it.
The following additional packages will be installed:
  docker-buildx-plugin docker-ce-rootless-extras docker-compose-plugin git git-man iptables less liberror-perl libip4tc2
  libip6tc2 libjansson4 libltdl7 libnetfilter-conntrack3 libnfnetlink0 libnftables1 libnftnl11 libslirp0 nftables patch
  pigz slirp4netns
Suggested packages:
  aufs-tools cgroupfs-mount | cgroup-lite git-daemon-run | git-daemon-sysvinit git-doc git-email git-gui gitk gitweb
  git-cvs git-mediawiki git-svn firewalld ed diffutils-doc
The following NEW packages will be installed:
  containerd.io docker-buildx-plugin docker-ce docker-ce-cli docker-ce-rootless-extras docker-compose-plugin git git-man
  iptables less liberror-perl libip4tc2 libip6tc2 libjansson4 libltdl7 libnetfilter-conntrack3 libnfnetlink0 libnftables1
  libnftnl11 libslirp0 nftables patch pigz slirp4netns
0 upgraded, 24 newly installed, 0 to remove and 0 not upgraded.
Need to get 133 MB of archives.
After this operation, 487 MB of additional disk space will be used.
Get:1 https://download.docker.com/linux/ubuntu noble/stable amd64 containerd.io amd64 1.7.25-1 [29.6 MB]
Get:2 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 pigz amd64 2.8-1 [65.6 kB]                      
Get:3 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 less amd64 590-2ubuntu2.1 [142 kB]          
Get:4 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libip4tc2 amd64 1.8.10-3ubuntu2 [23.3 kB]
Get:5 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libip6tc2 amd64 1.8.10-3ubuntu2 [23.7 kB]
Get:6 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libnfnetlink0 amd64 1.0.2-2build1 [14.8 kB]
Get:7 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libnetfilter-conntrack3 amd64 1.0.9-6build1 [45.2 kB]
Get:8 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libnftnl11 amd64 1.2.6-2build1 [66.0 kB]
Get:9 http://us.archive.ubuntu.com/ubuntu noble/main amd64 iptables amd64 1.8.10-3ubuntu2 [381 kB]
Get:10 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libjansson4 amd64 2.14-2build2 [32.8 kB]
Get:11 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libnftables1 amd64 1.0.9-1build1 [358 kB]
Get:12 http://us.archive.ubuntu.com/ubuntu noble/main amd64 nftables amd64 1.0.9-1build1 [69.8 kB]
Get:13 http://us.archive.ubuntu.com/ubuntu noble/main amd64 liberror-perl all 0.17029-2 [25.6 kB]
Get:14 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 git-man all 1:2.43.0-1ubuntu7.2 [1100 kB]
Get:15 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 git amd64 1:2.43.0-1ubuntu7.2 [3679 kB]
Get:16 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libltdl7 amd64 2.4.7-7build1 [40.3 kB]
Get:17 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libslirp0 amd64 4.7.0-1ubuntu3 [63.8 kB]
Get:18 http://us.archive.ubuntu.com/ubuntu noble/main amd64 patch amd64 2.7.6-7build3 [104 kB]
Get:19 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 slirp4netns amd64 1.2.1-1build2 [34.9 kB]
Get:20 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-buildx-plugin amd64 0.20.0-1~ubuntu.24.04~noble [33.2 MB]
Get:21 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-ce-cli amd64 5:27.5.1-1~ubuntu.24.04~noble [15.2 MB]
Get:22 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-ce amd64 5:27.5.1-1~ubuntu.24.04~noble [26.1 MB]
Get:23 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-ce-rootless-extras amd64 5:27.5.1-1~ubuntu.24.04~noble [9601 kB]
Get:24 https://download.docker.com/linux/ubuntu noble/stable amd64 docker-compose-plugin amd64 2.32.4-1~ubuntu.24.04~noble [12.8 MB]
Fetched 133 MB in 27s (5003 kB/s)                                                                                         
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package pigz.
(Reading database ... 92249 files and directories currently installed.)
Preparing to unpack .../00-pigz_2.8-1_amd64.deb ...
Unpacking pigz (2.8-1) ...
Selecting previously unselected package less.
Preparing to unpack .../01-less_590-2ubuntu2.1_amd64.deb ...
Unpacking less (590-2ubuntu2.1) ...
Selecting previously unselected package libip4tc2:amd64.
Preparing to unpack .../02-libip4tc2_1.8.10-3ubuntu2_amd64.deb ...
Unpacking libip4tc2:amd64 (1.8.10-3ubuntu2) ...
Selecting previously unselected package libip6tc2:amd64.
Preparing to unpack .../03-libip6tc2_1.8.10-3ubuntu2_amd64.deb ...
Unpacking libip6tc2:amd64 (1.8.10-3ubuntu2) ...
Selecting previously unselected package libnfnetlink0:amd64.
Preparing to unpack .../04-libnfnetlink0_1.0.2-2build1_amd64.deb ...
Unpacking libnfnetlink0:amd64 (1.0.2-2build1) ...
Selecting previously unselected package libnetfilter-conntrack3:amd64.
Preparing to unpack .../05-libnetfilter-conntrack3_1.0.9-6build1_amd64.deb ...
Unpacking libnetfilter-conntrack3:amd64 (1.0.9-6build1) ...
Selecting previously unselected package libnftnl11:amd64.
Preparing to unpack .../06-libnftnl11_1.2.6-2build1_amd64.deb ...
Unpacking libnftnl11:amd64 (1.2.6-2build1) ...
Selecting previously unselected package iptables.
Preparing to unpack .../07-iptables_1.8.10-3ubuntu2_amd64.deb ...
Unpacking iptables (1.8.10-3ubuntu2) ...
Selecting previously unselected package libjansson4:amd64.
Preparing to unpack .../08-libjansson4_2.14-2build2_amd64.deb ...
Unpacking libjansson4:amd64 (2.14-2build2) ...
Selecting previously unselected package libnftables1:amd64.
Preparing to unpack .../09-libnftables1_1.0.9-1build1_amd64.deb ...
Unpacking libnftables1:amd64 (1.0.9-1build1) ...
Selecting previously unselected package nftables.
Preparing to unpack .../10-nftables_1.0.9-1build1_amd64.deb ...
Unpacking nftables (1.0.9-1build1) ...
Selecting previously unselected package containerd.io.
Preparing to unpack .../11-containerd.io_1.7.25-1_amd64.deb ...
Unpacking containerd.io (1.7.25-1) ...
Selecting previously unselected package docker-buildx-plugin.
Preparing to unpack .../12-docker-buildx-plugin_0.20.0-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-buildx-plugin (0.20.0-1~ubuntu.24.04~noble) ...
Selecting previously unselected package docker-ce-cli.
Preparing to unpack .../13-docker-ce-cli_5%3a27.5.1-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-ce-cli (5:27.5.1-1~ubuntu.24.04~noble) ...
Selecting previously unselected package docker-ce.
Preparing to unpack .../14-docker-ce_5%3a27.5.1-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-ce (5:27.5.1-1~ubuntu.24.04~noble) ...
Selecting previously unselected package docker-ce-rootless-extras.
Preparing to unpack .../15-docker-ce-rootless-extras_5%3a27.5.1-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-ce-rootless-extras (5:27.5.1-1~ubuntu.24.04~noble) ...
Selecting previously unselected package docker-compose-plugin.
Preparing to unpack .../16-docker-compose-plugin_2.32.4-1~ubuntu.24.04~noble_amd64.deb ...
Unpacking docker-compose-plugin (2.32.4-1~ubuntu.24.04~noble) ...
Selecting previously unselected package liberror-perl.
Preparing to unpack .../17-liberror-perl_0.17029-2_all.deb ...
Unpacking liberror-perl (0.17029-2) ...
Selecting previously unselected package git-man.
Preparing to unpack .../18-git-man_1%3a2.43.0-1ubuntu7.2_all.deb ...
Unpacking git-man (1:2.43.0-1ubuntu7.2) ...
Selecting previously unselected package git.
Preparing to unpack .../19-git_1%3a2.43.0-1ubuntu7.2_amd64.deb ...
Unpacking git (1:2.43.0-1ubuntu7.2) ...
Selecting previously unselected package libltdl7:amd64.
Preparing to unpack .../20-libltdl7_2.4.7-7build1_amd64.deb ...
Unpacking libltdl7:amd64 (2.4.7-7build1) ...
Selecting previously unselected package libslirp0:amd64.
Preparing to unpack .../21-libslirp0_4.7.0-1ubuntu3_amd64.deb ...
Unpacking libslirp0:amd64 (4.7.0-1ubuntu3) ...
Selecting previously unselected package patch.
Preparing to unpack .../22-patch_2.7.6-7build3_amd64.deb ...
Unpacking patch (2.7.6-7build3) ...
Selecting previously unselected package slirp4netns.
Preparing to unpack .../23-slirp4netns_1.2.1-1build2_amd64.deb ...
Unpacking slirp4netns (1.2.1-1build2) ...
Setting up libip4tc2:amd64 (1.8.10-3ubuntu2) ...
Setting up libip6tc2:amd64 (1.8.10-3ubuntu2) ...
Setting up less (590-2ubuntu2.1) ...
Setting up libnftnl11:amd64 (1.2.6-2build1) ...
Setting up libjansson4:amd64 (2.14-2build2) ...
Setting up liberror-perl (0.17029-2) ...
Setting up docker-buildx-plugin (0.20.0-1~ubuntu.24.04~noble) ...
Setting up containerd.io (1.7.25-1) ...
Created symlink /etc/systemd/system/multi-user.target.wants/containerd.service → /usr/lib/systemd/system/containerd.service.
Setting up patch (2.7.6-7build3) ...
Setting up docker-compose-plugin (2.32.4-1~ubuntu.24.04~noble) ...
Setting up libltdl7:amd64 (2.4.7-7build1) ...
Setting up docker-ce-cli (5:27.5.1-1~ubuntu.24.04~noble) ...
Setting up libslirp0:amd64 (4.7.0-1ubuntu3) ...
Setting up pigz (2.8-1) ...
Setting up libnfnetlink0:amd64 (1.0.2-2build1) ...
Setting up git-man (1:2.43.0-1ubuntu7.2) ...
Setting up docker-ce-rootless-extras (5:27.5.1-1~ubuntu.24.04~noble) ...
Setting up libnftables1:amd64 (1.0.9-1build1) ...
Setting up nftables (1.0.9-1build1) ...
Setting up slirp4netns (1.2.1-1build2) ...
Setting up git (1:2.43.0-1ubuntu7.2) ...
Setting up libnetfilter-conntrack3:amd64 (1.0.9-6build1) ...
Setting up iptables (1.8.10-3ubuntu2) ...
update-alternatives: using /usr/sbin/iptables-legacy to provide /usr/sbin/iptables (iptables) in auto mode
update-alternatives: using /usr/sbin/ip6tables-legacy to provide /usr/sbin/ip6tables (ip6tables) in auto mode
update-alternatives: using /usr/sbin/iptables-nft to provide /usr/sbin/iptables (iptables) in auto mode
update-alternatives: using /usr/sbin/ip6tables-nft to provide /usr/sbin/ip6tables (ip6tables) in auto mode
update-alternatives: using /usr/sbin/arptables-nft to provide /usr/sbin/arptables (arptables) in auto mode
update-alternatives: using /usr/sbin/ebtables-nft to provide /usr/sbin/ebtables (ebtables) in auto mode
Setting up docker-ce (5:27.5.1-1~ubuntu.24.04~noble) ...
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
Created symlink /etc/systemd/system/sockets.target.wants/docker.socket → /usr/lib/systemd/system/docker.socket.
Processing triggers for libc-bin (2.39-0ubuntu8.4) ...
Scanning processes...                                                                                                      
Scanning candidates...                                                                                                     
Scanning linux images...                                                                                                   

Running kernel seems to be up-to-date.

Restarting services...

Service restarts being deferred:
 /etc/needrestart/restart.d/dbus.service
 systemctl restart getty@tty1.service
 systemctl restart getty@tty6.service
 systemctl restart systemd-logind.service
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

User sessions running outdated binaries:
 sre @ user manager service: systemd[6205]

No VM guests are running outdated hypervisor (qemu) binaries on this host.
sre@ubuntu:~/java_projects/simple_app$ 

sre@ubuntu:~/java_projects/simple_app$ sudo systemctl enable docker && sudo systemctl start docker
Synchronizing state of docker.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable docker
sre@ubuntu:~/java_projects/simple_app$ sudo usermod -aG docker $USER
sre@ubuntu:~/java_projects/simple_app$ 

sre@ubuntu:~/simple-app/myapp$ dpkg -l | grep docker
ii  docker-buildx-plugin                  0.20.0-1~ubuntu.24.04~noble             amd64        Docker Buildx cli plugin.
ii  docker-ce                             5:27.5.1-1~ubuntu.24.04~noble           amd64        Docker: the open-source application container engine
ii  docker-ce-cli                         5:27.5.1-1~ubuntu.24.04~noble           amd64        Docker CLI: the open-source application container engine
ii  docker-ce-rootless-extras             5:27.5.1-1~ubuntu.24.04~noble           amd64        Rootless support for Docker.
ii  docker-compose-plugin                 2.32.4-1~ubuntu.24.04~noble             amd64        Docker Compose (V2) plugin for the Docker CLI.
sre@ubuntu:~/simple-app/myapp$ which docker
/usr/bin/docker
sre@ubuntu:~/simple-app/myapp$ docker version
Client: Docker Engine - Community
 Version:           27.5.1
 API version:       1.47
 Go version:        go1.22.11
 Git commit:        9f9e405
 Built:             Wed Jan 22 13:41:48 2025
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          27.5.1
  API version:      1.47 (minimum version 1.24)
  Go version:       go1.22.11
  Git commit:       4c9b3b0
  Built:            Wed Jan 22 13:41:48 2025
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.7.25
  GitCommit:        bcc810d6b9066471b0b6fa75f557a15a1cbf31bb
 runc:
  Version:          1.2.4
  GitCommit:        v1.2.4-0-g6c52b3f
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0


