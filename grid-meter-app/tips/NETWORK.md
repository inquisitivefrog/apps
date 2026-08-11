
docker network inspect -v grid-meter-app_grid-meter
docker exec -it grid-meter-app-toolbox-1 sh
getent hosts prometheus
getent hosts postgres
getent hosts kafka
getent hosts tempo
curl http://tempo:4318/v1/traces

docker compose ps --format "table {{.Service}}\t{{.Names}}"

docker compose up -d --remove-orphans alloy loki

