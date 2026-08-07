
sre@ubuntu:~$ sudo apt-get install -y gdebi-core
[sudo] password for sre: 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  gdebi-core
0 upgraded, 1 newly installed, 0 to remove and 169 not upgraded.
Need to get 132 kB of archives.
After this operation, 861 kB of additional disk space will be used.
Get:1 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 gdebi-core all 0.9.5.7+nmu7 [132 kB]
Fetched 132 kB in 1s (215 kB/s)
Selecting previously unselected package gdebi-core.
(Reading database ... 85935 files and directories currently installed.)
Preparing to unpack .../gdebi-core_0.9.5.7+nmu7_all.deb ...
Unpacking gdebi-core (0.9.5.7+nmu7) ...
Setting up gdebi-core (0.9.5.7+nmu7) ...
/usr/share/gdebi/GDebi/GDebiCli.py:159: SyntaxWarning: invalid escape sequence '\S'
  c = findall("[[(](\S+)/\S+[])]", msg)[0].lower()
Processing triggers for man-db (2.12.0-4build2) ...
Scanning processes...                                                                                                                    
Scanning linux images...                                                                                                                 

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.

NOTE: download from browser: https://www.openlogic.com/openjdk-downloads

tim@Tims-MBP Downloads % scp openlogic-openjdk-21.0.6_7-linux-x64-deb.deb sre@ubuntu:/home/sre
sre@ubuntu's password: 
openlogic-openjdk-21.0.6_7-linux-x64-deb.deb  100%  242MB  11.4MB/s   00:21    

sre@ubuntu:~$ sudo gdebi ./openlogic-openjdk-21.0.6_7-linux-x64-deb.deb 
/usr/bin/gdebi:113: SyntaxWarning: invalid escape sequence '\S'
  c = findall("[[(](\S+)/\S+[])]", msg)[0].lower()
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Reading state information... Done
Requires the installation of the following packages: fonts-dejavu fonts-dejavu-extra libxi6 libxrender1 libxtst6 x11-common 

OpenJDK Development Kit 21 (JDK) with Hotspot by OpenLogic
Do you want to install the software package? [y/N]:y
/usr/bin/gdebi:113: FutureWarning: Possible nested set at position 1
  c = findall("[[(](\S+)/\S+[])]", msg)[0].lower()
Get:1 http://us.archive.ubuntu.com/ubuntu noble/main amd64 fonts-dejavu-extra all 2.37-8 [1947 kB]                                      
Get:2 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 fonts-dejavu all 2.37-8 [3020 B]                                         
Get:3 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libxi6 amd64 2:1.8.1-1build1 [32.4 kB]                                       
Get:4 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libxrender1 amd64 1:0.9.10-1.1build1 [19.0 kB]                               
Get:5 http://us.archive.ubuntu.com/ubuntu noble/main amd64 x11-common all 1:7.7+23ubuntu3 [21.7 kB]                                     
Get:6 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libxtst6 amd64 2:1.2.3-1.1build1 [12.6 kB]                                   
Fetched 2036 kB in 0s (0 B/s)                                                                                                           
Selecting previously unselected package fonts-dejavu-extra.
(Reading database ... 86007 files and directories currently installed.)
Preparing to unpack .../0-fonts-dejavu-extra_2.37-8_all.deb ...
Unpacking fonts-dejavu-extra (2.37-8) ...
Selecting previously unselected package fonts-dejavu.
Preparing to unpack .../1-fonts-dejavu_2.37-8_all.deb ...
Unpacking fonts-dejavu (2.37-8) ...
Selecting previously unselected package libxi6:amd64.
Preparing to unpack .../2-libxi6_2%3a1.8.1-1build1_amd64.deb ...
Unpacking libxi6:amd64 (2:1.8.1-1build1) ...
Selecting previously unselected package libxrender1:amd64.
Preparing to unpack .../3-libxrender1_1%3a0.9.10-1.1build1_amd64.deb ...
Unpacking libxrender1:amd64 (1:0.9.10-1.1build1) ...
Selecting previously unselected package x11-common.
Preparing to unpack .../4-x11-common_1%3a7.7+23ubuntu3_all.deb ...
Unpacking x11-common (1:7.7+23ubuntu3) ...
Selecting previously unselected package libxtst6:amd64.
Preparing to unpack .../5-libxtst6_2%3a1.2.3-1.1build1_amd64.deb ...
Unpacking libxtst6:amd64 (2:1.2.3-1.1build1) ...
Setting up libxi6:amd64 (2:1.8.1-1build1) ...
Setting up libxrender1:amd64 (1:0.9.10-1.1build1) ...
Setting up x11-common (1:7.7+23ubuntu3) ...
Setting up fonts-dejavu-extra (2.37-8) ...
Setting up fonts-dejavu (2.37-8) ...
Setting up libxtst6:amd64 (2:1.2.3-1.1build1) ...
Processing triggers for man-db (2.12.0-4build2) ...
Processing triggers for libc-bin (2.39-0ubuntu8.4) ...
Scanning processes...                                                                                                                    
Scanning linux images...                                                                                                                 

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
Selecting previously unselected package openlogic-openjdk-21-hotspot.
(Reading database ... 86071 files and directories currently installed.)
Preparing to unpack .../openlogic-openjdk-21.0.6_7-linux-x64-deb.deb ...
Unpacking openlogic-openjdk-21-hotspot (21.0.6+7~openlogic-5) ...
Setting up openlogic-openjdk-21-hotspot (21.0.6+7~openlogic-5) ...
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jar to provide /usr/bin/jar (jar) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jarsigner to provide /usr/bin/jarsigner (jarsigner) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/javac to provide /usr/bin/javac (javac) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/javadoc to provide /usr/bin/javadoc (javadoc) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/javap to provide /usr/bin/javap (javap) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jcmd to provide /usr/bin/jcmd (jcmd) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jconsole to provide /usr/bin/jconsole (jconsole) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jdb to provide /usr/bin/jdb (jdb) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jdeprscan to provide /usr/bin/jdeprscan (jdeprscan) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jdeps to provide /usr/bin/jdeps (jdeps) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jfr to provide /usr/bin/jfr (jfr) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jhsdb to provide /usr/bin/jhsdb (jhsdb) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jimage to provide /usr/bin/jimage (jimage) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jinfo to provide /usr/bin/jinfo (jinfo) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jlink to provide /usr/bin/jlink (jlink) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jmap to provide /usr/bin/jmap (jmap) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jmod to provide /usr/bin/jmod (jmod) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jps to provide /usr/bin/jps (jps) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jrunscript to provide /usr/bin/jrunscript (jrunscript) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jshell to provide /usr/bin/jshell (jshell) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jstack to provide /usr/bin/jstack (jstack) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jstat to provide /usr/bin/jstat (jstat) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/jstatd to provide /usr/bin/jstatd (jstatd) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/bin/serialver to provide /usr/bin/serialver (serialver) in auto mode
update-alternatives: using /usr/lib/jvm/openlogic-openjdk-21-hotspot-amd64/lib/jspawnhelper to provide /usr/bin/jspawnhelper (jspawnhelper) in auto mode

sre@ubuntu:~$ which java
/usr/bin/java
sre@ubuntu:~$ java -version
openjdk version "21.0.6" 2025-01-21
OpenJDK Runtime Environment (build 21.0.6+7-Ubuntu-124.04.1)
OpenJDK 64-Bit Server VM (build 21.0.6+7-Ubuntu-124.04.1, mixed mode, sharing)
sre@ubuntu:~$ which javac
/usr/bin/javac
sre@ubuntu:~$ javac -version
javac 21.0.6

