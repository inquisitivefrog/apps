# won't start with a normal `docker compose up` — opt-in only
docker compose --profile debug up -d toolbox

# then exec in and hit anything by service name
docker exec -it grid-meter-app-toolbox-1 sh
curl http://api:8080/actuator/health
curl http://api:8080/actuator/prometheus
dig kafka
nc -zv postgres 5432

# tear down when done
docker compose --profile debug down toolbox

docker compose --profile debug up -d toolbox

ALSO
docker ai "help me fix this compose error"
