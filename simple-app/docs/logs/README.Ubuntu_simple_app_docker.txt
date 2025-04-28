
sre@ubuntu:~/java_projects/simple_app/myapp$ which docker
/usr/bin/docker
sre@ubuntu:~/java_projects/simple_app/myapp$ docker version
Client: Docker Engine - Community
 Version:           27.5.1
 API version:       1.47
 Go version:        go1.22.11
 Git commit:        9f9e405
 Built:             Wed Jan 22 13:41:48 2025
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          27.5.1
  API version:      1.47 (minimum version 1.24)
  Go version:       go1.22.11
  Git commit:       4c9b3b0
  Built:            Wed Jan 22 13:41:48 2025
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.7.25
  GitCommit:        bcc810d6b9066471b0b6fa75f557a15a1cbf31bb
 runc:
  Version:          1.2.4
  GitCommit:        v1.2.4-0-g6c52b3f
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
sre@ubuntu:~/java_projects/simple_app/myapp$ docker info
Client: Docker Engine - Community
 Version:    27.5.1
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.20.0
    Path:     /usr/libexec/docker/cli-plugins/docker-buildx
  compose: Docker Compose (Docker Inc.)
    Version:  v2.32.4
    Path:     /usr/libexec/docker/cli-plugins/docker-compose

Server:
 Containers: 3
  Running: 1
  Paused: 0
  Stopped: 2
 Images: 3
 Server Version: 27.5.1
 Storage Driver: overlay2
  Backing Filesystem: extfs
  Supports d_type: true
  Using metacopy: false
  Native Overlay Diff: true
  userxattr: false
 Logging Driver: json-file
 Cgroup Driver: systemd
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: bcc810d6b9066471b0b6fa75f557a15a1cbf31bb
 runc version: v1.2.4-0-g6c52b3f
 init version: de40ad0
 Security Options:
  apparmor
  seccomp
   Profile: builtin
  cgroupns
 Kernel Version: 6.8.0-53-generic
 Operating System: Ubuntu 24.04.2 LTS
 OSType: linux
 Architecture: x86_64
 CPUs: 2
 Total Memory: 2.903GiB
 Name: ubuntu
 ID: 37fc070f-642c-4bf7-a94c-3a6ca43701ae
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Experimental: false
 Insecure Registries:
  127.0.0.0/8
 Live Restore Enabled: false

sre@ubuntu:~/java_projects/simple_app/myapp$ docker build -t myapp-webapp .
[+] Building 22.4s (7/7) FINISHED                                                                                                                                       docker:default
 => [internal] load build definition from Dockerfile                                                                                                                              0.0s
 => => transferring dockerfile: 236B                                                                                                                                              0.0s
 => [internal] load metadata for docker.io/library/openjdk:7u221-jre-slim                                                                                                         1.5s
 => [internal] load .dockerignore                                                                                                                                                 0.0s
 => => transferring context: 2B                                                                                                                                                   0.0s
 => [internal] load build context                                                                                                                                                 1.4s
 => => transferring context: 56.42MB                                                                                                                                              1.4s
 => [1/2] FROM docker.io/library/openjdk:7u221-jre-slim@sha256:38c7b79abce73883d7a193fdc2607a1f36f710bb22440d5f080c2ed4ccba8bbc                                                  20.1s
 => => resolve docker.io/library/openjdk:7u221-jre-slim@sha256:38c7b79abce73883d7a193fdc2607a1f36f710bb22440d5f080c2ed4ccba8bbc                                                   0.0s
 => => sha256:38c7b79abce73883d7a193fdc2607a1f36f710bb22440d5f080c2ed4ccba8bbc 986B / 986B                                                                                        0.0s
 => => sha256:f6db6a5b7899df0dec9649724f674aa5227bb8188538b2de597294477d996f87 1.36kB / 1.36kB                                                                                    0.0s
 => => sha256:aeba7c9f8f84657cc21f04c41840402bae19fda5462d280a6f7d8afdd48e476a 4.38kB / 4.38kB                                                                                    0.0s
 => => sha256:80e253c906dee8d7b26d7dafa4166149c57cb763d43ba6d483710370c32da5cd 30.15MB / 30.15MB                                                                                 11.7s
 => => sha256:359b1e5bffc36ffeb13a6993169cc333fa6661a6c4eed575d232ce4946cde837 463.82kB / 463.82kB                                                                                0.2s
 => => sha256:3f816a1ef6133e8f97fa4b0edb9b7e83432b998f2d5018b90bb97231273f6821 247B / 247B                                                                                        0.4s
 => => sha256:91e0fb57abef91b68244295d0ba40eff5bd83f23133d267124b13df7c99f3fd0 130B / 130B                                                                                        1.3s
 => => sha256:a0c9810766c76d2372648e43bc8567846fc031357586fd505fc7c88abf18628a 61.72MB / 61.72MB                                                                                 17.9s
 => => extracting sha256:80e253c906dee8d7b26d7dafa4166149c57cb763d43ba6d483710370c32da5cd                                                                                         3.7s
 => => extracting sha256:359b1e5bffc36ffeb13a6993169cc333fa6661a6c4eed575d232ce4946cde837                                                                                         0.1s
 => => extracting sha256:3f816a1ef6133e8f97fa4b0edb9b7e83432b998f2d5018b90bb97231273f6821                                                                                         0.0s
 => => extracting sha256:91e0fb57abef91b68244295d0ba40eff5bd83f23133d267124b13df7c99f3fd0                                                                                         0.0s
 => => extracting sha256:a0c9810766c76d2372648e43bc8567846fc031357586fd505fc7c88abf18628a                                                                                         1.9s
 => [2/2] COPY target/*.jar webapp.jar                                                                                                                                            0.3s
 => exporting to image                                                                                                                                                            0.3s
 => => exporting layers                                                                                                                                                           0.3s
 => => writing image sha256:4473dce477afa6e7adca5fdcf272db0c913825742da1e97b40b52512b752e710                                                                                      0.0s
 => => naming to docker.io/library/myapp-webapp                                                                                                                                   0.0s
sre@ubuntu:~/java_projects/simple_app/myapp$ docker images
REPOSITORY     TAG       IMAGE ID       CREATED              SIZE
myapp-webapp   latest    4473dce477af   About a minute ago   253MB
hello-world    latest    74cc54e27dc4   3 weeks ago          10.1kB
mysql          5.7       5107333e08a8   14 months ago        501MB


