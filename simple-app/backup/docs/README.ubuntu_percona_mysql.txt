
sre@ubuntu:~/simple_app/myapp$ sudo apt update
[sudo] password for sre: 
Hit:1 http://us.archive.ubuntu.com/ubuntu noble InRelease
Get:2 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease [126 kB]
Get:3 http://security.ubuntu.com/ubuntu noble-security InRelease [126 kB]
Hit:4 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease 
Get:5 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 Packages [853 kB]
Get:6 http://us.archive.ubuntu.com/ubuntu noble-updates/universe amd64 Packages [1,012 kB]
Fetched 2,117 kB in 2s (1,036 kB/s)                       
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
169 packages can be upgraded. Run 'apt list --upgradable' to see them.

sre@ubuntu:~/simple_app/myapp$ sudo apt-get install -y cursl gnupg2 softwae-properties-common 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
E: Unable to locate package cursl
E: Unable to locate package softwae-properties-common
sre@ubuntu:~/simple_app/myapp$ sudo apt-get install -y curl gnupg2 softwae-properties-common 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
E: Unable to locate package softwae-properties-common
sre@ubuntu:~/simple_app/myapp$ sudo apt-get install -y curl gnupg2 software-properties-common 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
curl is already the newest version (8.5.0-2ubuntu10.6).
curl set to manually installed.
The following NEW packages will be installed:
  gnupg2
The following packages will be upgraded:
  python3-software-properties software-properties-common
2 upgraded, 1 newly installed, 0 to remove and 167 not upgraded.
Need to get 48.9 kB of archives.
After this operation, 32.8 kB of additional disk space will be used.
Get:1 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 software-properties-common all 0.99.49.1 [14.4 kB]
Get:2 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 python3-software-properties all 0.99.49.1 [29.7 kB]
Get:3 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 gnupg2 all 2.4.4-2ubuntu17 [4,748 B]
Fetched 48.9 kB in 1s (93.5 kB/s)
(Reading database ... 86770 files and directories currently installed.)
Preparing to unpack .../software-properties-common_0.99.49.1_all.deb ...
Unpacking software-properties-common (0.99.49.1) over (0.99.48) ...
Preparing to unpack .../python3-software-properties_0.99.49.1_all.deb ...
Unpacking python3-software-properties (0.99.49.1) over (0.99.48) ...
Selecting previously unselected package gnupg2.
Preparing to unpack .../gnupg2_2.4.4-2ubuntu17_all.deb ...
Unpacking gnupg2 (2.4.4-2ubuntu17) ...
Setting up gnupg2 (2.4.4-2ubuntu17) ...
Setting up python3-software-properties (0.99.49.1) ...
Setting up software-properties-common (0.99.49.1) ...
Processing triggers for man-db (2.12.0-4build2) ...
Processing triggers for dbus (1.14.10-4ubuntu4) ...
Scanning processes...                                                                                                                            
Scanning linux images...                                                                                                                         

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
sre@ubuntu:~/simple_app/myapp$ curl -O https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 16510  100 16510    0     0   123k      0 --:--:-- --:--:-- --:--:--  124k
sre@ubuntu:~/simple_app/myapp$ sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
Selecting previously unselected package percona-release.
(Reading database ... 86776 files and directories currently installed.)
Preparing to unpack percona-release_latest.noble_all.deb ...
Unpacking percona-release (1.0-29.generic) ...
Setting up percona-release (1.0-29.generic) ...
grep: /etc/apt/sources.list.d/percona*: No such file or directory
ERROR: Invalid filename format: percona*
* Enabling the Percona Release repository
Get:1 http://repo.percona.com/prel/apt noble InRelease [12.8 kB]
Get:2 http://repo.percona.com/prel/apt noble/main amd64 Packages [545 B]          
Hit:3 http://us.archive.ubuntu.com/ubuntu noble InRelease                         
Hit:4 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:5 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:6 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Fetched 13.3 kB in 1s (14.9 kB/s)
Reading package lists... Done
* Enabling the Percona Telemetry repository
Hit:1 http://repo.percona.com/prel/apt noble InRelease
Get:2 http://repo.percona.com/telemetry/apt noble InRelease [12.8 kB]                                         
Hit:3 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                     
Hit:4 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease                                             
Hit:5 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease               
Hit:6 http://security.ubuntu.com/ubuntu noble-security InRelease
Get:7 http://repo.percona.com/telemetry/apt noble/main Sources [1,382 B]
Get:8 http://repo.percona.com/telemetry/apt noble/main amd64 Packages [842 B]
Fetched 15.0 kB in 1s (13.0 kB/s)
Reading package lists... Done
* Enabling the PMM2 Client repository
Get:1 http://repo.percona.com/pmm2-client/apt noble InRelease [18.7 kB]
Hit:2 http://repo.percona.com/prel/apt noble InRelease                                                                                          
Hit:3 http://repo.percona.com/telemetry/apt noble InRelease                                                                                     
Get:4 http://repo.percona.com/pmm2-client/apt noble/main amd64 Packages [1,119 B]                                                               
Hit:5 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                                                       
Hit:6 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease            
Hit:7 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:8 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Fetched 19.8 kB in 1s (14.6 kB/s)
Reading package lists... Done
The percona-release package now contains a percona-release script that can enable additional repositories for our newer products.

Note: currently there are no repositories that contain Percona products or distributions enabled. We recommend you to enable Percona Distribution repositories instead of individual product repositories, because with the Distribution you will get not only the database itself but also a set of other componets that will help you work with your database.

For example, to enable the Percona Distribution for MySQL 8.0 repository use:

  percona-release setup pdps8.0

Note: To avoid conflicts with older product versions, the percona-release setup command may disable our original repository for some products.

For more information, please visit:
  https://docs.percona.com/percona-software-repositories/percona-release.html

sre@ubuntu:~/simple_app/myapp$ sudo apt update
Hit:1 http://repo.percona.com/pmm2-client/apt noble InRelease
Hit:2 http://repo.percona.com/prel/apt noble InRelease                                                        
Hit:3 http://repo.percona.com/telemetry/apt noble InRelease                                                                         
Hit:4 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                                           
Hit:5 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:6 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:7 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
167 packages can be upgraded. Run 'apt list --upgradable' to see them.
sre@ubuntu:~/simple_app/myapp$ sudo percona-release setup ps80
* Disabling all Percona Repositories
* Enabling the Percona Server for MySQL 8.0 repository
* Enabling the Percona Tools repository
Hit:1 http://repo.percona.com/prel/apt noble InRelease
Get:2 http://repo.percona.com/ps-80/apt noble InRelease [15.9 kB]                                                                   
Hit:3 http://repo.percona.com/telemetry/apt noble InRelease                                                                                     
Get:4 http://repo.percona.com/tools/apt noble InRelease [15.8 kB]                                       
Hit:5 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                      
Hit:6 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease                 
Hit:7 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:8 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Get:9 http://repo.percona.com/ps-80/apt noble/main Sources [2,657 B]
Get:10 http://repo.percona.com/ps-80/apt noble/main amd64 Packages [22.3 kB]
Get:11 http://repo.percona.com/tools/apt noble/main Sources [1,572 B]
Get:12 http://repo.percona.com/tools/apt noble/main amd64 Packages [3,212 B]
Fetched 61.4 kB in 1s (46.5 kB/s)
Reading package lists... Done
sre@ubuntu:~/simple_app/myapp$ sudo apt install percona-server-server
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  bzip2 debsums libatomic1 libbz2-1.0 libdpkg-perl libfile-fcntllock-perl libfile-fnmatch-perl libmecab2 percona-server-client
  percona-server-common percona-telemetry-agent
Suggested packages:
  bzip2-doc debian-keyring gcc | c-compiler binutils bzr
The following NEW packages will be installed:
  bzip2 debsums libatomic1 libdpkg-perl libfile-fcntllock-perl libfile-fnmatch-perl libmecab2 percona-server-client percona-server-common
  percona-server-server percona-telemetry-agent
The following packages will be upgraded:
  libbz2-1.0
1 upgraded, 11 newly installed, 0 to remove and 166 not upgraded.
Need to get 184 MB of archives.
After this operation, 634 MB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://repo.percona.com/ps-80/apt noble/main amd64 percona-server-common amd64 8.0.40-31-1.noble [3,186 kB]
Get:2 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 libdpkg-perl all 1.22.6ubuntu6.1 [269 kB]
Get:3 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 libfile-fnmatch-perl amd64 0.02-3build4 [9,756 B]
Get:4 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 debsums all 3.0.2.1 [35.5 kB]
Get:5 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 libatomic1 amd64 14.2.0-4ubuntu2~24.04 [10.5 kB]
Get:6 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libmecab2 amd64 0.996-14ubuntu4 [201 kB]
Get:7 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 libbz2-1.0 amd64 1.0.8-5.1build0.1 [34.4 kB]
Get:8 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 bzip2 amd64 1.0.8-5.1build0.1 [34.5 kB]
Get:9 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libfile-fcntllock-perl amd64 0.22-4ubuntu5 [30.7 kB]
Get:10 http://repo.percona.com/ps-80/apt noble/main amd64 percona-server-client amd64 8.0.40-31-1.noble [24.7 MB]
Get:11 http://repo.percona.com/telemetry/apt noble/main amd64 percona-telemetry-agent amd64 1.0.3-3.noble [10.6 MB]
Get:12 http://repo.percona.com/ps-80/apt noble/main amd64 percona-server-server amd64 8.0.40-31-1.noble [145 MB]                                
Fetched 184 MB in 35s (5,222 kB/s)                                                                                                              
Preconfiguring packages ...
Selecting previously unselected package libdpkg-perl.
(Reading database ... 86781 files and directories currently installed.)
Preparing to unpack .../libdpkg-perl_1.22.6ubuntu6.1_all.deb ...
Unpacking libdpkg-perl (1.22.6ubuntu6.1) ...
Selecting previously unselected package libfile-fnmatch-perl.
Preparing to unpack .../libfile-fnmatch-perl_0.02-3build4_amd64.deb ...
Unpacking libfile-fnmatch-perl (0.02-3build4) ...
Selecting previously unselected package debsums.
Preparing to unpack .../debsums_3.0.2.1_all.deb ...
Unpacking debsums (3.0.2.1) ...
Setting up libdpkg-perl (1.22.6ubuntu6.1) ...
Setting up libfile-fnmatch-perl (0.02-3build4) ...
Setting up debsums (3.0.2.1) ...
Selecting previously unselected package percona-server-common.
(Reading database ... 87008 files and directories currently installed.)
Preparing to unpack .../0-percona-server-common_8.0.40-31-1.noble_amd64.deb ...
Unpacking percona-server-common (8.0.40-31-1.noble) ...
Selecting previously unselected package percona-server-client.
Preparing to unpack .../1-percona-server-client_8.0.40-31-1.noble_amd64.deb ...
Unpacking percona-server-client (8.0.40-31-1.noble) ...
Selecting previously unselected package percona-telemetry-agent.
Preparing to unpack .../2-percona-telemetry-agent_1.0.3-3.noble_amd64.deb ...
Unpacking percona-telemetry-agent (1.0.3-3.noble) ...
Selecting previously unselected package libatomic1:amd64.
Preparing to unpack .../3-libatomic1_14.2.0-4ubuntu2~24.04_amd64.deb ...
Unpacking libatomic1:amd64 (14.2.0-4ubuntu2~24.04) ...
Selecting previously unselected package libmecab2:amd64.
Preparing to unpack .../4-libmecab2_0.996-14ubuntu4_amd64.deb ...
Unpacking libmecab2:amd64 (0.996-14ubuntu4) ...
Selecting previously unselected package percona-server-server.
Preparing to unpack .../5-percona-server-server_8.0.40-31-1.noble_amd64.deb ...
Unpacking percona-server-server (8.0.40-31-1.noble) ...
Preparing to unpack .../6-libbz2-1.0_1.0.8-5.1build0.1_amd64.deb ...
Unpacking libbz2-1.0:amd64 (1.0.8-5.1build0.1) over (1.0.8-5.1) ...
Setting up libbz2-1.0:amd64 (1.0.8-5.1build0.1) ...
Selecting previously unselected package bzip2.
(Reading database ... 87383 files and directories currently installed.)
Preparing to unpack .../bzip2_1.0.8-5.1build0.1_amd64.deb ...
Unpacking bzip2 (1.0.8-5.1build0.1) ...
Selecting previously unselected package libfile-fcntllock-perl.
Preparing to unpack .../libfile-fcntllock-perl_0.22-4ubuntu5_amd64.deb ...
Unpacking libfile-fcntllock-perl (0.22-4ubuntu5) ...
Setting up libmecab2:amd64 (0.996-14ubuntu4) ...
Setting up libfile-fcntllock-perl (0.22-4ubuntu5) ...
Setting up percona-server-common (8.0.40-31-1.noble) ...
update-alternatives: using /etc/mysql/my.cnf.fallback to provide /etc/mysql/my.cnf (my.cnf) in auto mode
Setting up percona-server-client (8.0.40-31-1.noble) ...
Setting up bzip2 (1.0.8-5.1build0.1) ...
Setting up libatomic1:amd64 (14.2.0-4ubuntu2~24.04) ...
Setting up percona-telemetry-agent (1.0.3-3.noble) ...
Setting up percona-server-server (8.0.40-31-1.noble) ...
update-alternatives: using /etc/mysql/mysql.cnf to provide /etc/mysql/my.cnf (my.cnf) in auto mode


 * Percona Server is distributed with several useful UDF (User Defined Function) from Percona Toolkit.
 * Run the following commands to create these functions:

	mysql -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
	mysql -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
	mysql -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"

 * See http://www.percona.com/doc/percona-server/8.0/management/udf-percona-toolkit.html for more details


Created symlink /etc/systemd/system/multi-user.target.wants/mysql.service → /usr/lib/systemd/system/mysql.service.
Processing triggers for man-db (2.12.0-4build2) ...
Processing triggers for libc-bin (2.39-0ubuntu8.4) ...
Scanning processes...                                                                                                                            
Scanning candidates...                                                                                                                           
Scanning linux images...                                                                                                                         

Running kernel seems to be up-to-date.

Restarting services...
 systemctl restart packagekit.service

Service restarts being deferred:
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

User sessions running outdated binaries:
 sre @ session #1: apt[14911]

No VM guests are running outdated hypervisor (qemu) binaries on this host.
sre@ubuntu:~/simple_app/myapp$ 

sre@ubuntu:~/simple_app/myapp$ sudo systemctl status mysql
● mysql.service - Percona Server
     Loaded: loaded (/usr/lib/systemd/system/mysql.service; enabled; preset: enabled)
     Active: active (running) since Fri 2025-02-07 01:00:16 UTC; 1min 44s ago
    Process: 18196 ExecStartPre=/usr/share/mysql/mysql-systemd-start pre (code=exited, status=0/SUCCESS)
   Main PID: 18242 (mysqld)
     Status: "Server is operational"
      Tasks: 39 (limit: 2276)
     Memory: 373.0M (peak: 389.1M)
        CPU: 3.636s
     CGroup: /system.slice/mysql.service
             └─18242 /usr/sbin/mysqld

Feb 07 01:00:15 ubuntu systemd[1]: Starting mysql.service - Percona Server...
Feb 07 01:00:15 ubuntu (mysqld)[18242]: mysql.service: Referenced but unset environment variable evaluates to an empty string: MYSQLD_OPTS
Feb 07 01:00:16 ubuntu systemd[1]: Started mysql.service - Percona Server.
sre@ubuntu:~/simple_app/myapp$ sudo systemctl enable mysql
Synchronizing state of mysql.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable mysql

sre@ubuntu:~/simple_app/myapp$ ls -ld /etc/mysql/my.cnf
lrwxrwxrwx 1 root root 24 Feb  7 01:00 /etc/mysql/my.cnf -> /etc/alternatives/my.cnf
sre@ubuntu:~/simple_app/myapp$ wc -l /etc/mysql/my.cnf
13 /etc/mysql/my.cnf
sre@ubuntu:~/simple_app/myapp$ cat /etc/mysql/my.cnf
#
# The Percona Server 8.0 configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html
#
#
# * IMPORTANT: Additional settings that can override those from this file!
#   The files must end with '.cnf', otherwise they'll be ignored.
#

!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/

