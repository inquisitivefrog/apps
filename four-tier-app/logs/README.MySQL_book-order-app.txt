
sre@ubuntu:~/java_projects/book-order-app/src/main$ systemctl status mysql
● mysql.service - Percona Server
     Loaded: loaded (/usr/lib/systemd/system/mysql.service; enabled; preset: enabled)
     Active: active (running) since Thu 2025-02-13 19:21:08 UTC; 25min ago
    Process: 724 ExecStartPre=/usr/share/mysql/mysql-systemd-start pre (code=exited, status=0/SUCCESS)
   Main PID: 834 (mysqld)
     Status: "Server is operational"
      Tasks: 40 (limit: 3480)
     Memory: 441.8M (peak: 450.7M)
        CPU: 35.098s
     CGroup: /system.slice/mysql.service
             └─834 /usr/sbin/mysqld

Feb 13 19:21:04 ubuntu systemd[1]: Starting mysql.service - Percona Server...
Feb 13 19:21:05 ubuntu (mysqld)[834]: mysql.service: Referenced but unset environment variable evaluates to an empty string: MYSQLD_OPTS
Feb 13 19:21:08 ubuntu systemd[1]: Started mysql.service - Percona Server.

sre@ubuntu:~/java_projects/book-order-app/src/main$ mysqladmin --user=dbuser --password ping
Enter password: 
mysqld is alive

sre@ubuntu:~/java_projects/book-order-app/src/main$ mysql -u root -p -e "CREATE DATABASE bookdb;"
Enter password: 
sre@ubuntu:~/java_projects/book-order-app/src/main$ mysql -u root -p -e "SHOW DATABASES LIKE 'bookdb';"
Enter password: 
+-------------------+
| Database (bookdb) |
+-------------------+
| bookdb            |
+-------------------+
sre@ubuntu:~/java_projects/book-order-app/src/main$ mysql -u root -p -e "GRANT ALL PRIVILEGES ON bookdb.* TO 'dbuser'@'%';"
Enter password: 
sre@ubuntu:~/java_projects/book-order-app/src/main$ mysql -u root -p -e "SHOW GRANTS FOR 'dbuser'@'%';"
Enter password: 
+----------------------------------------------------+
| Grants for dbuser@%                                |
+----------------------------------------------------+
| GRANT USAGE ON *.* TO `dbuser`@`%`                 |
| GRANT ALL PRIVILEGES ON `bookdb`.* TO `dbuser`@`%` |
| GRANT ALL PRIVILEGES ON `testdb`.* TO `dbuser`@`%` |
+----------------------------------------------------+
sre@ubuntu:~/java_projects/book-order-app/src/main$ 

