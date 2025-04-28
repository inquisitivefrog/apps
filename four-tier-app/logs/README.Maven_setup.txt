
sre@ubuntu:~/java_projects/book-order-app$ which java
/usr/bin/java
sre@ubuntu:~/java_projects/book-order-app$ java -version
openjdk version "21.0.6" 2025-01-21
OpenJDK Runtime Environment (build 21.0.6+7-Ubuntu-124.04.1)
OpenJDK 64-Bit Server VM (build 21.0.6+7-Ubuntu-124.04.1, mixed mode, sharing)
sre@ubuntu:~/java_projects/book-order-app$ which javac
/usr/bin/javac
sre@ubuntu:~/java_projects/book-order-app$ javac -version
javac 21.0.6
sre@ubuntu:~/java_projects/book-order-app$ which mvn
/usr/bin/mvn
sre@ubuntu:~/java_projects/book-order-app$ mvn -version
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 21.0.6, vendor: Ubuntu, runtime: /usr/lib/jvm/java-21-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.8.0-53-generic", arch: "amd64", family: "unix"

sre@ubuntu:~$ cd java_projects/
sre@ubuntu:~/java_projects$ ls
simple_app
sre@ubuntu:~/java_projects$ mvn archetype:generate -DgroupId=com.example -DartifactId=book-order-app -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
[INFO] Scanning for projects...
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/2.5/maven-clean-plugin-2.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/2.5/maven-clean-plugin-2.5.pom (3.9 kB at 6.6 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/22/maven-plugins-22.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/22/maven-plugins-22.pom (13 kB at 303 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/21/maven-parent-21.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/21/maven-parent-21.pom (26 kB at 753 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/apache/10/apache-10.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/apache/10/apache-10.pom (15 kB at 493 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/2.5/maven-clean-plugin-2.5.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/2.5/maven-clean-plugin-2.5.jar (25 kB at 724 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-install-plugin/2.4/maven-install-plugin-2.4.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-install-plugin/2.4/maven-install-plugin-2.4.pom (6.4 kB at 266 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/23/maven-plugins-23.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/23/maven-plugins-23.pom (9.2 kB at 368 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/22/maven-parent-22.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/22/maven-parent-22.pom (30 kB at 826 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/apache/11/apache-11.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/apache/11/apache-11.pom (15 kB at 511 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-install-plugin/2.4/maven-install-plugin-2.4.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-install-plugin/2.4/maven-install-plugin-2.4.jar (27 kB at 749 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-deploy-plugin/2.7/maven-deploy-plugin-2.7.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-deploy-plugin/2.7/maven-deploy-plugin-2.7.pom (5.6 kB at 175 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-deploy-plugin/2.7/maven-deploy-plugin-2.7.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-deploy-plugin/2.7/maven-deploy-plugin-2.7.jar (27 kB at 813 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-antrun-plugin/1.3/maven-antrun-plugin-1.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-antrun-plugin/1.3/maven-antrun-plugin-1.3.pom (4.7 kB at 206 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/12/maven-plugins-12.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/12/maven-plugins-12.pom (12 kB at 511 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/9/maven-parent-9.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/9/maven-parent-9.pom (33 kB at 1.3 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-antrun-plugin/1.3/maven-antrun-plugin-1.3.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-antrun-plugin/1.3/maven-antrun-plugin-1.3.jar (24 kB at 813 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-assembly-plugin/2.2-beta-5/maven-assembly-plugin-2.2-beta-5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-assembly-plugin/2.2-beta-5/maven-assembly-plugin-2.2-beta-5.pom (15 kB at 632 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/16/maven-plugins-16.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-plugins/16/maven-plugins-16.pom (13 kB at 540 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-assembly-plugin/2.2-beta-5/maven-assembly-plugin-2.2-beta-5.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-assembly-plugin/2.2-beta-5/maven-assembly-plugin-2.2-beta-5.jar (209 kB at 3.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-dependency-plugin/2.8/maven-dependency-plugin-2.8.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-dependency-plugin/2.8/maven-dependency-plugin-2.8.pom (11 kB at 545 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-dependency-plugin/2.8/maven-dependency-plugin-2.8.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-dependency-plugin/2.8/maven-dependency-plugin-2.8.jar (153 kB at 2.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-release-plugin/2.5.3/maven-release-plugin-2.5.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-release-plugin/2.5.3/maven-release-plugin-2.5.3.pom (11 kB at 382 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/release/maven-release/2.5.3/maven-release-2.5.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/release/maven-release/2.5.3/maven-release-2.5.3.pom (5.0 kB at 239 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/27/maven-parent-27.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/maven-parent/27/maven-parent-27.pom (41 kB at 1.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/apache/17/apache-17.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/apache/17/apache-17.pom (16 kB at 698 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-release-plugin/2.5.3/maven-release-plugin-2.5.3.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-release-plugin/2.5.3/maven-release-plugin-2.5.3.jar (53 kB at 1.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-metadata.xml
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/maven-metadata.xml
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-metadata.xml (14 kB at 649 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/maven-metadata.xml (21 kB at 448 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-archetype-plugin/maven-metadata.xml
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-archetype-plugin/maven-metadata.xml (1.0 kB at 33 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-archetype-plugin/3.3.1/maven-archetype-plugin-3.3.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-archetype-plugin/3.3.1/maven-archetype-plugin-3.3.1.pom (10 kB at 428 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/maven-archetype/3.3.1/maven-archetype-3.3.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/maven-archetype/3.3.1/maven-archetype-3.3.1.pom (10 kB at 515 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-bom/4.0.23/groovy-bom-4.0.23.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-bom/4.0.23/groovy-bom-4.0.23.pom (27 kB at 941 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-archetype-plugin/3.3.1/maven-archetype-plugin-3.3.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-archetype-plugin/3.3.1/maven-archetype-plugin-3.3.1.jar (99 kB at 1.8 MB/s)
[INFO] 
[INFO] ------------------< org.apache.maven:standalone-pom >-------------------
[INFO] Building Maven Stub Project (No POM) 1
[INFO] --------------------------------[ pom ]---------------------------------
[INFO] 
[INFO] >>> maven-archetype-plugin:3.3.1:generate (default-cli) > generate-sources @ standalone-pom >>>
[INFO] 
[INFO] <<< maven-archetype-plugin:3.3.1:generate (default-cli) < generate-sources @ standalone-pom <<<
[INFO] 
[INFO] 
[INFO] --- maven-archetype-plugin:3.3.1:generate (default-cli) @ standalone-pom ---
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-catalog/3.3.1/archetype-catalog-3.3.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-catalog/3.3.1/archetype-catalog-3.3.1.pom (1.7 kB at 79 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-models/3.3.1/archetype-models-3.3.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-models/3.3.1/archetype-models-3.3.1.pom (3.0 kB at 136 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-descriptor/3.3.1/archetype-descriptor-3.3.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-descriptor/3.3.1/archetype-descriptor-3.3.1.pom (1.8 kB at 69 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-common/3.3.1/archetype-common-3.3.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-common/3.3.1/archetype-common-3.3.1.pom (18 kB at 700 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy/4.0.23/groovy-4.0.23.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy/4.0.23/groovy-4.0.23.pom (24 kB at 652 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-json/4.0.23/groovy-json-4.0.23.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-json/4.0.23/groovy-json-4.0.23.pom (23 kB at 627 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-templates/4.0.23/groovy-templates-4.0.23.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-templates/4.0.23/groovy-templates-4.0.23.pom (23 kB at 948 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-xml/4.0.23/groovy-xml-4.0.23.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-xml/4.0.23/groovy-xml-4.0.23.pom (23 kB at 836 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-yaml/4.0.23/groovy-yaml-4.0.23.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-yaml/4.0.23/groovy-yaml-4.0.23.pom (23 kB at 1.1 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/dataformat/jackson-dataformat-yaml/2.17.2/jackson-dataformat-yaml-2.17.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/dataformat/jackson-dataformat-yaml/2.17.2/jackson-dataformat-yaml-2.17.2.pom (2.6 kB at 114 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/dataformat/jackson-dataformats-text/2.17.2/jackson-dataformats-text-2.17.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/dataformat/jackson-dataformats-text/2.17.2/jackson-dataformats-text-2.17.2.pom (3.5 kB at 158 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/jackson-base/2.17.2/jackson-base-2.17.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/jackson-base/2.17.2/jackson-base-2.17.2.pom (12 kB at 471 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.17.2/jackson-databind-2.17.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.17.2/jackson-databind-2.17.2.pom (21 kB at 966 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.17.2/jackson-annotations-2.17.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.17.2/jackson-annotations-2.17.2.pom (7.1 kB at 372 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-core/2.17.2/jackson-core-2.17.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-core/2.17.2/jackson-core-2.17.2.pom (9.6 kB at 482 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/2.2/snakeyaml-2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/2.2/snakeyaml-2.2.pom (21 kB at 966 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/ivy/ivy/2.5.2/ivy-2.5.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/ivy/ivy/2.5.2/ivy-2.5.2.pom (6.8 kB at 338 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-invoker/3.3.0/maven-invoker-3.3.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-invoker/3.3.0/maven-invoker-3.3.0.pom (4.2 kB at 185 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/velocity/velocity-engine-core/2.4.1/velocity-engine-core-2.4.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/velocity/velocity-engine-core/2.4.1/velocity-engine-core-2.4.1.pom (12 kB at 521 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/velocity/velocity-engine-parent/2.4.1/velocity-engine-parent-2.4.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/velocity/velocity-engine-parent/2.4.1/velocity-engine-parent-2.4.1.pom (9.5 kB at 432 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/ibm/icu/icu4j/75.1/icu4j-75.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/ibm/icu/icu4j/75.1/icu4j-75.1.pom (13 kB at 657 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/ibm/icu/icu4j-root/75.1/icu4j-root-75.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/ibm/icu/icu4j-root/75.1/icu4j-root-75.1.pom (27 kB at 1.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-interactivity-api/1.3/plexus-interactivity-api-1.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-interactivity-api/1.3/plexus-interactivity-api-1.3.pom (1.7 kB at 99 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-interactivity/1.3/plexus-interactivity-1.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-interactivity/1.3/plexus-interactivity-1.3.pom (1.9 kB at 85 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugin-tools/maven-plugin-annotations/3.13.1/maven-plugin-annotations-3.13.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugin-tools/maven-plugin-annotations/3.13.1/maven-plugin-annotations-3.13.1.pom (1.5 kB at 59 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugin-tools/maven-plugin-tools/3.13.1/maven-plugin-tools-3.13.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugin-tools/maven-plugin-tools/3.13.1/maven-plugin-tools-3.13.1.pom (18 kB at 274 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-script-interpreter/1.5/maven-script-interpreter-1.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-script-interpreter/1.5/maven-script-interpreter-1.5.pom (4.6 kB at 211 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache-extras/beanshell/bsh/2.0b6/bsh-2.0b6.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache-extras/beanshell/bsh/2.0b6/bsh-2.0b6.pom (5.0 kB at 293 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-catalog/3.3.1/archetype-catalog-3.3.1.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-descriptor/3.3.1/archetype-descriptor-3.3.1.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-common/3.3.1/archetype-common-3.3.1.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy/4.0.23/groovy-4.0.23.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-json/4.0.23/groovy-json-4.0.23.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-descriptor/3.3.1/archetype-descriptor-3.3.1.jar (24 kB at 397 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-templates/4.0.23/groovy-templates-4.0.23.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-catalog/3.3.1/archetype-catalog-3.3.1.jar (19 kB at 223 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-xml/4.0.23/groovy-xml-4.0.23.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetype/archetype-common/3.3.1/archetype-common-3.3.1.jar (175 kB at 947 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-yaml/4.0.23/groovy-yaml-4.0.23.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-templates/4.0.23/groovy-templates-4.0.23.jar (92 kB at 391 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/dataformat/jackson-dataformat-yaml/2.17.2/jackson-dataformat-yaml-2.17.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-yaml/4.0.23/groovy-yaml-4.0.23.jar (6.2 kB at 26 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/2.2/snakeyaml-2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/dataformat/jackson-dataformat-yaml/2.17.2/jackson-dataformat-yaml-2.17.2.jar (55 kB at 185 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-core/2.17.2/jackson-core-2.17.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-json/4.0.23/groovy-json-4.0.23.jar (130 kB at 411 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.17.2/jackson-databind-2.17.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy-xml/4.0.23/groovy-xml-4.0.23.jar (213 kB at 548 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.17.2/jackson-annotations-2.17.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/2.2/snakeyaml-2.2.jar (334 kB at 663 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/ivy/ivy/2.5.2/ivy-2.5.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-core/2.17.2/jackson-core-2.17.2.jar (582 kB at 980 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/commons-io/commons-io/2.17.0/commons-io-2.17.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.17.2/jackson-annotations-2.17.2.jar (78 kB at 119 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/ibm/icu/icu4j/75.1/icu4j-75.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/commons-io/commons-io/2.17.0/commons-io-2.17.0.jar (516 kB at 518 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-io/3.5.0/plexus-io-3.5.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-io/3.5.0/plexus-io-3.5.0.jar (79 kB at 69 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-interactivity-api/1.3/plexus-interactivity-api-1.3.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/plexus/plexus-interactivity-api/1.3/plexus-interactivity-api-1.3.jar (10 kB at 8.5 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugin-tools/maven-plugin-annotations/3.13.1/maven-plugin-annotations-3.13.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugin-tools/maven-plugin-annotations/3.13.1/maven-plugin-annotations-3.13.1.jar (14 kB at 11 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-invoker/3.3.0/maven-invoker-3.3.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-invoker/3.3.0/maven-invoker-3.3.0.jar (34 kB at 25 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/velocity/velocity-engine-core/2.4.1/velocity-engine-core-2.4.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.17.2/jackson-databind-2.17.2.jar (1.6 MB at 1.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-script-interpreter/1.5/maven-script-interpreter-1.5.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/shared/maven-script-interpreter/1.5/maven-script-interpreter-1.5.jar (25 kB at 17 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache-extras/beanshell/bsh/2.0b6/bsh-2.0b6.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/ivy/ivy/2.5.2/ivy-2.5.2.jar (1.4 MB at 936 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/velocity/velocity-engine-core/2.4.1/velocity-engine-core-2.4.1.jar (516 kB at 297 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache-extras/beanshell/bsh/2.0b6/bsh-2.0b6.jar (389 kB at 220 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/groovy/groovy/4.0.23/groovy-4.0.23.jar (7.6 MB at 2.0 MB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/com/ibm/icu/icu4j/75.1/icu4j-75.1.jar (14 MB at 2.9 MB/s)
[INFO] Generating project in Batch mode
Downloading from central: https://repo.maven.apache.org/maven2/archetype-catalog.xml
Downloaded from central: https://repo.maven.apache.org/maven2/archetype-catalog.xml (16 MB at 5.3 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetypes/maven-archetype-quickstart/1.0/maven-archetype-quickstart-1.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetypes/maven-archetype-quickstart/1.0/maven-archetype-quickstart-1.0.jar (4.3 kB at 123 kB/s)
[INFO] ----------------------------------------------------------------------------
[INFO] Using following parameters for creating project from Old (1.x) Archetype: maven-archetype-quickstart:1.0
[INFO] ----------------------------------------------------------------------------
[INFO] Parameter: basedir, Value: /home/sre/java_projects/book-order-app
[INFO] Parameter: package, Value: com.example
[INFO] Parameter: groupId, Value: com.example
[INFO] Parameter: artifactId, Value: book-order-app
[INFO] Parameter: packageName, Value: com.example
[INFO] Parameter: version, Value: 1.0-SNAPSHOT
[INFO] project created from Old (1.x) Archetype in dir: /home/sre/java_projects/book-order-app/book-order-app
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  13.181 s
[INFO] Finished at: 2025-02-13T19:22:35Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects$ 

