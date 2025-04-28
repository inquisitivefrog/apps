
sre@ubuntu:~/java_projects/simple_app/myapp$ which java
/usr/bin/java
sre@ubuntu:~/java_projects/simple_app/myapp$ java -version
openjdk version "21.0.6" 2025-01-21
OpenJDK Runtime Environment (build 21.0.6+7-Ubuntu-124.04.1)
OpenJDK 64-Bit Server VM (build 21.0.6+7-Ubuntu-124.04.1, mixed mode, sharing)
sre@ubuntu:~/java_projects/simple_app/myapp$ echo $JAVA_HOME
/usr/lib/jvm/java-21-openjdk-amd64
sre@ubuntu:~/java_projects/simple_app/myapp$ which mvn
/usr/bin/mvn
sre@ubuntu:~/java_projects/simple_app/myapp$ mvn -version
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 21.0.6, vendor: Ubuntu, runtime: /usr/lib/jvm/java-21-openjdk-amd64
Default locale: en_US, platform encoding: UTF-8
OS name: "linux", version: "6.8.0-53-generic", arch: "amd64", family: "unix"
sre@ubuntu:~/java_projects/simple_app/myapp$

sre@ubuntu:~/java_projects/simple_app/myapp$ mvn compile
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.simple.apps:myapp >------------------------
[INFO] Building myapp 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.3.1:resources (default-resources) @ myapp ---
[INFO] Copying 1 resource from src/main/resources to target/classes
[INFO] Copying 0 resource from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:compile (default-compile) @ myapp ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [forked debug parameters release 21] to target/classes
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.348 s
[INFO] Finished at: 2025-02-12T18:44:16Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/simple_app/myapp$ ls -l target/
total 12
drwxrwxr-x 3 sre sre 4096 Feb 12 18:44 classes
drwxrwxr-x 3 sre sre 4096 Feb 12 18:44 generated-sources
drwxrwxr-x 3 sre sre 4096 Feb 12 18:44 maven-status
sre@ubuntu:~/java_projects/simple_app/myapp$ 

sre@ubuntu:~/java_projects/simple_app$ mvn compile
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.simple.apps:myapp >------------------------
[INFO] Building myapp 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.3.1:resources (default-resources) @ myapp ---
[INFO] Copying 1 resource from src/main/resources to target/classes
[INFO] Copying 0 resource from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:compile (default-compile) @ myapp ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.434 s
[INFO] Finished at: 2025-02-12T23:04:25Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/simple_app$ 

