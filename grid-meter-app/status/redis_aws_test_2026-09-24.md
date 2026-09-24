
# Terminal 1

kubectl logs -f api-6f8dc8dd6f-4p6zw

2026-09-24T16:04:59.862Z  INFO [customerId=] 1 --- [grid-meter-api] [           main] [                                                 ] .RepositoryConfigurationExtensionSupport : Spring Data Redis - Could not safely identify store assignment for repository candidate interface com.gridmeter.api.reading.ReadingRepository; If you want this repository to be a Redis repository, consider annotating your entities with one of these annotations: org.springframework.data.redis.core.RedisHash (preferred), or consider extending one of the following types with your repository: org.springframework.data.keyvalue.repository.KeyValueRepository
2026-09-24T16:04:59.863Z  INFO [customerId=] 1 --- [grid-meter-api] [           main] [                                                 ] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 21 ms. Found 0 Redis repository interfaces.
tim@Timothys-MacBook-Air aws % 

# Terminal 2

tim@Timothys-MacBook-Air grid-meter-app % TOKEN=$(curl -s -X POST http://abf338bd29c15490b88057ab50b39e42-951615524.us-west-2.elb.amazonaws.com/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"demo","password":"GridMeter!Demo2026"}' | python3 -c 'import json,sys;print(json.load(sys.stdin)["accessToken"])')
tim@Timothys-MacBook-Air grid-meter-app % curl -s -X POST http://abf338bd29c15490b88057ab50b39e42-951615524.us-west-2.elb.amazonaws.com/api/v1/readings \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"meterId":"94144723-09c1-464b-b105-e009a415f508","readingTimestamp":"2026-09-24T17:00:00Z","value":444.44}'
{"id":"2bb7acdb-4beb-4eef-a207-e435a5dcd8b4","meterId":"94144723-09c1-464b-b105-e009a415f508","readingTimestamp":"2026-09-24T17:00:00Z","receivedAt":"2026-09-24T16:34:22.569222272Z","value":444.44}%                                          tim@Timothys-MacBook-Air grid-meter-app % curl -s -X POST http://abf338bd29c15490b88057ab50b39e42-951615524.us-west-2.elb.amazonaws.com/api/v1/readings \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"meterId":"94144723-09c1-464b-b105-e009a415f508","readingTimestamp":"2026-09-24T17:00:00Z","value":444.44}'
{"id":"93c1d107-b8ff-4bb4-9f2c-b9c377807758","meterId":"94144723-09c1-464b-b105-e009a415f508","readingTimestamp":"2026-09-24T17:00:00Z","receivedAt":"2026-09-24T16:34:32.579440864Z","value":444.44}%     
tim@Timothys-MacBook-Air aws % 

# Terminal 3

tim@Timothys-MacBook-Air aws % kubectl logs -f api-6f8dc8dd6f-77d9d

2026-09-24T16:05:34.302Z  INFO [customerId=] 1 --- [grid-meter-api] [           main] [                                                 ] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 16 ms. Found 0 Redis repository interfaces.
2026-09-24T16:06:14.047Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt starting for meter 94144723-09c1-464b-b105-e009a415f508
2026-09-24T16:06:14.064Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt SUCCEEDED for meter 94144723-09c1-464b-b105-e009a415f508
2026-09-24T16:06:38.423Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt starting for meter 94144723-09c1-464b-b105-e009a415f508
2026-09-24T16:06:38.427Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt SUCCEEDED for meter 94144723-09c1-464b-b105-e009a415f508
2026-09-24T16:34:22.733Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt starting for meter 94144723-09c1-464b-b105-e009a415f508
2026-09-24T16:34:22.736Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt SUCCEEDED for meter 94144723-09c1-464b-b105-e009a415f508
2026-09-24T16:34:32.603Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt starting for meter 94144723-09c1-464b-b105-e009a415f508
2026-09-24T16:34:32.606Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt SUCCEEDED for meter 94144723-09c1-464b-b105-e009a415f508
tim@Timothys-MacBook-Air aws % 
