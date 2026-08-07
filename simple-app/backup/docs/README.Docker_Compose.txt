
sre@ubuntu:~/simple_app/myapp$ which docker-compose
/snap/bin/docker-compose
sre@ubuntu:~/simple_app/myapp$ docker-compose version
Docker Compose version v2.20.3

sre@ubuntu:~/simple_app/myapp$ cat docker-compose.yml 
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - webapp

  webapp:
    build: .
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://db:3306/mydb?useSSL=false&allowPublicKeyRetrieval=true
      - SPRING_DATASOURCE_USERNAME=dbuser
      - SPRING_DATASOURCE_PASSWORD=G1ng3rb33r
    depends_on:
      - db

  db:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: mydb
    volumes:
      - dbdata:/var/lib/mysql

  jmeter:
    image: justb4/jmeter
    volumes:
      - ./jmeter:/test
    command: -n -t ./test/JMeterTest.jmx -l ./test/results.jtl

volumes:
  dbdata:


