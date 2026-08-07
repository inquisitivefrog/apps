
tim@Tims-MBP myapp % vi nginx.conf

tim@Tims-MBP myapp % cat nginx.conf 
events {
    worker_connections  1024;
}
http {
    server {
        listen 80;
        server_name localhost;
        location / {
            proxy_pass http://webapp:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}

