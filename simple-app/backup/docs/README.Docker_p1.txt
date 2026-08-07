sre@ubuntu:~$ which docker
/snap/bin/docker
sre@ubuntu:~$ docker version
Client:
 Version:           27.2.0
 API version:       1.47
 Go version:        go1.21.13
 Git commit:        3ab4256
 Built:             Tue Dec 17 12:23:46 2024
 OS/Arch:           linux/amd64
 Context:           default
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.47/version": dial unix /var/run/docker.sock: connect: permission denied
sre@ubuntu:~$ sudo docker version
[sudo] password for sre: 
Client:
 Version:           27.2.0
 API version:       1.47
 Go version:        go1.21.13
 Git commit:        3ab4256
 Built:             Tue Dec 17 12:23:46 2024
 OS/Arch:           linux/amd64
 Context:           default

Server:
 Engine:
  Version:          27.2.0
  API version:      1.47 (minimum version 1.24)
  Go version:       go1.21.13
  Git commit:       3ab5c7d
  Built:            Tue Dec 17 12:24:21 2024
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v1.7.21
  GitCommit:        472731909fa34bd7bc9c087e4c27943f9835f111
 runc:
  Version:          1.1.13
  GitCommit:        
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0

