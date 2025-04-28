
sre@ubuntu:~/java_projects/simple_app$ docker image ls
REPOSITORY     TAG       IMAGE ID       CREATED       SIZE
myapp-webapp   latest    b679034e98f1   3 hours ago   495MB
sre@ubuntu:~/java_projects/simple_app$ docker build -t myapp-webapp .
[+] Building 2.0s (7/7) FINISHED                                                                                                  docker:default
 => [internal] load build definition from Dockerfile                                                                                        0.0s
 => => transferring dockerfile: 158B                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/openjdk:21-jdk-slim                                                                      0.8s
 => [internal] load .dockerignore                                                                                                           0.0s
 => => transferring context: 2B                                                                                                             0.0s
 => [internal] load build context                                                                                                           0.5s
 => => transferring context: 56.42MB                                                                                                        0.5s
 => CACHED [1/2] FROM docker.io/library/openjdk:21-jdk-slim@sha256:7072053847a8a05d7f3a14ebc778a90b38c50ce7e8f199382128a53385160688         0.0s
 => [2/2] COPY target/*.jar webapp.jar                                                                                                      0.2s
 => exporting to image                                                                                                                      0.3s
 => => exporting layers                                                                                                                     0.3s
 => => writing image sha256:840312f082de0cc0cf5870be01824ce5ce8d995fac6b5b55b38d125519279179                                                0.0s
 => => naming to docker.io/library/myapp-webapp                                                                                             0.0s

