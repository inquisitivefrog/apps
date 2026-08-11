#!/bin/bash

# 1. API health via Traefik routing
curl -s http://localhost/api/actuator/health

# 2. API's own view of Kafka/Redis/DB connectivity (if actuator health details are exposed)
curl -s http://localhost/api/actuator/health | python3 -m json.tool
curl -s http://localhost/api/v1/meters
curl -s http://localhost/api/v1/readings

# 3. Traefik dashboard is reachable
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/dashboard/

# 4. Prometheus is scraping and up
curl -s http://localhost/prometheus/-/healthy

# 5. Grafana is up
curl -s -o /dev/null -w "%{http_code}\n" http://localhost/grafana/api/health

# 6. Postgres accepting connections
docker exec grid-meter-app-postgres-1 pg_isready -U gridmeter

# 7. Kafka broker responding (list topics)
docker exec grid-meter-app-kafka-1 /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# 8. Redis responding
docker exec grid-meter-app-redis-1 redis-cli ping


docker run --rm --network grid-meter-app_grid-meter curlimages/curl -s http://api:8080/actuator/prometheus | head -20

docker run --rm --network grid-meter-app_grid-meter curlimages/curl -s http://prometheus:9090/api/v1/targets | python3 -m json.tool

# does the endpoint respond with metrics now that it's exposed?
docker run --rm --network grid-meter-app_grid-meter curlimages/curl -s http://api:8080/actuator/prometheus | head -20

# is Prometheus actually scraping it successfully (not just configured to)?
curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool

(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % curl -s -o /dev/null -w "%{http_code}\n" http://localhost/grafana/login
200
(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % curl -s http://localhost/grafana/api/health
{
  "database": "ok",
  "version": "13.0.2",
  "commit": "3fcdbc5a"
}%                           

(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % curl -s http://localhost/api/v1/meters
{"content":[{"id":"885331d1-4797-4997-b5b9-a90ee41d2190","serialNumber":"MTR-0001","location":"123 Main St, Unit 4","status":"ACTIVE","installedAt":"2026-01-15T00:00:00Z","createdAt":"2026-08-08T06:48:56.141352Z","updatedAt":"2026-08-08T06:48:56.141352Z"}],"page":0,"size":20,"totalElements":1,"totalPages":1}%                                                                                                                    (⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % curl curl -s http://localhost/api/v1/readings
{"content":[{"id":"5270d1f8-b662-4d40-ae36-44a144304e32","meterId":"885331d1-4797-4997-b5b9-a90ee41d2190","readingTimestamp":"2026-08-08T06:00:00Z","receivedAt":"2026-08-08T06:49:43.438848Z","value":42.500}],"page":0,"size":20,"totalElements":1,"totalPages":1}%                                                                                                                                                                     (⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % 

(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % docker logs --since 5m grid-meter-app-api-1
(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % 

(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % vi api/src/main/resources/application.yml 
(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % docker compose up -d --build api


(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % curl -s http://localhost/api/v1/meters
{"content":[{"id":"885331d1-4797-4997-b5b9-a90ee41d2190","serialNumber":"MTR-0001","location":"123 Main St, Unit 4","status":"ACTIVE","installedAt":"2026-01-15T00:00:00Z","createdAt":"2026-08-08T06:48:56.141352Z","updatedAt":"2026-08-08T06:48:56.141352Z"}],"page":0,"size":20,"totalElements":1,"totalPages":1}%                                                                                                                    (⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % docker run --rm --network grid-meter-app_grid-meter curlimages/curl -s http://api:8080/actuator/prometheus | head -5
# HELP application_ready_time_seconds Time taken for the application to be ready to service requests
# TYPE application_ready_time_seconds gauge
application_ready_time_seconds{main_application_class="com.gridmeter.api.GridMeterApiApplication"} 3.6
# HELP application_started_time_seconds Time taken to start the application
# TYPE application_started_time_seconds gauge
(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % docker run --rm --network grid-meter-app_grid-meter curlimages/curl -s http://prometheus:9090/api/v1/targets | grep -A3 '"job":"grid-meter-api"'
{"status":"success","data":{"activeTargets":[{"discoveredLabels":{"__address__":"api:8080","__metrics_path__":"/actuator/prometheus","__scheme__":"http","__scrape_interval__":"15s","__scrape_timeout__":"10s","job":"grid-meter-api"},"labels":{"instance":"api:8080","job":"grid-meter-api"},"scrapePool":"grid-meter-api","scrapeUrl":"http://api:8080/actuator/prometheus","globalUrl":"http://api:8080/actuator/prometheus","lastError":"","lastScrape":"2026-08-10T21:20:24.529202794Z","lastScrapeDuration":0.014675125,"health":"up","scrapeInterval":"15s","scrapeTimeout":"10s"}],"droppedTargets":[],"droppedTargetCounts":{"grid-meter-api":0}}}
(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % 

docker logs --since 2m grid-meter-app-api-1 | grep -i "otlp\|ConnectException"

docker run --rm --network grid-meter-app_grid-meter curlimages/curl -s -w "\nHTTP_STATUS:%{http_code}\n" http://api:8080/actuator/prometheus

curl -s http://localhost/api/v1/meters

docker exec grid-meter-app-api-1 \                       
  sh -c 'env | sort | grep -Ei "OTLP|MANAGEMENT|SPRING"'


