
# Terminal 1

tim@Timothys-MacBook-Air grid-meter-app % kubectl exec -it api-f55996f5b-48s8b -- /usr/bin/env | grep -E 'GRID_METER_GCP|SPRING_DATA_REDIS|SPRING_PROFILES_ACTIVE'
SPRING_DATA_REDIS_PORT=6379
SPRING_PROFILES_ACTIVE=cloud,cloud-gcp
SPRING_DATA_REDIS_HOST=10.10.0.3
GRID_METER_GCP_SERVICE_ACCOUNT_EMAIL=grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com
GRID_METER_GCP_MEMORYSTORE_CA_PATH=/etc/grid-meter/memorystore-ca.pem

tim@Timothys-MacBook-Air grid-meter-app % kubectl exec -it api-f55996f5b-48s8b -- /bin/sh                                                  
/app # cat /etc/grid-meter/memorystore-ca.pem
-----BEGIN CERTIFICATE-----
MIIGITCCA9WgAwIBAgIUAIEKMFQVVVtrdvU0wdN0VntwSCkwQQYJKoZIhvcNAQEK
MDSgDzANBglghkgBZQMEAgEFAKEcMBoGCSqGSIb3DQEBCDANBglghkgBZQMEAgEF
AKIDAgEgMGAxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpHb29nbGUgTExDMTwwOgYD
VQQDEzNHb29nbGUtUm9vdC1DQS02YWM3ZGQ3ZS0wMDAwLTIxZjgtOGNhZi1mYzQx
MTY3YzFmNzEwHhcNMjYwOTI0MTc0NTM1WhcNMzYwOTI0MTc0NTEyWjBMMQswCQYD
VQQGEwJVUzETMBEGA1UEChMKR29vZ2xlIExMQzEoMCYGA1UEAxMfQ0FTLU1hbmFn
ZWQgQ0EtdXMtY2VudHJhbDEtNmIwODCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
AQoCggEBAM+TdYUZgzaSHxV5g5t1Wu+M4T4eg9zHkwMuFc/i8dxalwtXHcYNKuZ7
koib9hn252MS5Bl53dddwdK0OXy4UkmsoO7M7eO8DXMT1qgQh5nPNW40lzMCxdFU
9aiee9RaSeB5lfZNjwfpXL7Dkc4Eg3KyOT9h9EkyrolwHptuEufzM3SB2nxzNOB2
SIdOVQrWy8qacmubtzzNA3yQfbdY0TTR/eqL365/cSZS0huTlaJZhDmgdRp732BG
ce0M8fQjB1VLCW8K1ORgg8QnUj0XkuyIwjyWofZdnllsPAROuuHBl557OW1CYFQl
OpEmPlFVjclzvds/LVShD56J6cM4szcCAwEAAaOCAX0wggF5MA4GA1UdDwEB/wQE
AwIBBjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBSK/R8kFqSZs5vpKlfy
ZrSHf/BLFDAfBgNVHSMEGDAWgBRhL9e3yr/cPcXfBtoMOI3C9lH1/DCBjQYIKwYB
BQUHAQEEgYAwfjB8BggrBgEFBQcwAoZwaHR0cDovL3ByaXZhdGVjYS1jb250ZW50
LTZhZGIyNTUyLTAwMDAtMjRlYi1hMTdmLTM0YzdlOTNjMWY5Zi5zdG9yYWdlLmdv
b2dsZWFwaXMuY29tL2YwZDA1OTdkMThiMjM2NmIyMzhiL2NhLmNydDCBggYDVR0f
BHsweTB3oHWgc4ZxaHR0cDovL3ByaXZhdGVjYS1jb250ZW50LTZhZGIyNTUyLTAw
MDAtMjRlYi1hMTdmLTM0YzdlOTNjMWY5Zi5zdG9yYWdlLmdvb2dsZWFwaXMuY29t
L2YwZDA1OTdkMThiMjM2NmIyMzhiL2NybC5jcmwwQQYJKoZIhvcNAQEKMDSgDzAN
BglghkgBZQMEAgEFAKEcMBoGCSqGSIb3DQEBCDANBglghkgBZQMEAgEFAKIDAgEg
A4ICAQCQ3Ih5BpIwDeD571FWhMiKbLKM2l3016RPL6QySGnlFV1RFLwabJZz01AT
dvM0jodsuQOwvsYjfWEwy+BJ7kx23wuHdOp6C7pPp2pnS783iRGBHdEDQCNHKz/g
Ma0MWGDxMNWjKswkqyb7rffWu9vkS/csBdX6jb5de+/AvUHgsl4uwwCsSn3u3Y0a
Rt8EjLQSXNtHb2db/rhW28aseZOp/qAmQzauaFovUv81coyeq4apUQuVr8VD/TA2
fhv8h6gqYHVmPzUEnGL/JbYojftdb63fxC8CRMwLYmouMdVT1IkJAxuFr9V/mhmh
l+qLBDE48kTRDLlAvXw54FnLPLYFPE8JSHhr3tSXDogcxdaweJPyeH9j6oSypfPZ
zXlp/Nb5LyIKrzh72NxhhqDMiAnza/L3wC8gEIUDy0tUhIqWMltgbYVf++iJ7FHg
mMyDO14/d/zw37aOq/F0qa3qBuXN6pzlKXjLMla1aYTd21Y4R/19fg0QU8ULc8pE
qCr3n7y8LOHUe+VgG+RhZgKMMAa3xOB21aXJSmdjCjIGsGViD2JNmOQz74pcwVZj
iCUAQ/g216+dMeIfMImIh7Cpq7Fu7uqtE6Yv/hkef5DK8t37yDVUrRxCKAEDrVw9
1ij3rFNkHDmzr+9NOixRFsgIKl+qeJVxXvzgc1VVcOdmpFiNfQ==
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIGGTCCA82gAwIBAgIUAI8iBNJfu3htBA2p2fEauwzH8fYwQQYJKoZIhvcNAQEK
MDSgDzANBglghkgBZQMEAgEFAKEcMBoGCSqGSIb3DQEBCDANBglghkgBZQMEAgEF
AKIDAgEgMGAxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpHb29nbGUgTExDMTwwOgYD
VQQDEzNHb29nbGUtUm9vdC1DQS02YWM3ZGQ3ZS0wMDAwLTIxZjgtOGNhZi1mYzQx
MTY3YzFmNzEwHhcNMjYwOTI0MTc0NTE0WhcNMzYwOTI0MTc0NTEyWjBgMQswCQYD
VQQGEwJVUzETMBEGA1UEChMKR29vZ2xlIExMQzE8MDoGA1UEAxMzR29vZ2xlLVJv
b3QtQ0EtNmFjN2RkN2UtMDAwMC0yMWY4LThjYWYtZmM0MTE2N2MxZjcxMIICIjAN
BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqASPp2nqTHmYnuJ12rYB7FmcrsbH
iEYPxgA457j1GhpuwOqZNmSEKeElxs8rqiHVbWlIK+5MIU4ghj1LXvll/7oCeBub
xk9tjZSD3hDBDxbBT1XNhiErOj2NRQUHPsuJBOBUaxWda9aSSfZsQyDJ2mOQifeR
MNIU5LJJs1/d3UF8MX6hNILASg2rvOh2m6IA66VW6ZK57ks8kq7zF7XTLAHX8POt
4IXryxvpKV0xEu9LkHW5bcpSWkaxmmq7/E537/vUwRr7Ldr9s1ZHdbs4YXMuT7R0
rQ3YHcdsbq3Mt8y1T6QV5GqK6DR/5eZcFuBRkBGYMKTMkUu4/BRp/DuilFDFgUc+
jTAyYIt9VE0hSFWyYjb+4NakD5RaExIFTDRcZE04HXQ7k4Y+wBh6txdyWUjGKiit
DvVEdev7C2H92MD5D8YDuv0KKXis5nR6x5cKWTE9625G7MptEfDYvde110vwSDq8
mRa0SJZq25A6uerKFGyEZSxsGw/ZvALjEz97hzvt6fs5Ng5+as/EmUAR0F+AngML
jKy9ZzQpGpUJ0ol7iQnrqj0CdiILZICZg/q4cFbhDsGV62DdbynIeiGvA3KSmR9Z
NTzyUHglqazbvbYtNN1pLZ6E5mSk5pMdlMKaUzsaDm0w/ptiN6rLI6iOVvLFSV3n
1l5sdvTDX739boMCAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
MAMBAf8wHQYDVR0OBBYEFGEv17fKv9w9xd8G2gw4jcL2UfX8MB8GA1UdIwQYMBaA
FGEv17fKv9w9xd8G2gw4jcL2UfX8MEEGCSqGSIb3DQEBCjA0oA8wDQYJYIZIAWUD
BAIBBQChHDAaBgkqhkiG9w0BAQgwDQYJYIZIAWUDBAIBBQCiAwIBIAOCAgEATPYr
jreuh+ccIX8/w1B6ot98lI9sPwRubZf/6+0xt7mHGi4gSFP5xqegyTad26AhOZPP
Ndy/kbSsmfm36WmTXFpc4Y28yFlyp3RdMUfpk9lzCe81zezwUM3OD+Tgm4A42fSm
qG4q80jbPE0scxdpdXSu7seaIXqP5JzjfxojRPtFS1SV5Vyu/oD/diXF/3FOH3pD
/DgYKo+wV/ks7BTpaxBv/BA6bcgk3EV18BaRR0ekdD0ywWzMcDQ1T1VvlwggRmjc
rLZKD4KWrFEtStyWdCbvcbMUPd8to66biN1Bdu6dsGocOUh2R3WCGytrW4hm/him
W9RXfcLOXfZsVW9NahFvPRdND7boEEbEEfB0pN7061qL/lfjeWfBPOq8HwN7u2VV
vx05EJTpYtJiHc9JwbLZEZYVwox3jyooUYye0NoZGV7DczDgAC5bdcqcyqCDSrpW
N9SKWAEEp1acqSAO2V+oBEv5aqTQ6FhC3ztGZ+1qr05jwWC+V+qnOXlCi6JxtKP/
V0hlzXYB1nrnmq5z146NBlq2UDUW3LBnQG1mPtHEgPJ6T/kK835TusqfYYEcN8n9
M7L1i3tAryyMq2Z3gm0aX2b+UKh2S35nGV850pHD+cgcQGYFjwAAll67hJxN9/je
loOzZhiOPw86eIbJw44rLGGqexg/Dx1iX/CFX28=
-----END CERTIFICATE-----


tim@Timothys-MacBook-Air grid-meter-app % kubectl logs -l app=api --prefix | grep Redis
[pod/api-f55996f5b-48s8b/api] 2026-09-24T20:43:38.776Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt starting for meter a4901a1e-420e-47d6-895d-4ee0795711de
[pod/api-f55996f5b-48s8b/api] 2026-09-24T20:43:38.783Z  INFO [customerId=] 1 --- [grid-meter-api] [ntainer#0-0-C-1] [                                                 ] c.g.api.reading.ReadingEventConsumer     : Redis write attempt SUCCEEDED for meter a4901a1e-420e-47d6-895d-4ee0795711de

tim@Timothys-MacBook-Air grid-meter-app % curl -s "https://search.maven.org/solrsearch/select?q=g:com.google.cloud+AND+a:google-cloud-iamcredentials&core=gav&rows=3&wt=json" | python3 -c "import json,sys; d=json.load(sys.stdin); [print(x['id']) for x in d['response']['docs']]"
     echo "---"
com.google.cloud:google-cloud-iamcredentials:2.93.0
com.google.cloud:google-cloud-iamcredentials:2.92.0
com.google.cloud:google-cloud-iamcredentials:2.64.0

tim@Timothys-MacBook-Air grid-meter-app % kubectl get pods -A | grep api-
default           api-f55996f5b-48s8b                                              1/1     Running   0             12m
default           api-f55996f5b-t8whn                                              1/1     Running   0             12m

tim@Timothys-MacBook-Air grid-meter-app % kubectl exec -it api-f55996f5b-48s8b -- /usr/bin/env | grep -E 'GRID_METER_GCP|SPRING_DATA_REDIS|SPRING_PROFILES_ACTIVE'
SPRING_DATA_REDIS_PORT=6379
SPRING_PROFILES_ACTIVE=cloud,cloud-gcp
SPRING_DATA_REDIS_HOST=10.10.0.3
GRID_METER_GCP_SERVICE_ACCOUNT_EMAIL=grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com
GRID_METER_GCP_MEMORYSTORE_CA_PATH=/etc/grid-meter/memorystore-ca.pem
tim@Timothys-MacBook-Air grid-meter-app % kubectl exec -it api-f55996f5b-48s8b -- /bin/sh                                                  
/app # cat /etc/grid-meter/memorystore-ca.pem
-----BEGIN CERTIFICATE-----
MIIGITCCA9WgAwIBAgIUAIEKMFQVVVtrdvU0wdN0VntwSCkwQQYJKoZIhvcNAQEK
MDSgDzANBglghkgBZQMEAgEFAKEcMBoGCSqGSIb3DQEBCDANBglghkgBZQMEAgEF
AKIDAgEgMGAxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpHb29nbGUgTExDMTwwOgYD
VQQDEzNHb29nbGUtUm9vdC1DQS02YWM3ZGQ3ZS0wMDAwLTIxZjgtOGNhZi1mYzQx
MTY3YzFmNzEwHhcNMjYwOTI0MTc0NTM1WhcNMzYwOTI0MTc0NTEyWjBMMQswCQYD
VQQGEwJVUzETMBEGA1UEChMKR29vZ2xlIExMQzEoMCYGA1UEAxMfQ0FTLU1hbmFn
ZWQgQ0EtdXMtY2VudHJhbDEtNmIwODCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
AQoCggEBAM+TdYUZgzaSHxV5g5t1Wu+M4T4eg9zHkwMuFc/i8dxalwtXHcYNKuZ7
koib9hn252MS5Bl53dddwdK0OXy4UkmsoO7M7eO8DXMT1qgQh5nPNW40lzMCxdFU
9aiee9RaSeB5lfZNjwfpXL7Dkc4Eg3KyOT9h9EkyrolwHptuEufzM3SB2nxzNOB2
SIdOVQrWy8qacmubtzzNA3yQfbdY0TTR/eqL365/cSZS0huTlaJZhDmgdRp732BG
ce0M8fQjB1VLCW8K1ORgg8QnUj0XkuyIwjyWofZdnllsPAROuuHBl557OW1CYFQl
OpEmPlFVjclzvds/LVShD56J6cM4szcCAwEAAaOCAX0wggF5MA4GA1UdDwEB/wQE
AwIBBjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBSK/R8kFqSZs5vpKlfy
ZrSHf/BLFDAfBgNVHSMEGDAWgBRhL9e3yr/cPcXfBtoMOI3C9lH1/DCBjQYIKwYB
BQUHAQEEgYAwfjB8BggrBgEFBQcwAoZwaHR0cDovL3ByaXZhdGVjYS1jb250ZW50
LTZhZGIyNTUyLTAwMDAtMjRlYi1hMTdmLTM0YzdlOTNjMWY5Zi5zdG9yYWdlLmdv
b2dsZWFwaXMuY29tL2YwZDA1OTdkMThiMjM2NmIyMzhiL2NhLmNydDCBggYDVR0f
BHsweTB3oHWgc4ZxaHR0cDovL3ByaXZhdGVjYS1jb250ZW50LTZhZGIyNTUyLTAw
MDAtMjRlYi1hMTdmLTM0YzdlOTNjMWY5Zi5zdG9yYWdlLmdvb2dsZWFwaXMuY29t
L2YwZDA1OTdkMThiMjM2NmIyMzhiL2NybC5jcmwwQQYJKoZIhvcNAQEKMDSgDzAN
BglghkgBZQMEAgEFAKEcMBoGCSqGSIb3DQEBCDANBglghkgBZQMEAgEFAKIDAgEg
A4ICAQCQ3Ih5BpIwDeD571FWhMiKbLKM2l3016RPL6QySGnlFV1RFLwabJZz01AT
dvM0jodsuQOwvsYjfWEwy+BJ7kx23wuHdOp6C7pPp2pnS783iRGBHdEDQCNHKz/g
Ma0MWGDxMNWjKswkqyb7rffWu9vkS/csBdX6jb5de+/AvUHgsl4uwwCsSn3u3Y0a
Rt8EjLQSXNtHb2db/rhW28aseZOp/qAmQzauaFovUv81coyeq4apUQuVr8VD/TA2
fhv8h6gqYHVmPzUEnGL/JbYojftdb63fxC8CRMwLYmouMdVT1IkJAxuFr9V/mhmh
l+qLBDE48kTRDLlAvXw54FnLPLYFPE8JSHhr3tSXDogcxdaweJPyeH9j6oSypfPZ
zXlp/Nb5LyIKrzh72NxhhqDMiAnza/L3wC8gEIUDy0tUhIqWMltgbYVf++iJ7FHg
mMyDO14/d/zw37aOq/F0qa3qBuXN6pzlKXjLMla1aYTd21Y4R/19fg0QU8ULc8pE
qCr3n7y8LOHUe+VgG+RhZgKMMAa3xOB21aXJSmdjCjIGsGViD2JNmOQz74pcwVZj
iCUAQ/g216+dMeIfMImIh7Cpq7Fu7uqtE6Yv/hkef5DK8t37yDVUrRxCKAEDrVw9
1ij3rFNkHDmzr+9NOixRFsgIKl+qeJVxXvzgc1VVcOdmpFiNfQ==
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIGGTCCA82gAwIBAgIUAI8iBNJfu3htBA2p2fEauwzH8fYwQQYJKoZIhvcNAQEK
MDSgDzANBglghkgBZQMEAgEFAKEcMBoGCSqGSIb3DQEBCDANBglghkgBZQMEAgEF
AKIDAgEgMGAxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpHb29nbGUgTExDMTwwOgYD
VQQDEzNHb29nbGUtUm9vdC1DQS02YWM3ZGQ3ZS0wMDAwLTIxZjgtOGNhZi1mYzQx
MTY3YzFmNzEwHhcNMjYwOTI0MTc0NTE0WhcNMzYwOTI0MTc0NTEyWjBgMQswCQYD
VQQGEwJVUzETMBEGA1UEChMKR29vZ2xlIExMQzE8MDoGA1UEAxMzR29vZ2xlLVJv
b3QtQ0EtNmFjN2RkN2UtMDAwMC0yMWY4LThjYWYtZmM0MTE2N2MxZjcxMIICIjAN
BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqASPp2nqTHmYnuJ12rYB7FmcrsbH
iEYPxgA457j1GhpuwOqZNmSEKeElxs8rqiHVbWlIK+5MIU4ghj1LXvll/7oCeBub
xk9tjZSD3hDBDxbBT1XNhiErOj2NRQUHPsuJBOBUaxWda9aSSfZsQyDJ2mOQifeR
MNIU5LJJs1/d3UF8MX6hNILASg2rvOh2m6IA66VW6ZK57ks8kq7zF7XTLAHX8POt
4IXryxvpKV0xEu9LkHW5bcpSWkaxmmq7/E537/vUwRr7Ldr9s1ZHdbs4YXMuT7R0
rQ3YHcdsbq3Mt8y1T6QV5GqK6DR/5eZcFuBRkBGYMKTMkUu4/BRp/DuilFDFgUc+
jTAyYIt9VE0hSFWyYjb+4NakD5RaExIFTDRcZE04HXQ7k4Y+wBh6txdyWUjGKiit
DvVEdev7C2H92MD5D8YDuv0KKXis5nR6x5cKWTE9625G7MptEfDYvde110vwSDq8
mRa0SJZq25A6uerKFGyEZSxsGw/ZvALjEz97hzvt6fs5Ng5+as/EmUAR0F+AngML
jKy9ZzQpGpUJ0ol7iQnrqj0CdiILZICZg/q4cFbhDsGV62DdbynIeiGvA3KSmR9Z
NTzyUHglqazbvbYtNN1pLZ6E5mSk5pMdlMKaUzsaDm0w/ptiN6rLI6iOVvLFSV3n
1l5sdvTDX739boMCAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
MAMBAf8wHQYDVR0OBBYEFGEv17fKv9w9xd8G2gw4jcL2UfX8MB8GA1UdIwQYMBaA
FGEv17fKv9w9xd8G2gw4jcL2UfX8MEEGCSqGSIb3DQEBCjA0oA8wDQYJYIZIAWUD
BAIBBQChHDAaBgkqhkiG9w0BAQgwDQYJYIZIAWUDBAIBBQCiAwIBIAOCAgEATPYr
jreuh+ccIX8/w1B6ot98lI9sPwRubZf/6+0xt7mHGi4gSFP5xqegyTad26AhOZPP
Ndy/kbSsmfm36WmTXFpc4Y28yFlyp3RdMUfpk9lzCe81zezwUM3OD+Tgm4A42fSm
qG4q80jbPE0scxdpdXSu7seaIXqP5JzjfxojRPtFS1SV5Vyu/oD/diXF/3FOH3pD
/DgYKo+wV/ks7BTpaxBv/BA6bcgk3EV18BaRR0ekdD0ywWzMcDQ1T1VvlwggRmjc
rLZKD4KWrFEtStyWdCbvcbMUPd8to66biN1Bdu6dsGocOUh2R3WCGytrW4hm/him
W9RXfcLOXfZsVW9NahFvPRdND7boEEbEEfB0pN7061qL/lfjeWfBPOq8HwN7u2VV
vx05EJTpYtJiHc9JwbLZEZYVwox3jyooUYye0NoZGV7DczDgAC5bdcqcyqCDSrpW
N9SKWAEEp1acqSAO2V+oBEv5aqTQ6FhC3ztGZ+1qr05jwWC+V+qnOXlCi6JxtKP/
V0hlzXYB1nrnmq5z146NBlq2UDUW3LBnQG1mPtHEgPJ6T/kK835TusqfYYEcN8n9
M7L1i3tAryyMq2Z3gm0aX2b+UKh2S35nGV850pHD+cgcQGYFjwAAll67hJxN9/je
loOzZhiOPw86eIbJw44rLGGqexg/Dx1iX/CFX28=
-----END CERTIFICATE-----
/app # exit


# Terminal 2

tim@Timothys-MacBook-Air grid-meter-app % curl -s "https://search.maven.org/solrsearch/select?q=g:com.google.cloud+AND+a:google-cloud-iamcredentials&core=gav&rows=3&wt=json" | python3 -c "import json,sys; d=json.load(sys.stdin); [print(x['id']) for x in d['response']['docs']]"
     echo "---"
com.google.cloud:google-cloud-iamcredentials:2.93.0
com.google.cloud:google-cloud-iamcredentials:2.92.0
com.google.cloud:google-cloud-iamcredentials:2.64.0

tim@Timothys-MacBook-Air grid-meter-app % TOKEN=$(curl -s -X POST http://34.9.29.158/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"demo","password":"GridMeter!Demo2026"}' | python3 -c 'import json,sys;print(json.load(sys.stdin)["accessToken"])')
tim@Timothys-MacBook-Air grid-meter-app % curl -s -X POST http://34.9.29.158/api/v1/readings \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"meterId":"a4901a1e-420e-47d6-895d-4ee0795711de","readingTimestamp":"2026-09-24T21:15:00Z","value":333.33}'
{"id":"17c2beda-89b0-482c-9a33-0e4a27418abc","meterId":"a4901a1e-420e-47d6-895d-4ee0795711de","readingTimestamp":"2026-09-24T21:15:00Z","receivedAt":"2026-09-24T20:56:21.437602300Z","value":333.33}%                          tim@Timothys-MacBook-Air grid-meter-app % 

