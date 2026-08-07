
sre@ubuntu:~/simple_app/myapp$ sudo mysql -u root -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 9
Server version: 8.0.40-31 Percona Server (GPL), Release '31', Revision '49317865'

Copyright (c) 2009-2024 Percona LLC and/or its affiliates
Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> CREATE USER 'dbuser'@'localhost' IDENTIFIED BY 'G1ng3rb33r';
Query OK, 0 rows affected (0.03 sec)

mysql> GRANT ALL PRIVILEGES ON *.* TO 'dbuser'@'localhost' WITH GRANT OPTION;
Query OK, 0 rows affected (0.00 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.01 sec)

mysql> EXIT;
Bye
sre@ubuntu:~/simple_app/myapp$ which mysql
/usr/bin/mysql
sre@ubuntu:~/simple_app/myapp$ mysql -u dbuser@localhost -p
Enter password: 
ERROR 1045 (28000): Access denied for user 'dbuser@localhost'@'localhost' (using password: YES)
sre@ubuntu:~/simple_app/myapp$ mysql -u dbuser -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 11
Server version: 8.0.40-31 Percona Server (GPL), Release '31', Revision '49317865'

Copyright (c) 2009-2024 Percona LLC and/or its affiliates
Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> SELECT VERSION();
+-----------+
| VERSION() |
+-----------+
| 8.0.40-31 |
+-----------+
1 row in set (0.00 sec)

mysql> CREATE DATABASE testdb;
Query OK, 1 row affected (0.02 sec)

mysql> USE testdb;
Database changed
mysql> CREATE TABLE testtable (id INT, name VARCHAR(50));
Query OK, 0 rows affected (0.05 sec)

mysql> INSERT INTO testtable VALUES(1, 'Test Entry');
Query OK, 1 row affected (0.01 sec)

mysql> SELECT * FROM testtable;
+------+------------+
| id   | name       |
+------+------------+
|    1 | Test Entry |
+------+------------+
1 row in set (0.00 sec)

mysql> exit;
Bye
sre@ubuntu:~/simple_app/myapp$ 

