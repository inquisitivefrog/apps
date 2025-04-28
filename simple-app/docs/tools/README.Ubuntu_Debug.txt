
New Commands
------------
1. sudo lvextend -L +1G /dev/ubuntu-vg/ubuntu-lv
  Size of logical volume ubuntu-vg/ubuntu-lv changed from 10.00 GiB (2560 extents) to 11.00 GiB (2816 extents).
2. sudo journalctl --vacuum-time=3d  # Keep only 3 days of logs
Vacuuming done, freed 0B of archived journals from /var/log/journal.
3. sudo truncate -s 0 /var/log/mysql/error.log
4. sudo apt-get clean # remove old packages

sudo apt update
sudo apt upgrade
sudo apt install -y default-jdk
which java
java -version
which javac
javac -version
sudo vi /etc/environment
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
echo $JAVA_HOME
sudo apt-get install -y maven
which mvn
mvn -version

mvn dependency:resolve
mvn compile
mvn clean package
mvn test

which docker
docker -version
docker info
docker images
docker ps
docker compose up --build

sudo vi /etc/mysql/mysql.conf.d/mysqld.cnf
sudo grep bind /etc/mysql/mysql.conf.d/mysqld.cnf
bind            = 0.0.0.0


mysql -u root -p -e "CREATE DATABASE testdb;"
mysql -u root -p -e "SHOW DATABASES LIKE 'testdb';"
mysql -u root -p -e "CREATE USER 'dbuser'@'localhost' IDENTIFIED BY 'G1ng3rb33r';"
mysql -u root -p -e "CREATE USER 'dbuser'@'%' IDENTIFIED BY 'G1ng3rb33r';"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON testdb.* TO 'dbuser'@'%';"
mysql -u root -p -e "SELECT Host, User FROM mysql.user WHERE User LIKE 'db%';"
mysql -u root -p -e "SHOW GRANTS FOR 'dbuser'@'localhost';"
mysql -u root -p -e "SHOW GRANTS FOR 'dbuser'@'%';"
sudo usermod -aG docker ${USER}

sudo systemctl restart mysql
systemctl status mysql.service
journalctl -xeu mysql.service
ss -at | grep LISTEN

hostname -I
vi src/main/resources/application.properties
cat src/main/resources/application.properties
docker build -t myapp-webapp .
docker run --rm --name webapp -p 8080:8080 myapp-webapp

sre@ubuntu:~/java_projects/simple_app$ sudo apt install -y libxml2-utils
[sudo] password for sre: 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following package was automatically installed and is no longer required:
  python3-netifaces
Use 'sudo apt autoremove' to remove it.
The following NEW packages will be installed:
  libxml2-utils
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 39.4 kB of archives.
After this operation, 187 kB of additional disk space will be used.
Get:1 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 libxml2-utils amd64 2.9.14+dfsg-1.3ubuntu3.1 [39.4 kB]
Fetched 39.4 kB in 0s (130 kB/s)         
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package libxml2-utils.
(Reading database ... 93906 files and directories currently installed.)
Preparing to unpack .../libxml2-utils_2.9.14+dfsg-1.3ubuntu3.1_amd64.deb ...
Unpacking libxml2-utils (2.9.14+dfsg-1.3ubuntu3.1) ...
Setting up libxml2-utils (2.9.14+dfsg-1.3ubuntu3.1) ...
Scanning processes...                                                                                                                            
Scanning linux images...                                                                                                                         

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.

