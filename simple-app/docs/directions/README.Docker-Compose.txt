
tim@Tims-MBP myapp % vi docker-compose.yml

tim@Tims-MBP myapp % cat docker-compose.yml 
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
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=example
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
    command: -n -t /test/JMeterTest.jmx -l /test/results.jtl

volumes:
  dbdata:
tim@Tims-MBP myapp % 

tim@Tims-MBP simple-app % which docker-compose
/usr/local/bin/docker-compose
tim@Tims-MBP simple-app % docker-compose version
Docker Compose version v2.31.0-desktop.2
