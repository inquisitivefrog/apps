
sre@ubuntu:~$ sudo ls -l /etc/netplan/50-cloud-init.yaml 
[sudo] password for sre: 
-rw------- 1 root root 618 Feb 12 22:48 /etc/netplan/50-cloud-init.yaml
sre@ubuntu:~$ sudo vi /etc/netplan/50-cloud-init.yaml 
sre@ubuntu:~$ sudo cat /etc/netplan/50-cloud-init.yaml 
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    renderer: networkd
    ethernets:
        enp0s3:
            dhcp4: no
            addresses:
              - 192.168.1.107/24
            routes:
              - to: default
                via: 192.168.1.1
            nameservers:
              addresses: [8.8.8.8, 8.8.4.4]
    version: 2
sre@ubuntu:~$ sudo netplan apply
sre@ubuntu:~$ 

sre@ubuntu:~$ ip addr show enp0s3
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:ff:ff:74 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.107/24 brd 192.168.1.255 scope global enp0s3
       valid_lft forever preferred_lft forever
    inet6 2001:5a8:49c6:ce00:a00:27ff:feff:ff74/64 scope global dynamic mngtmpaddr noprefixroute 
       valid_lft 20946sec preferred_lft 20946sec
    inet6 fe80::a00:27ff:feff:ff74/64 scope link 
       valid_lft forever preferred_lft forever

