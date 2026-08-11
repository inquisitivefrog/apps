docker compose up -d --build api         
docker compose build api --no-cache
docker compose up -d --force-recreate api
docker logs -f grid-meter-app-api-1
docker exec grid-meter-app-api-1 sh -c \
  'unzip -p /app/app.jar BOOT-INF/classes/application.yml'


docker compose run --rm \
  -e JAVA_TOOL_OPTIONS="-Xmx384m -Dmanagement.otlp.metrics.export.enabled=false" \
  api

docker exec grid-meter-app-api-1 sh -c \
'java -jar /app/app.jar --debug 2>&1 | grep -i -A12 -B12 "OtlpMetricsExport"'

docker exec grid-meter-app-api-1 sh -c \
'java -jar /app/app.jar --debug 2>&1 | grep -i -A8 -B8 "otlp"'

grep -nEi 'opentelemetry|micrometer.*otlp|prometheus' api/pom.xml


