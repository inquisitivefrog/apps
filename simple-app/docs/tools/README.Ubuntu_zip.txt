
sre@ubuntu:~$ which unzip
sre@ubuntu:~$ sudo apt-get install -y zip
[sudo] password for sre: 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  libllvm17t64 linux-headers-6.8.0-39 linux-headers-6.8.0-39-generic linux-image-6.8.0-39-generic
  linux-modules-6.8.0-39-generic linux-modules-extra-6.8.0-39-generic linux-tools-6.8.0-39
  linux-tools-6.8.0-39-generic
Use 'sudo apt autoremove' to remove them.
The following additional packages will be installed:
  unzip
The following NEW packages will be installed:
  unzip zip
0 upgraded, 2 newly installed, 0 to remove and 11 not upgraded.
Need to get 350 kB of archives.
After this operation, 933 kB of additional disk space will be used.
Get:1 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 unzip amd64 6.0-28ubuntu4.1 [174 kB]
Get:2 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 zip amd64 3.0-13ubuntu0.2 [176 kB]
Fetched 350 kB in 1s (342 kB/s)
Selecting previously unselected package unzip.
(Reading database ... 202864 files and directories currently installed.)
Preparing to unpack .../unzip_6.0-28ubuntu4.1_amd64.deb ...
Unpacking unzip (6.0-28ubuntu4.1) ...
Selecting previously unselected package zip.
Preparing to unpack .../zip_3.0-13ubuntu0.2_amd64.deb ...
Unpacking zip (3.0-13ubuntu0.2) ...
Setting up unzip (6.0-28ubuntu4.1) ...
Setting up zip (3.0-13ubuntu0.2) ...
Processing triggers for man-db (2.12.0-4build2) ...
Scanning processes...                                                                                   
Scanning linux images...                                                                                

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
sre@ubuntu:~$ which zip
/usr/bin/zip

