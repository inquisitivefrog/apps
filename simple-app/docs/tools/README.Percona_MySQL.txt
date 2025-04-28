
sre@ubuntu:~/java_projects/simple_app/myapp$ systemctl status mysql
Unit mysql.service could not be found.
sre@ubuntu:~/java_projects/simple_app/myapp$ sudo apt install -y wget
[sudo] password for sre: 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
wget is already the newest version (1.21.4-1ubuntu4.1).
wget set to manually installed.
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
sre@ubuntu:~/java_projects/simple_app/myapp$ wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
--2025-02-12 04:52:39--  https://repo.percona.com/apt/percona-release_latest.generic_all.deb
Resolving repo.percona.com (repo.percona.com)... 2604:2dc0:200:69f::2, 147.135.54.159
Connecting to repo.percona.com (repo.percona.com)|2604:2dc0:200:69f::2|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 16510 (16K) [application/x-debian-package]
Saving to: ‘percona-release_latest.generic_all.deb’

percona-release_latest.generic_all.deb    100%[===================================================================================>]  16.12K  --.-KB/s    in 0.001s  

2025-02-12 04:52:39 (27.6 MB/s) - ‘percona-release_latest.generic_all.deb’ saved [16510/16510]

sre@ubuntu:~/java_projects/simple_app/myapp$ sudo dpkg -i percona-release_latest.generic_all.deb
Selecting previously unselected package percona-release.
(Reading database ... 103271 files and directories currently installed.)
Preparing to unpack percona-release_latest.generic_all.deb ...
Unpacking percona-release (1.0-29.generic) ...
Setting up percona-release (1.0-29.generic) ...
grep: /etc/apt/sources.list.d/percona*: No such file or directory
ERROR: Invalid filename format: percona*
* Enabling the Percona Release repository
Get:1 http://repo.percona.com/prel/apt noble InRelease [12.8 kB]
Hit:2 https://download.docker.com/linux/ubuntu noble InRelease                                                                                                       
Hit:3 http://security.ubuntu.com/ubuntu noble-security InRelease                                                                                          
Hit:4 http://us.archive.ubuntu.com/ubuntu noble InRelease                                       
Hit:5 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease
Get:6 http://repo.percona.com/prel/apt noble/main amd64 Packages [545 B]
Hit:7 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Fetched 13.3 kB in 1s (14.4 kB/s)
Reading package lists... Done
* Enabling the Percona Telemetry repository
Hit:1 http://repo.percona.com/prel/apt noble InRelease
Hit:2 https://download.docker.com/linux/ubuntu noble InRelease                                                                                                       
Get:3 http://repo.percona.com/telemetry/apt noble InRelease [12.8 kB]                                                                                                
Hit:4 http://security.ubuntu.com/ubuntu noble-security InRelease                                                                                                     
Hit:5 http://us.archive.ubuntu.com/ubuntu noble InRelease                                       
Hit:6 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease
Get:7 http://repo.percona.com/telemetry/apt noble/main Sources [1,382 B]
Hit:8 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease 
Get:9 http://repo.percona.com/telemetry/apt noble/main amd64 Packages [842 B]
Fetched 15.0 kB in 1s (14.5 kB/s)
Reading package lists... Done
* Enabling the PMM2 Client repository
Get:1 http://repo.percona.com/pmm2-client/apt noble InRelease [18.7 kB]
Hit:2 https://download.docker.com/linux/ubuntu noble InRelease                                                                                                       
Hit:3 http://repo.percona.com/prel/apt noble InRelease                                                                                                               
Hit:4 http://repo.percona.com/telemetry/apt noble InRelease                                             
Hit:5 http://us.archive.ubuntu.com/ubuntu noble InRelease                         
Hit:6 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease                 
Hit:7 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:8 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Get:9 http://repo.percona.com/pmm2-client/apt noble/main amd64 Packages [1,119 B]
Fetched 19.8 kB in 1s (17.0 kB/s)
Reading package lists... Done
The percona-release package now contains a percona-release script that can enable additional repositories for our newer products.

Note: currently there are no repositories that contain Percona products or distributions enabled. We recommend you to enable Percona Distribution repositories instead of individual product repositories, because with the Distribution you will get not only the database itself but also a set of other componets that will help you work with your database.

For example, to enable the Percona Distribution for MySQL 8.0 repository use:

  percona-release setup pdps8.0

Note: To avoid conflicts with older product versions, the percona-release setup command may disable our original repository for some products.

For more information, please visit:
  https://docs.percona.com/percona-software-repositories/percona-release.html

sre@ubuntu:~/java_projects/simple_app/myapp$ sudo percona-release setup ps80
* Disabling all Percona Repositories
* Enabling the Percona Server for MySQL 8.0 repository
* Enabling the Percona Tools repository
Hit:1 http://repo.percona.com/prel/apt noble InRelease
Hit:2 https://download.docker.com/linux/ubuntu noble InRelease                                                                                            
Get:3 http://repo.percona.com/ps-80/apt noble InRelease [15.9 kB]                                                                                         
Hit:4 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                           
Hit:5 http://repo.percona.com/telemetry/apt noble InRelease                                             
Get:6 http://repo.percona.com/tools/apt noble InRelease [15.8 kB]   
Hit:7 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease   
Hit:8 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:9 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Get:10 http://repo.percona.com/ps-80/apt noble/main Sources [2,657 B]
Get:11 http://repo.percona.com/ps-80/apt noble/main amd64 Packages [22.3 kB]
Get:12 http://repo.percona.com/tools/apt noble/main Sources [1,572 B]
Get:13 http://repo.percona.com/tools/apt noble/main amd64 Packages [3,212 B]
Fetched 61.4 kB in 1s (47.8 kB/s)    
Reading package lists... Done
sre@ubuntu:~/java_projects/simple_app/myapp$ sudo apt update
Hit:1 https://download.docker.com/linux/ubuntu noble InRelease
Hit:2 http://repo.percona.com/prel/apt noble InRelease                                                                              
Hit:3 http://repo.percona.com/ps-80/apt noble InRelease                                                                             
Hit:4 http://repo.percona.com/telemetry/apt noble InRelease                                                                         
Hit:5 http://repo.percona.com/tools/apt noble InRelease                                                                                                   
Hit:6 http://us.archive.ubuntu.com/ubuntu noble InRelease                                                                                                 
Hit:7 http://security.ubuntu.com/ubuntu noble-security InRelease                                                                    
Hit:8 http://us.archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:9 http://us.archive.ubuntu.com/ubuntu noble-backports InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
All packages are up to date.
sre@ubuntu:~/java_projects/simple_app/myapp$ sudo apt install -y percona-server-server
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  bzip2 debsums libatomic1 libdpkg-perl libfile-fcntllock-perl libfile-fnmatch-perl libmecab2 percona-server-client percona-server-common percona-telemetry-agent
Suggested packages:
  bzip2-doc debian-keyring gcc | c-compiler binutils bzr
The following NEW packages will be installed:
  bzip2 debsums libatomic1 libdpkg-perl libfile-fcntllock-perl libfile-fnmatch-perl libmecab2 percona-server-client percona-server-common percona-server-server
  percona-telemetry-agent
0 upgraded, 11 newly installed, 0 to remove and 0 not upgraded.
Need to get 184 MB of archives.
After this operation, 634 MB of additional disk space will be used.
Get:1 http://repo.percona.com/ps-80/apt noble/main amd64 percona-server-common amd64 8.0.40-31-1.noble [3,186 kB]
Get:2 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 libdpkg-perl all 1.22.6ubuntu6.1 [269 kB]            
Get:3 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 libfile-fnmatch-perl amd64 0.02-3build4 [9,756 B]        
Get:4 http://us.archive.ubuntu.com/ubuntu noble/universe amd64 debsums all 3.0.2.1 [35.5 kB]   
Get:5 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 libatomic1 amd64 14.2.0-4ubuntu2~24.04 [10.5 kB]
Get:6 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libmecab2 amd64 0.996-14ubuntu4 [201 kB]
Get:7 http://us.archive.ubuntu.com/ubuntu noble-updates/main amd64 bzip2 amd64 1.0.8-5.1build0.1 [34.5 kB]
Get:8 http://us.archive.ubuntu.com/ubuntu noble/main amd64 libfile-fcntllock-perl amd64 0.22-4ubuntu5 [30.7 kB]
Get:9 http://repo.percona.com/ps-80/apt noble/main amd64 percona-server-client amd64 8.0.40-31-1.noble [24.7 MB]
Get:10 http://repo.percona.com/telemetry/apt noble/main amd64 percona-telemetry-agent amd64 1.0.3-3.noble [10.6 MB]
Get:11 http://repo.percona.com/ps-80/apt noble/main amd64 percona-server-server amd64 8.0.40-31-1.noble [145 MB]       
Fetched 184 MB in 37s (4,936 kB/s)                                                                                                                                   
Preconfiguring packages ...
Selecting previously unselected package libdpkg-perl.
(Reading database ... 103276 files and directories currently installed.)
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
(Reading database ... 103503 files and directories currently installed.)
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
Selecting previously unselected package bzip2.
Preparing to unpack .../6-bzip2_1.0.8-5.1build0.1_amd64.deb ...
Unpacking bzip2 (1.0.8-5.1build0.1) ...
Selecting previously unselected package libfile-fcntllock-perl.
Preparing to unpack .../7-libfile-fcntllock-perl_0.22-4ubuntu5_amd64.deb ...
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

Service restarts being deferred:
 /etc/needrestart/restart.d/dbus.service
 systemctl restart systemd-logind.service
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

User sessions running outdated binaries:
 sre @ session #1: login[2064]
 sre @ user manager service: systemd[2365]

No VM guests are running outdated hypervisor (qemu) binaries on this host.

sre@ubuntu:~/java_projects/simple_app/myapp$ systemctl status mysql
● mysql.service - Percona Server
     Loaded: loaded (/usr/lib/systemd/system/mysql.service; enabled; preset: enabled)
     Active: active (running) since Wed 2025-02-12 04:55:59 UTC; 9min ago
    Process: 26668 ExecStartPre=/usr/share/mysql/mysql-systemd-start pre (code=exited, status=0/SUCCESS)
   Main PID: 26713 (mysqld)
     Status: "Server is operational"
      Tasks: 40 (limit: 3479)
     Memory: 367.8M (peak: 385.3M)
        CPU: 18.366s
     CGroup: /system.slice/mysql.service
             └─26713 /usr/sbin/mysqld

Feb 12 04:55:58 ubuntu systemd[1]: Starting mysql.service - Percona Server...
Feb 12 04:55:58 ubuntu (mysqld)[26713]: mysql.service: Referenced but unset environment variable evaluates to an empty string: MYSQLD_OPTS
Feb 12 04:55:59 ubuntu systemd[1]: Started mysql.service - Percona Server.

sre@ubuntu:~/java_projects/simple_app/myapp$ mysql -u root -p 
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 12
Server version: 8.0.40-31 Percona Server (GPL), Release '31', Revision '49317865'

Copyright (c) 2009-2024 Percona LLC and/or its affiliates
Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> CREATE DATABASE testdb;
Query OK, 1 row affected (0.01 sec)

mysql> CREATE USER 'dbuser'@'localhost' IDENTIFIED BY 'G1ng3rb33r';
Query OK, 0 rows affected (0.02 sec)

mysql> GRANT ALL PRIVILEGES ON testdb.* TO 'dbuser'@'localhost';
Query OK, 0 rows affected (0.01 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.02 sec)

mysql> EXIT;
Bye
sre@ubuntu:~/java_projects/simple_app/myapp$ 

sre@ubuntu:~/java_projects/simple_app/myapp$ mysql -u dbuser -p -e "SHOW DATABASES;"
Enter password: 
+--------------------+
| Database           |
+--------------------+
| information_schema |
| performance_schema |
| testdb             |
+--------------------+

sre@ubuntu:~/java_projects/simple_app/myapp$ mysqladmin --user=dbuser --password status
Enter password: 
Uptime: 659  Threads: 2  Questions: 11  Slow queries: 0  Opens: 185  Flush tables: 4  Open tables: 86  Queries per second avg: 0.016

sre@ubuntu:~/java_projects/simple_app/myapp$ mysqladmin --user=dbuser --password processlist
Enter password: 
+----+--------+-----------+----+---------+------+-------+------------------+---------+-----------+---------------+
| Id | User   | Host      | db | Command | Time | State | Info             | Time_ms | Rows_sent | Rows_examined |
+----+--------+-----------+----+---------+------+-------+------------------+---------+-----------+---------------+
| 16 | dbuser | localhost |    | Query   | 0    | init  | show processlist | 0       | 0         | 0             |
+----+--------+-----------+----+---------+------+-------+------------------+---------+-----------+---------------+

sre@ubuntu:~/java_projects/simple_app/myapp$ mysqladmin --user=dbuser --password --show-warnings ping
Enter password: 
mysqld is alive
sre@ubuntu:~/java_projects/simple_app/myapp$ mysqladmin --user=dbuser --password --show-warnings version
Enter password: 
mysqladmin  Ver 8.0.40-31 for Linux on x86_64 (Percona Server (GPL), Release '31', Revision '49317865')
Copyright (c) 2009-2024 Percona LLC and/or its affiliates
Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Server version		8.0.40-31
Protocol version	10
Connection		Localhost via UNIX socket
UNIX socket		/var/run/mysqld/mysqld.sock
Uptime:			15 min 0 sec

Threads: 2  Questions: 20  Slow queries: 0  Opens: 202  Flush tables: 4  Open tables: 103  Queries per second avg: 0.022

sre@ubuntu:~/java_projects/simple_app/myapp$ mysql -u root -p -e "SELECT VARIABLE_NAME, VARIABLE_VALUE FROM performance_schema.global_variables" -B --silent --batch | jq -Rn '
[inputs | split("\t") | if length == 2 then { (. | .[0]): .[1] } else empty end] | add'
Enter password: 
{
  "activate_all_roles_on_login": "OFF",
  "admin_address": "",
  "admin_port": "33062",
  "admin_ssl_ca": "",
  "admin_ssl_capath": "",
  "admin_ssl_cert": "",
  "admin_ssl_cipher": "",
  "admin_ssl_crl": "",
  "admin_ssl_crlpath": "",
  "admin_ssl_key": "",
  "admin_tls_ciphersuites": "",
  "admin_tls_version": "TLSv1.2,TLSv1.3",
  "authentication_policy": "*,,",
  "auto_generate_certs": "ON",
  "auto_increment_increment": "1",
  "auto_increment_offset": "1",
  "autocommit": "ON",
  "automatic_sp_privileges": "ON",
  "avoid_temporal_upgrade": "OFF",
  "back_log": "151",
  "basedir": "/usr/",
  "big_tables": "OFF",
  "bind_address": "*",
  "binlog_cache_size": "32768",
  "binlog_checksum": "CRC32",
  "binlog_ddl_skip_rewrite": "OFF",
  "binlog_direct_non_transactional_updates": "OFF",
  "binlog_encryption": "OFF",
  "binlog_error_action": "ABORT_SERVER",
  "binlog_expire_logs_auto_purge": "ON",
  "binlog_expire_logs_seconds": "2592000",
  "binlog_format": "ROW",
  "binlog_group_commit_sync_delay": "0",
  "binlog_group_commit_sync_no_delay_count": "0",
  "binlog_gtid_simple_recovery": "ON",
  "binlog_max_flush_queue_time": "0",
  "binlog_order_commits": "ON",
  "binlog_rotate_encryption_master_key_at_startup": "OFF",
  "binlog_row_event_max_size": "8192",
  "binlog_row_image": "FULL",
  "binlog_row_metadata": "MINIMAL",
  "binlog_row_value_options": "",
  "binlog_rows_query_log_events": "OFF",
  "binlog_skip_flush_commands": "OFF",
  "binlog_space_limit": "0",
  "binlog_stmt_cache_size": "32768",
  "binlog_transaction_compression": "OFF",
  "binlog_transaction_compression_level_zstd": "3",
  "binlog_transaction_dependency_history_size": "25000",
  "binlog_transaction_dependency_tracking": "COMMIT_ORDER",
  "block_encryption_mode": "aes-128-ecb",
  "buffered_error_log_filename": "",
  "buffered_error_log_size": "0",
  "build_id": "db39432cca0b5d586d4d9a5317f00840e5075403",
  "bulk_insert_buffer_size": "8388608",
  "caching_sha2_password_auto_generate_rsa_keys": "ON",
  "caching_sha2_password_digest_rounds": "5000",
  "caching_sha2_password_private_key_path": "private_key.pem",
  "caching_sha2_password_public_key_path": "public_key.pem",
  "character_set_client": "utf8mb4",
  "character_set_connection": "utf8mb4",
  "character_set_database": "utf8mb4",
  "character_set_filesystem": "binary",
  "character_set_results": "utf8mb4",
  "character_set_server": "utf8mb4",
  "character_set_system": "utf8mb3",
  "character_sets_dir": "/usr/share/mysql/charsets/",
  "check_proxy_users": "OFF",
  "collation_connection": "utf8mb4_0900_ai_ci",
  "collation_database": "utf8mb4_0900_ai_ci",
  "collation_server": "utf8mb4_0900_ai_ci",
  "completion_type": "NO_CHAIN",
  "concurrent_insert": "AUTO",
  "connect_timeout": "10",
  "connection_memory_chunk_size": "8192",
  "connection_memory_limit": "18446744073709551615",
  "core_file": "OFF",
  "create_admin_listener_thread": "OFF",
  "cte_max_recursion_depth": "1000",
  "datadir": "/var/lib/mysql/",
  "default_authentication_plugin": "mysql_native_password",
  "default_collation_for_utf8mb4": "utf8mb4_0900_ai_ci",
  "default_password_lifetime": "0",
  "default_storage_engine": "InnoDB",
  "default_table_encryption": "OFF",
  "default_tmp_storage_engine": "InnoDB",
  "default_week_format": "0",
  "delay_key_write": "ON",
  "delayed_insert_limit": "100",
  "delayed_insert_timeout": "300",
  "delayed_queue_size": "1000",
  "disabled_storage_engines": "",
  "disconnect_on_expired_password": "ON",
  "div_precision_increment": "4",
  "encrypt_tmp_files": "OFF",
  "end_markers_in_json": "OFF",
  "enforce_gtid_consistency": "OFF",
  "enforce_storage_engine": "",
  "eq_range_index_dive_limit": "200",
  "event_scheduler": "ON",
  "expand_fast_index_creation": "OFF",
  "expire_logs_days": "0",
  "explain_format": "TRADITIONAL",
  "explicit_defaults_for_timestamp": "ON",
  "flush": "OFF",
  "flush_time": "0",
  "foreign_key_checks": "ON",
  "ft_boolean_syntax": "+ -><()~*:\"\"&|",
  "ft_max_word_len": "84",
  "ft_min_word_len": "4",
  "ft_query_expansion_limit": "20",
  "ft_query_extra_word_chars": "OFF",
  "ft_stopword_file": "(built-in)",
  "general_log": "OFF",
  "general_log_file": "/var/lib/mysql/ubuntu.log",
  "generated_random_password_length": "20",
  "global_connection_memory_limit": "18446744073709551615",
  "global_connection_memory_tracking": "OFF",
  "group_concat_max_len": "1024",
  "group_replication_consistency": "EVENTUAL",
  "gtid_executed": "",
  "gtid_executed_compression_period": "0",
  "gtid_mode": "OFF",
  "gtid_owned": "",
  "gtid_purged": "",
  "have_backup_locks": "YES",
  "have_backup_safe_binlog_info": "YES",
  "have_compress": "YES",
  "have_dynamic_loading": "YES",
  "have_geometry": "YES",
  "have_openssl": "YES",
  "have_profiling": "YES",
  "have_query_cache": "NO",
  "have_rtree_keys": "YES",
  "have_snapshot_cloning": "YES",
  "have_ssl": "YES",
  "have_statement_timeout": "YES",
  "have_symlink": "DISABLED",
  "histogram_generation_max_mem_size": "20000000",
  "host_cache_size": "279",
  "hostname": "ubuntu",
  "information_schema_stats_expiry": "86400",
  "init_connect": "",
  "init_file": "",
  "init_replica": "",
  "init_slave": "",
  "innodb_adaptive_flushing": "ON",
  "innodb_adaptive_flushing_lwm": "10",
  "innodb_adaptive_hash_index": "ON",
  "innodb_adaptive_hash_index_parts": "8",
  "innodb_adaptive_max_sleep_delay": "150000",
  "innodb_api_bk_commit_interval": "5",
  "innodb_api_disable_rowlock": "OFF",
  "innodb_api_enable_binlog": "OFF",
  "innodb_api_enable_mdl": "OFF",
  "innodb_api_trx_level": "0",
  "innodb_autoextend_increment": "64",
  "innodb_autoinc_lock_mode": "2",
  "innodb_buffer_pool_chunk_size": "134217728",
  "innodb_buffer_pool_dump_at_shutdown": "ON",
  "innodb_buffer_pool_dump_now": "OFF",
  "innodb_buffer_pool_dump_pct": "25",
  "innodb_buffer_pool_filename": "ib_buffer_pool",
  "innodb_buffer_pool_in_core_file": "ON",
  "innodb_buffer_pool_instances": "1",
  "innodb_buffer_pool_load_abort": "OFF",
  "innodb_buffer_pool_load_at_startup": "ON",
  "innodb_buffer_pool_load_now": "OFF",
  "innodb_buffer_pool_size": "134217728",
  "innodb_change_buffer_max_size": "25",
  "innodb_change_buffering": "all",
  "innodb_checksum_algorithm": "crc32",
  "innodb_cleaner_lsn_age_factor": "high_checkpoint",
  "innodb_cmp_per_index_enabled": "OFF",
  "innodb_commit_concurrency": "0",
  "innodb_compressed_columns_threshold": "96",
  "innodb_compressed_columns_zip_level": "6",
  "innodb_compression_failure_threshold_pct": "5",
  "innodb_compression_level": "6",
  "innodb_compression_pad_pct_max": "50",
  "innodb_concurrency_tickets": "5000",
  "innodb_corrupt_table_action": "assert",
  "innodb_data_file_path": "ibdata1:12M:autoextend",
  "innodb_data_home_dir": "",
  "innodb_ddl_buffer_size": "1048576",
  "innodb_ddl_threads": "4",
  "innodb_deadlock_detect": "ON",
  "innodb_dedicated_server": "OFF",
  "innodb_default_row_format": "dynamic",
  "innodb_directories": "",
  "innodb_disable_sort_file_cache": "OFF",
  "innodb_doublewrite": "ON",
  "innodb_doublewrite_batch_size": "0",
  "innodb_doublewrite_dir": "",
  "innodb_doublewrite_files": "2",
  "innodb_doublewrite_pages": "4",
  "innodb_empty_free_list_algorithm": "legacy",
  "innodb_encrypt_online_alter_logs": "OFF",
  "innodb_extend_and_initialize": "ON",
  "innodb_fast_shutdown": "1",
  "innodb_file_per_table": "ON",
  "innodb_fill_factor": "100",
  "innodb_flush_log_at_timeout": "1",
  "innodb_flush_log_at_trx_commit": "1",
  "innodb_flush_method": "fsync",
  "innodb_flush_neighbors": "0",
  "innodb_flush_sync": "ON",
  "innodb_flushing_avg_loops": "30",
  "innodb_force_index_records_in_range": "0",
  "innodb_force_load_corrupted": "OFF",
  "innodb_force_recovery": "0",
  "innodb_fsync_threshold": "0",
  "innodb_ft_aux_table": "",
  "innodb_ft_cache_size": "8000000",
  "innodb_ft_enable_diag_print": "OFF",
  "innodb_ft_enable_stopword": "ON",
  "innodb_ft_ignore_stopwords": "OFF",
  "innodb_ft_max_token_size": "84",
  "innodb_ft_min_token_size": "3",
  "innodb_ft_num_word_optimize": "2000",
  "innodb_ft_result_cache_limit": "2000000000",
  "innodb_ft_server_stopword_table": "",
  "innodb_ft_sort_pll_degree": "2",
  "innodb_ft_total_cache_size": "640000000",
  "innodb_ft_user_stopword_table": "",
  "innodb_idle_flush_pct": "100",
  "innodb_io_capacity": "200",
  "innodb_io_capacity_max": "2000",
  "innodb_lock_wait_timeout": "50",
  "innodb_log_buffer_size": "16777216",
  "innodb_log_checksums": "ON",
  "innodb_log_compressed_pages": "ON",
  "innodb_log_file_size": "50331648",
  "innodb_log_files_in_group": "2",
  "innodb_log_group_home_dir": "./",
  "innodb_log_spin_cpu_abs_lwm": "80",
  "innodb_log_spin_cpu_pct_hwm": "50",
  "innodb_log_wait_for_flush_spin_hwm": "400",
  "innodb_log_write_ahead_size": "8192",
  "innodb_log_writer_threads": "ON",
  "innodb_lru_scan_depth": "1024",
  "innodb_max_dirty_pages_pct": "90.000000",
  "innodb_max_dirty_pages_pct_lwm": "10.000000",
  "innodb_max_purge_lag": "0",
  "innodb_max_purge_lag_delay": "0",
  "innodb_max_undo_log_size": "1073741824",
  "innodb_monitor_disable": "",
  "innodb_monitor_enable": "",
  "innodb_monitor_reset": "",
  "innodb_monitor_reset_all": "",
  "innodb_numa_interleave": "OFF",
  "innodb_old_blocks_pct": "37",
  "innodb_old_blocks_time": "1000",
  "innodb_online_alter_log_max_size": "134217728",
  "innodb_open_files": "4000",
  "innodb_optimize_fulltext_only": "OFF",
  "innodb_page_cleaners": "1",
  "innodb_page_size": "16384",
  "innodb_parallel_dblwr_encrypt": "OFF",
  "innodb_parallel_doublewrite_path": "xb_doublewrite",
  "innodb_parallel_read_threads": "4",
  "innodb_print_all_deadlocks": "OFF",
  "innodb_print_ddl_logs": "OFF",
  "innodb_print_lock_wait_timeout_info": "OFF",
  "innodb_purge_batch_size": "300",
  "innodb_purge_rseg_truncate_frequency": "128",
  "innodb_purge_threads": "4",
  "innodb_random_read_ahead": "OFF",
  "innodb_read_ahead_threshold": "56",
  "innodb_read_io_threads": "4",
  "innodb_read_only": "OFF",
  "innodb_records_in_range": "0",
  "innodb_redo_log_archive_dirs": "",
  "innodb_redo_log_capacity": "104857600",
  "innodb_redo_log_encrypt": "OFF",
  "innodb_replication_delay": "0",
  "innodb_rollback_on_timeout": "OFF",
  "innodb_rollback_segments": "128",
  "innodb_segment_reserve_factor": "12.500000",
  "innodb_show_locks_held": "10",
  "innodb_sort_buffer_size": "1048576",
  "innodb_spin_wait_delay": "6",
  "innodb_spin_wait_pause_multiplier": "50",
  "innodb_stats_auto_recalc": "ON",
  "innodb_stats_include_delete_marked": "OFF",
  "innodb_stats_method": "nulls_equal",
  "innodb_stats_on_metadata": "OFF",
  "innodb_stats_persistent": "ON",
  "innodb_stats_persistent_sample_pages": "20",
  "innodb_stats_transient_sample_pages": "8",
  "innodb_status_output": "OFF",
  "innodb_status_output_locks": "OFF",
  "innodb_strict_mode": "ON",
  "innodb_sync_array_size": "1",
  "innodb_sync_spin_loops": "30",
  "innodb_sys_tablespace_encrypt": "OFF",
  "innodb_table_locks": "ON",
  "innodb_temp_data_file_path": "ibtmp1:12M:autoextend",
  "innodb_temp_tablespace_encrypt": "OFF",
  "innodb_temp_tablespaces_dir": "./#innodb_temp/",
  "innodb_thread_concurrency": "0",
  "innodb_thread_sleep_delay": "10000",
  "innodb_tmpdir": "",
  "innodb_undo_directory": "./",
  "innodb_undo_log_encrypt": "OFF",
  "innodb_undo_log_truncate": "ON",
  "innodb_undo_tablespaces": "2",
  "innodb_use_fdatasync": "OFF",
  "innodb_use_native_aio": "ON",
  "innodb_validate_tablespace_paths": "ON",
  "innodb_version": "8.0.40-31",
  "innodb_write_io_threads": "4",
  "interactive_timeout": "28800",
  "internal_tmp_mem_storage_engine": "TempTable",
  "jemalloc_detected": "OFF",
  "jemalloc_profiling": "OFF",
  "join_buffer_size": "262144",
  "keep_files_on_create": "OFF",
  "key_buffer_size": "8388608",
  "key_cache_age_threshold": "300",
  "key_cache_block_size": "1024",
  "key_cache_division_limit": "100",
  "keyring_operations": "ON",
  "kill_idle_transaction": "0",
  "large_files_support": "ON",
  "large_page_size": "0",
  "large_pages": "OFF",
  "lc_messages": "en_US",
  "lc_messages_dir": "/usr/share/mysql/",
  "lc_time_names": "en_US",
  "license": "GPL",
  "local_infile": "OFF",
  "lock_wait_timeout": "31536000",
  "locked_in_memory": "OFF",
  "log_bin": "ON",
  "log_bin_basename": "/var/lib/mysql/binlog",
  "log_bin_index": "/var/lib/mysql/binlog.index",
  "log_bin_trust_function_creators": "OFF",
  "log_bin_use_v1_row_events": "OFF",
  "log_error": "/var/log/mysql/error.log",
  "log_error_services": "log_filter_internal; log_sink_internal",
  "log_error_suppression_list": "",
  "log_error_verbosity": "2",
  "log_output": "FILE",
  "log_queries_not_using_indexes": "OFF",
  "log_query_errors": "",
  "log_raw": "OFF",
  "log_replica_updates": "ON",
  "log_slave_updates": "ON",
  "log_slow_admin_statements": "OFF",
  "log_slow_extra": "OFF",
  "log_slow_filter": "",
  "log_slow_rate_limit": "1",
  "log_slow_rate_type": "session",
  "log_slow_replica_statements": "OFF",
  "log_slow_slave_statements": "OFF",
  "log_slow_sp_statements": "ON",
  "log_slow_verbosity": "",
  "log_statements_unsafe_for_binlog": "ON",
  "log_throttle_queries_not_using_indexes": "0",
  "log_timestamps": "UTC",
  "long_query_time": "10.000000",
  "low_priority_updates": "OFF",
  "lower_case_file_system": "OFF",
  "lower_case_table_names": "0",
  "mandatory_roles": "",
  "master_info_repository": "TABLE",
  "master_verify_checksum": "OFF",
  "max_allowed_packet": "67108864",
  "max_binlog_cache_size": "18446744073709547520",
  "max_binlog_size": "1073741824",
  "max_binlog_stmt_cache_size": "18446744073709547520",
  "max_connect_errors": "100",
  "max_connections": "151",
  "max_delayed_threads": "20",
  "max_digest_length": "1024",
  "max_error_count": "1024",
  "max_execution_time": "0",
  "max_heap_table_size": "16777216",
  "max_insert_delayed_threads": "20",
  "max_join_size": "18446744073709551615",
  "max_length_for_sort_data": "4096",
  "max_points_in_geometry": "65536",
  "max_prepared_stmt_count": "16382",
  "max_relay_log_size": "0",
  "max_seeks_for_key": "18446744073709551615",
  "max_slowlog_files": "0",
  "max_slowlog_size": "0",
  "max_sort_length": "1024",
  "max_sp_recursion_depth": "0",
  "max_user_connections": "0",
  "max_write_lock_count": "18446744073709551615",
  "min_examined_row_limit": "0",
  "myisam_data_pointer_size": "6",
  "myisam_max_sort_file_size": "9223372036853727232",
  "myisam_mmap_size": "18446744073709551615",
  "myisam_recover_options": "OFF",
  "myisam_sort_buffer_size": "8388608",
  "myisam_stats_method": "nulls_unequal",
  "myisam_use_mmap": "OFF",
  "mysql_native_password_proxy_users": "OFF",
  "mysqlx_bind_address": "*",
  "mysqlx_compression_algorithms": "DEFLATE_STREAM,LZ4_MESSAGE,ZSTD_STREAM",
  "mysqlx_connect_timeout": "30",
  "mysqlx_deflate_default_compression_level": "3",
  "mysqlx_deflate_max_client_compression_level": "5",
  "mysqlx_document_id_unique_prefix": "0",
  "mysqlx_enable_hello_notice": "ON",
  "mysqlx_idle_worker_thread_timeout": "60",
  "mysqlx_interactive_timeout": "28800",
  "mysqlx_lz4_default_compression_level": "2",
  "mysqlx_lz4_max_client_compression_level": "8",
  "mysqlx_max_allowed_packet": "67108864",
  "mysqlx_max_connections": "100",
  "mysqlx_min_worker_threads": "2",
  "mysqlx_port": "33060",
  "mysqlx_port_open_timeout": "0",
  "mysqlx_read_timeout": "30",
  "mysqlx_socket": "/var/run/mysqld/mysqlx.sock",
  "mysqlx_ssl_ca": "",
  "mysqlx_ssl_capath": "",
  "mysqlx_ssl_cert": "",
  "mysqlx_ssl_cipher": "",
  "mysqlx_ssl_crl": "",
  "mysqlx_ssl_crlpath": "",
  "mysqlx_ssl_key": "",
  "mysqlx_wait_timeout": "28800",
  "mysqlx_write_timeout": "60",
  "mysqlx_zstd_default_compression_level": "3",
  "mysqlx_zstd_max_client_compression_level": "11",
  "net_buffer_length": "16384",
  "net_buffer_shrink_interval": "0",
  "net_read_timeout": "30",
  "net_retry_count": "10",
  "net_write_timeout": "60",
  "new": "OFF",
  "ngram_token_size": "2",
  "offline_mode": "OFF",
  "old": "OFF",
  "old_alter_table": "OFF",
  "open_files_limit": "10000",
  "optimizer_max_subgraph_pairs": "100000",
  "optimizer_prune_level": "1",
  "optimizer_search_depth": "62",
  "optimizer_switch": "index_merge=on,index_merge_union=on,index_merge_sort_union=on,index_merge_intersection=on,engine_condition_pushdown=on,index_condition_pushdown=on,mrr=on,mrr_cost_based=on,block_nested_loop=on,batched_key_access=off,materialization=on,semijoin=on,loosescan=on,firstmatch=on,duplicateweedout=on,subquery_materialization_cost_based=on,use_index_extensions=on,condition_fanout_filter=on,derived_merge=on,use_invisible_indexes=off,skip_scan=on,hash_join=on,subquery_to_derived=off,prefer_ordering_index=on,hypergraph_optimizer=off,derived_condition_pushdown=on,favor_range_scan=off",
  "optimizer_trace": "enabled=off,one_line=off",
  "optimizer_trace_features": "greedy_search=on,range_optimizer=on,dynamic_range=on,repeated_subselect=on",
  "optimizer_trace_limit": "1",
  "optimizer_trace_max_mem_size": "1048576",
  "optimizer_trace_offset": "-1",
  "parser_max_mem_size": "18446744073709551615",
  "partial_revokes": "OFF",
  "password_history": "0",
  "password_require_current": "OFF",
  "password_reuse_interval": "0",
  "percona_telemetry.grace_interval": "86400",
  "percona_telemetry.history_keep_interval": "604800",
  "percona_telemetry.scrape_interval": "86400",
  "percona_telemetry.telemetry_root_dir": "/usr/local/percona/telemetry/ps",
  "percona_telemetry_disable": "OFF",
  "performance_schema": "ON",
  "performance_schema_accounts_size": "-1",
  "performance_schema_digests_size": "10000",
  "performance_schema_error_size": "5413",
  "performance_schema_events_stages_history_long_size": "10000",
  "performance_schema_events_stages_history_size": "10",
  "performance_schema_events_statements_history_long_size": "10000",
  "performance_schema_events_statements_history_size": "10",
  "performance_schema_events_transactions_history_long_size": "10000",
  "performance_schema_events_transactions_history_size": "10",
  "performance_schema_events_waits_history_long_size": "10000",
  "performance_schema_events_waits_history_size": "10",
  "performance_schema_hosts_size": "-1",
  "performance_schema_max_cond_classes": "150",
  "performance_schema_max_cond_instances": "-1",
  "performance_schema_max_digest_length": "1024",
  "performance_schema_max_digest_sample_age": "60",
  "performance_schema_max_file_classes": "80",
  "performance_schema_max_file_handles": "32768",
  "performance_schema_max_file_instances": "-1",
  "performance_schema_max_index_stat": "-1",
  "performance_schema_max_memory_classes": "530",
  "performance_schema_max_metadata_locks": "-1",
  "performance_schema_max_mutex_classes": "350",
  "performance_schema_max_mutex_instances": "-1",
  "performance_schema_max_prepared_statements_instances": "-1",
  "performance_schema_max_program_instances": "-1",
  "performance_schema_max_rwlock_classes": "70",
  "performance_schema_max_rwlock_instances": "-1",
  "performance_schema_max_socket_classes": "10",
  "performance_schema_max_socket_instances": "-1",
  "performance_schema_max_sql_text_length": "1024",
  "performance_schema_max_stage_classes": "175",
  "performance_schema_max_statement_classes": "227",
  "performance_schema_max_statement_stack": "10",
  "performance_schema_max_table_handles": "-1",
  "performance_schema_max_table_instances": "-1",
  "performance_schema_max_table_lock_stat": "-1",
  "performance_schema_max_thread_classes": "100",
  "performance_schema_max_thread_instances": "-1",
  "performance_schema_session_connect_attrs_size": "512",
  "performance_schema_setup_actors_size": "-1",
  "performance_schema_setup_objects_size": "-1",
  "performance_schema_show_processlist": "OFF",
  "performance_schema_users_size": "-1",
  "persist_only_admin_x509_subject": "",
  "persist_sensitive_variables_in_plaintext": "ON",
  "persisted_globals_load": "ON",
  "pid_file": "/var/run/mysqld/mysqld.pid",
  "plugin_dir": "/usr/lib/mysql/plugin/",
  "port": "3306",
  "preload_buffer_size": "32768",
  "print_identified_with_as_hex": "OFF",
  "profiling": "OFF",
  "profiling_history_size": "15",
  "protocol_compression_algorithms": "zlib,zstd,uncompressed",
  "protocol_version": "10",
  "proxy_protocol_networks": "",
  "query_alloc_block_size": "8192",
  "query_prealloc_size": "8192",
  "range_alloc_block_size": "4096",
  "range_optimizer_max_mem_size": "8388608",
  "rbr_exec_mode": "STRICT",
  "read_buffer_size": "131072",
  "read_only": "OFF",
  "read_rnd_buffer_size": "262144",
  "regexp_stack_limit": "8000000",
  "regexp_time_limit": "32",
  "relay_log": "ubuntu-relay-bin",
  "relay_log_basename": "/var/lib/mysql/ubuntu-relay-bin",
  "relay_log_index": "/var/lib/mysql/ubuntu-relay-bin.index",
  "relay_log_info_file": "relay-log.info",
  "relay_log_info_repository": "TABLE",
  "relay_log_purge": "ON",
  "relay_log_recovery": "OFF",
  "relay_log_space_limit": "0",
  "replica_allow_batching": "ON",
  "replica_checkpoint_group": "512",
  "replica_checkpoint_period": "300",
  "replica_compressed_protocol": "OFF",
  "replica_enable_event": "",
  "replica_exec_mode": "STRICT",
  "replica_load_tmpdir": "/tmp",
  "replica_max_allowed_packet": "1073741824",
  "replica_net_timeout": "60",
  "replica_parallel_type": "LOGICAL_CLOCK",
  "replica_parallel_workers": "4",
  "replica_pending_jobs_size_max": "134217728",
  "replica_preserve_commit_order": "ON",
  "replica_skip_errors": "OFF",
  "replica_sql_verify_checksum": "ON",
  "replica_transaction_retries": "10",
  "replica_type_conversions": "",
  "replication_optimize_for_static_plugin_config": "OFF",
  "replication_sender_observe_commit_only": "OFF",
  "report_host": "",
  "report_password": "",
  "report_port": "3306",
  "report_user": "",
  "require_secure_transport": "OFF",
  "rpl_read_size": "8192",
  "rpl_stop_replica_timeout": "31536000",
  "rpl_stop_slave_timeout": "31536000",
  "schema_definition_cache": "256",
  "secondary_engine_cost_threshold": "100000.000000",
  "secure_file_priv": "/var/lib/mysql-files/",
  "secure_log_path": "",
  "select_into_buffer_size": "131072",
  "select_into_disk_sync": "OFF",
  "select_into_disk_sync_delay": "0",
  "server_id": "1",
  "server_id_bits": "32",
  "server_uuid": "9eec543e-e8fd-11ef-8ef4-080027a02f6e",
  "session_track_gtids": "OFF",
  "session_track_schema": "ON",
  "session_track_state_change": "OFF",
  "session_track_system_variables": "time_zone,autocommit,character_set_client,character_set_results,character_set_connection",
  "session_track_transaction_info": "OFF",
  "sha256_password_auto_generate_rsa_keys": "ON",
  "sha256_password_private_key_path": "private_key.pem",
  "sha256_password_proxy_users": "OFF",
  "sha256_password_public_key_path": "public_key.pem",
  "show_create_table_verbosity": "OFF",
  "show_gipk_in_create_table_and_information_schema": "ON",
  "show_old_temporals": "OFF",
  "skip_external_locking": "ON",
  "skip_name_resolve": "OFF",
  "skip_networking": "OFF",
  "skip_replica_start": "OFF",
  "skip_show_database": "OFF",
  "skip_slave_start": "OFF",
  "slave_allow_batching": "ON",
  "slave_checkpoint_group": "512",
  "slave_checkpoint_period": "300",
  "slave_compressed_protocol": "OFF",
  "slave_exec_mode": "STRICT",
  "slave_load_tmpdir": "/tmp",
  "slave_max_allowed_packet": "1073741824",
  "slave_net_timeout": "60",
  "slave_parallel_type": "LOGICAL_CLOCK",
  "slave_parallel_workers": "4",
  "slave_pending_jobs_size_max": "134217728",
  "slave_preserve_commit_order": "ON",
  "slave_rows_search_algorithms": "INDEX_SCAN,HASH_SCAN",
  "slave_skip_errors": "OFF",
  "slave_sql_verify_checksum": "ON",
  "slave_transaction_retries": "10",
  "slave_type_conversions": "",
  "slow_launch_time": "2",
  "slow_query_log": "OFF",
  "slow_query_log_always_write_time": "10.000000",
  "slow_query_log_file": "/var/lib/mysql/ubuntu-slow.log",
  "slow_query_log_use_global_control": "",
  "socket": "/var/run/mysqld/mysqld.sock",
  "sort_buffer_size": "262144",
  "source_verify_checksum": "OFF",
  "sql_auto_is_null": "OFF",
  "sql_big_selects": "ON",
  "sql_buffer_result": "OFF",
  "sql_generate_invisible_primary_key": "OFF",
  "sql_log_off": "OFF",
  "sql_mode": "ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION",
  "sql_notes": "ON",
  "sql_quote_show_create": "ON",
  "sql_replica_skip_counter": "0",
  "sql_require_primary_key": "OFF",
  "sql_safe_updates": "OFF",
  "sql_select_limit": "18446744073709551615",
  "sql_slave_skip_counter": "0",
  "sql_warnings": "OFF",
  "ssl_ca": "ca.pem",
  "ssl_capath": "",
  "ssl_cert": "server-cert.pem",
  "ssl_cipher": "",
  "ssl_crl": "",
  "ssl_crlpath": "",
  "ssl_fips_mode": "OFF",
  "ssl_key": "server-key.pem",
  "ssl_session_cache_mode": "ON",
  "ssl_session_cache_timeout": "300",
  "stored_program_cache": "256",
  "stored_program_definition_cache": "256",
  "super_read_only": "OFF",
  "sync_binlog": "1",
  "sync_master_info": "10000",
  "sync_relay_log": "10000",
  "sync_relay_log_info": "10000",
  "sync_source_info": "10000",
  "system_time_zone": "UTC",
  "table_definition_cache": "2000",
  "table_encryption_privilege_check": "OFF",
  "table_open_cache": "4000",
  "table_open_cache_instances": "16",
  "table_open_cache_triggers": "524288",
  "tablespace_definition_cache": "256",
  "temptable_max_mmap": "1073741824",
  "temptable_max_ram": "1073741824",
  "temptable_use_mmap": "ON",
  "terminology_use_previous": "NONE",
  "tf_sequence_table_max_upper_bound": "1048576",
  "thread_cache_size": "9",
  "thread_handling": "one-thread-per-connection",
  "thread_pool_high_prio_mode": "transactions",
  "thread_pool_high_prio_tickets": "4294967295",
  "thread_pool_idle_timeout": "60",
  "thread_pool_max_threads": "100000",
  "thread_pool_oversubscribe": "3",
  "thread_pool_size": "2",
  "thread_pool_stall_limit": "500",
  "thread_stack": "1048576",
  "thread_statistics": "OFF",
  "time_zone": "SYSTEM",
  "tls_ciphersuites": "",
  "tls_version": "TLSv1.2,TLSv1.3",
  "tmp_table_size": "16777216",
  "tmpdir": "/tmp",
  "transaction_alloc_block_size": "8192",
  "transaction_isolation": "REPEATABLE-READ",
  "transaction_prealloc_size": "4096",
  "transaction_read_only": "OFF",
  "transaction_write_set_extraction": "XXHASH64",
  "unique_checks": "ON",
  "updatable_views_with_limit": "YES",
  "userstat": "OFF",
  "version": "8.0.40-31",
  "version_comment": "Percona Server (GPL), Release '31', Revision '49317865'",
  "version_compile_machine": "x86_64",
  "version_compile_os": "Linux",
  "version_compile_zlib": "1.3.1",
  "version_suffix": "",
  "wait_timeout": "28800",
  "windowing_use_high_precision": "ON",
  "xa_detach_on_prepare": "ON"
}
sre@ubuntu:~/java_projects/simple_app/myapp$ 

