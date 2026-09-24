
tim@Timothys-MacBook-Air azure % pwd   
/Users/tim/Documents/workspace/java/apps/grid-meter-app/terraform/azure
tim@Timothys-MacBook-Air azure % kubectl get pods -A | grep api-
default       api-55795c5fdf-kzwbw                                        1/1     Running             0             13m
default       api-55795c5fdf-wb2fq                                        1/1     Running             1 (14m ago)   14m

tim@Timothys-MacBook-Air azure % kubectl exec -it api-55795c5fdf-kzwbw -- /usr/bin/env | grep AZURE
AZURE_FEDERATED_TOKEN_FILE=/var/run/secrets/azure/tokens/azure-identity-token
AZURE_AUTHORITY_HOST=https://login.microsoftonline.com/
AZURE_CLIENT_ID=e7d5af6c-2d03-448d-8438-a5e26896838c
AZURE_TENANT_ID=91737469-4965-4d2f-a72d-9ba8a531a355
tim@Timothys-MacBook-Air azure % 

tim@Timothys-MacBook-Air azure % kubectl exec -it api-55795c5fdf-kzwbw -- /bin/sh                  
/app # which apk
/sbin/apk
/app # apk add --no-cache curl redis
(1/9) Installing c-ares (1.34.8-r0)
(2/9) Installing libunistring (1.4.2-r0)
(3/9) Installing libidn2 (2.3.8-r0)
(4/9) Installing nghttp2-libs (1.69.0-r0)
(5/9) Installing libpsl (0.21.5-r3)
(6/9) Installing zstd-libs (1.5.7-r2)
(7/9) Installing libcurl (8.22.0-r0)
(8/9) Installing curl (8.22.0-r0)
(9/9) Installing redis (8.8.0-r0)
  Executing redis-8.8.0-r0.pre-install
  Executing redis-8.8.0-r0.post-install
Executing busybox-1.37.0-r31.trigger
OK: 34.4 MiB in 53 packages
/app # apk add --no-cache curl redis
OK: 34.4 MiB in 53 packages
/app # which curl
/usr/bin/curl
/app # which redis-cli
/usr/bin/redis-cli
/app # 
/app # ACCESS_TOKEN=$(curl -s -X POST "${AZURE_AUTHORITY_HOST}${AZURE_TENANT_ID}/oauth2/v2.0/token" \
>   --data-urlencode "client_id=${AZURE_CLIENT_ID}" \
>   --data-urlencode "grant_type=client_credentials" \
>   --data-urlencode "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
>   --data-urlencode "client_assertion=$(cat ${AZURE_FEDERATED_TOKEN_FILE})" \
>   --data-urlencode "scope=https://redis.azure.com/.default" \
>   | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
/app # echo "token length: ${#ACCESS_TOKEN}"
token length: 1654
/app # echo $ACCESS_TOKEN
<redacted: real Entra ID access token, ~1650 chars -- scrubbed before commit, since AWS-key-style credential material should never go into git history even after the underlying resource (this Redis instance, this identity) is torn down>
/app # 

/app # PAYLOAD=$(echo "$ACCESS_TOKEN" | cut -d. -f2)
/app # echo $PAYLOAD
<redacted: base64url JWT payload segment of the same access token above -- scrubbed for consistency, though the header/signature needed to replay it are only in the (also redacted) full token above>

/app # MOD=$(( ${#PAYLOAD} % 4 )); [ "$MOD" -ne 0 ] && PAYLOAD="${PAYLOAD}$(printf '=%.0s' $(seq 1 $((4-MOD))))"
/app # echo $MOD
3
/app # CLAIMS=$(echo "$PAYLOAD" | tr '_-' '/+' | base64 -d 2>/dev/null)
/app # echo $CLAIMS
{"aud":"https://redis.azure.com","iss":"https://sts.windows.net/91737469-4965-4d2f-a72d-9ba8a531a355/","iat":1790287919,"nbf":1790287919,"exp":1790374619,"aio":"ASQA2/8eAAAAibIztlyEj9KkHr0JuQSYB9q0msSMA/UirvYPBR+Xll8=","appid":"e7d5af6c-2d03-448d-8438-a5e26896838c","appidacr":"2","idp":"https://sts.windows.net/91737469-4965-4d2f-a72d-9ba8a531a355/","idtyp":"app","oid":"8932f5b8-6174-4777-bfaa-fc47dd72e9a7","rh":"1.ADYAaXRzkWVJL02nLZuopTGjVbtfyqzktwlAgfE344_WbXgAAAA2AA.","sub":"8932f5b8-6174-4777-bfaa-fc47dd72e9a7","tid":"91737469-4965-4d2f-a72d-9ba8a531a355","uti":"bo9COqg1G0qbnOILQuZwAA","ver":"1.0","xms_act_fct":"9 3","xms_ftd":"E7x0_5TZ3DNlSWZ-OxoPGJxZ1BnsOgI8KfR3-HvUmzYBdXNjZW50cmFsLWRzbXM","xms_idrel":"7 24","xms_rd":"0.AVkApv8KBQgCEgE2EhQIBxIQxJxNnolw5kSSpQA4AzF-1hIUCAgSELtfyqzktwlAgfE344_WbXgSFAgLEhCBqWvYlnbQDCEjBFwioNhlGg4IChIKMTc5MDI4NzAzMA","xms_sub_fct":"3 9"}
/app # OID=$(echo "$CLAIMS" | grep -o '"oid":"[^"]*"' | cut -d'"' -f4)
/app # echo "oid: $OID"
oid: 8932f5b8-6174-4777-bfaa-fc47dd72e9a7
/app # redis-cli -h grid-meter-app-redis.centralus.redis.azure.net -p 10000 --tls --user "$OID" --pass "$ACCESS_TOKEN" PING
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
PONG
/app # redis-cli -h grid-meter-app-redis.centralus.redis.azure.net -p 10000 --tls --user "$OID" --pass "$ACCESS_TOKEN" GET "reading:latest:c6d7
18ea-3d01-4dce-8c34-b2bab454d5dc" 
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
"{\"@class\":\"com.gridmeter.api.reading.LatestReading\",\"meterId\":\"c6d718ea-3d01-4dce-8c34-b2bab454d5dc\",\"readingTimestamp\":\"2026-09-24T22:05:00Z\",\"value\":[\"java.math.BigDecimal\",55.5]}"
/app # 

