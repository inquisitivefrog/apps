
tim@Timothys-MacBook-Air grid-meter-app % ./k8s/deploy-azure.sh 
== Reading Terraform outputs ==
== Fetching kubeconfig for grid-meter-app-aks ==
WARNING: Merged "grid-meter-app-aks" as current context in /Users/tim/.kube/config
== Authenticating Docker to ACR ==
Login Succeeded
== Building + pushing images (tag: latest, platform: linux/amd64) ==
[+] Building 164.6s (15/15) FINISHED                                                                  docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                  0.0s
 => => transferring dockerfile: 373B                                                                                  0.0s
 => [internal] load metadata for docker.io/library/maven:3.9-eclipse-temurin-25                                       0.0s
 => [internal] load metadata for docker.io/library/eclipse-temurin:25-jre-alpine                                      0.0s
 => [internal] load .dockerignore                                                                                     0.0s
 => => transferring context: 2B                                                                                       0.0s
 => [build 1/6] FROM docker.io/library/maven:3.9-eclipse-temurin-25@sha256:d67198007bb4441b07d45587320f83154de80ece3  0.0s
 => => resolve docker.io/library/maven:3.9-eclipse-temurin-25@sha256:d67198007bb4441b07d45587320f83154de80ece3608f80  0.0s
 => [internal] load build context                                                                                     0.0s
 => => transferring context: 64.10kB                                                                                  0.0s
 => [stage-1 1/3] FROM docker.io/library/eclipse-temurin:25-jre-alpine@sha256:3137541deb3cac6626b5d9a4a2187bc0d6a343  0.0s
 => => resolve docker.io/library/eclipse-temurin:25-jre-alpine@sha256:3137541deb3cac6626b5d9a4a2187bc0d6a34312f858bd  0.0s
 => CACHED [build 2/6] WORKDIR /build                                                                                 0.0s
 => [build 3/6] COPY pom.xml .                                                                                        0.0s
 => [build 4/6] RUN mvn dependency:go-offline                                                                       145.2s
 => [build 5/6] COPY src ./src                                                                                        0.0s 
 => [build 6/6] RUN mvn package -DskipTests                                                                          16.2s 
 => CACHED [stage-1 2/3] WORKDIR /app                                                                                 0.0s 
 => [stage-1 3/3] COPY --from=build /build/target/*.jar app.jar                                                       0.2s 
 => exporting to image                                                                                                2.6s 
 => => exporting layers                                                                                               2.5s 
 => => exporting manifest sha256:4a2ce2cfc04e91372c502f9e996d61c1d7ff1e2771477ac8f08596327b94c7a0                     0.0s 
 => => exporting config sha256:5019c42064cef990abdd1eb530bbcf865d40858b0dadc79f6c63bfd969aac0e2                       0.0s
 => => exporting attestation manifest sha256:7cd564798dad04ea08518616d663037912a728463858e3e3ac32d880318d8a45         0.0s
 => => exporting manifest list sha256:2a893ee0c4da86834ecef23188f87c0d5164a191c011ba1033dd159291784a72                0.0s
 => => naming to gridmeterapp3caa5ec0.azurecr.io/api:latest                                                           0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/z2qvumewdtpa1hden9i48c94w
[+] Building 1.2s (15/15) FINISHED                                                                    docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                  0.0s
 => => transferring dockerfile: 337B                                                                                  0.0s
 => [internal] load metadata for docker.io/library/node:24-alpine                                                     0.0s
 => [internal] load metadata for docker.io/library/nginx:1.27-alpine                                                  0.0s
 => [internal] load .dockerignore                                                                                     0.0s
 => => transferring context: 2B                                                                                       0.0s
 => [build 1/6] FROM docker.io/library/node:24-alpine@sha256:e67514e5d0f6c46656005e1b693b2ec9d52e80b641307de684d4a01  0.0s
 => => resolve docker.io/library/node:24-alpine@sha256:e67514e5d0f6c46656005e1b693b2ec9d52e80b641307de684d4a015ba7a4  0.0s
 => [stage-1 1/3] FROM docker.io/library/nginx:1.27-alpine@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef  0.0s
 => => resolve docker.io/library/nginx:1.27-alpine@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e  0.0s
 => [internal] load build context                                                                                     1.1s
 => => transferring context: 4.04MB                                                                                   1.0s
 => CACHED [build 2/6] WORKDIR /build                                                                                 0.0s
 => CACHED [build 3/6] COPY package.json package-lock.json ./                                                         0.0s
 => CACHED [build 4/6] RUN npm ci                                                                                     0.0s
 => CACHED [build 5/6] COPY . .                                                                                       0.0s
 => CACHED [build 6/6] RUN npm run build                                                                              0.0s
 => CACHED [stage-1 2/3] COPY --from=build /build/dist /usr/share/nginx/html                                          0.0s
 => CACHED [stage-1 3/3] COPY nginx.conf /etc/nginx/conf.d/default.conf                                               0.0s
 => exporting to image                                                                                                0.0s
 => => exporting layers                                                                                               0.0s
 => => exporting manifest sha256:84b707d06b573d0b966201213a6a2fe21606bf20a7c7e5f35d3d9c410836a67a                     0.0s
 => => exporting config sha256:53077f1e6d67a3710e1346f67449392cfbcd71390e725b33c0a1e9039fd46011                       0.0s
 => => exporting attestation manifest sha256:55c30b4e2c0dba9b07a0c0875ae573c6fb0b4288ea651c47b51b19741971ef1a         0.0s
 => => exporting manifest list sha256:d3ece7b9563909f38ac530c5b0add90e7441c5792e919081294550b0202d34ac                0.0s
 => => naming to gridmeterapp3caa5ec0.azurecr.io/frontend:latest                                                      0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/1g2fmz3qohngy7uk91rmtl9zv
The push refers to repository [gridmeterapp3caa5ec0.azurecr.io/api]
5f4b8a3fd811: Pushed 
44136fa355b3: Pushed 
c76ddb39a6b7: Pushed 
55afa1ecc21d: Pushed 
51c06ae8de15: Pushed 
e8a125070461: Pushed 
ae042fea25ae: Pushed 
52c09128601b: Pushed 
27e6229dd31e: Pushed 
latest: digest: sha256:2a893ee0c4da86834ecef23188f87c0d5164a191c011ba1033dd159291784a72 size: 856
The push refers to repository [gridmeterapp3caa5ec0.azurecr.io/frontend]
68ebf00f7e18: Pushed 
44136fa355b3: Mounted from api 
61ca4f733c80: Pushed 
f18232174bc9: Pushed 
b464cfdf2a63: Pushed 
d7e507024086: Pushed 
81bd8ed7ec67: Pushed 
197eb75867ef: Pushed 
34a64644b756: Pushed 
39c2ddfd6010: Pushed 
e24fca0e6f92: Pushed 
b14fb3ea6fd1: Pushed 
latest: digest: sha256:d3ece7b9563909f38ac530c5b0add90e7441c5792e919081294550b0202d34ac size: 856
== Applying Traefik CRDs + RBAC (shared with kind/AWS/GCP) ==
customresourcedefinition.apiextensions.k8s.io/ingressroutes.traefik.io created
customresourcedefinition.apiextensions.k8s.io/ingressroutetcps.traefik.io created
customresourcedefinition.apiextensions.k8s.io/ingressrouteudps.traefik.io created
customresourcedefinition.apiextensions.k8s.io/middlewares.traefik.io created
customresourcedefinition.apiextensions.k8s.io/middlewaretcps.traefik.io created
customresourcedefinition.apiextensions.k8s.io/serverstransports.traefik.io created
customresourcedefinition.apiextensions.k8s.io/serverstransporttcps.traefik.io created
customresourcedefinition.apiextensions.k8s.io/tlsoptions.traefik.io created
customresourcedefinition.apiextensions.k8s.io/tlsstores.traefik.io created
customresourcedefinition.apiextensions.k8s.io/traefikservices.traefik.io created
clusterrole.rbac.authorization.k8s.io/traefik-ingress-controller created
clusterrolebinding.rbac.authorization.k8s.io/traefik-ingress-controller created
== Applying Traefik controller (Azure variant - LoadBalancer, not hostPort) ==
serviceaccount/traefik-ingress-controller created
deployment.apps/traefik created
service/traefik-web created
service/traefik-metrics created
== Un-defaulting AKS's own built-in default StorageClass (managed-csi) ==
storageclass.storage.k8s.io/managed-csi patched
== Applying default StorageClass (XFS-formatted, needed for Kafka's PVCs) ==
storageclass.storage.k8s.io/managed-csi-xfs created
== Fetching the real Postgres admin password from Key Vault (never hardcoded) ==
== Generating a fresh JWT signing secret for this deployment ==
== Applying secrets (generated at deploy time, never committed) ==
secret/grid-meter-secrets created
== Applying config (real Postgres/Redis endpoints, generated at deploy time) ==
configmap/grid-meter-config created
== Applying Kafka (self-hosted in-cluster, unchanged from every other target) ==
service/kafka-headless created
statefulset.apps/kafka created
== Applying api + frontend (real image + Workload Identity client ID baked in before the first apply, not patched after) ==
serviceaccount/grid-meter-app created
deployment.apps/api created
service/api created
deployment.apps/frontend created
service/frontend created
== Forcing a rollout restart (picks up a freshly-pushed :latest on a repeat run of this script) ==
deployment.apps/api restarted
deployment.apps/frontend restarted
== Applying IngressRoute (target-agnostic - only references Service names) ==
ingressroute.traefik.io/grid-meter created
== Waiting for rollouts ==
deployment "traefik" successfully rolled out
Waiting for 3 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 1 pods to be ready...
Waiting for 1 pods to be ready...
partitioned roll out complete: 3 new pods have been updated...
Waiting for deployment "api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "api" rollout to finish: 1 old replicas are pending termination...
deployment "api" successfully rolled out
deployment "frontend" successfully rolled out
== Waiting for the LoadBalancer's public IP (provisioning takes a minute or two) ==

Done. App should be reachable at http://4.150.160.117
tim@Timothys-MacBook-Air grid-meter-app % ./k8s/check-resources-azure.sh 
== Checking Kubernetes-deployed app layer (context: grid-meter-app-aks) ==

-- Traefik --
  PASS  Traefik Deployment ready: 1/1
  PASS  traefik-web Service type: LoadBalancer
  PASS  traefik-web external IP assigned: 4.150.160.117
  PASS  traefik-metrics Service exists: ClusterIP

-- Kafka --
  PASS  Kafka StatefulSet ready replicas: 3
  PASS  kafka-headless Service exists: None
  PASS  Kafka PVCs bound (expect 3): 3

-- api / frontend --
  PASS  api Deployment ready: 2/2
  PASS  api Service exists: ClusterIP
  PASS  frontend Deployment ready: 1/1
  PASS  frontend Service exists: ClusterIP

-- Config/secrets/routing --
  PASS  grid-meter-config ConfigMap exists: grid-meter-config
  PASS  grid-meter-secrets Secret exists: grid-meter-secrets
  PASS  IngressRoute exists: grid-meter
  PASS  managed-csi-xfs StorageClass is default: true

-- Observability (optional; only checked if deployed via k8s/deploy-observability.sh) --
  (not deployed - skipping; run k8s/deploy-observability.sh first if this cluster should have it)

== Summary: 15 passed, 0 failed ==
All expected Kubernetes-deployed resources confirmed present and healthy.
tim@Timothys-MacBook-Air grid-meter-app % kubectl get nodes -A -o wide
NAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-26917399-vmss000000   Ready    <none>   16m   v1.35.7   10.20.0.4     <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-26917399-vmss000001   Ready    <none>   16m   v1.35.7   10.20.0.5     <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
tim@Timothys-MacBook-Air grid-meter-app % kubectl get pods -A -o wide
NAMESPACE     NAME                                                   READY   STATUS    RESTARTS        AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
default       api-55795c5fdf-kzwbw                                   1/1     Running   0               2m40s   10.244.0.30    aks-system-26917399-vmss000001   <none>           <none>
default       api-55795c5fdf-wb2fq                                   1/1     Running   1 (3m26s ago)   4m2s    10.244.0.187   aks-system-26917399-vmss000001   <none>           <none>
default       frontend-56b7d965cd-xt2bz                              1/1     Running   0               4m2s    10.244.1.48    aks-system-26917399-vmss000000   <none>           <none>
default       kafka-0                                                1/1     Running   0               4m4s    10.244.1.178   aks-system-26917399-vmss000000   <none>           <none>
default       kafka-1                                                1/1     Running   0               3m23s   10.244.1.33    aks-system-26917399-vmss000000   <none>           <none>
default       kafka-2                                                1/1     Running   0               3m3s    10.244.0.117   aks-system-26917399-vmss000001   <none>           <none>
default       traefik-7b75595b65-cbx4w                               1/1     Running   0               4m7s    10.244.1.245   aks-system-26917399-vmss000000   <none>           <none>
kube-system   azure-cns-4gng7                                        2/2     Running   0               16m     10.20.0.4      aks-system-26917399-vmss000000   <none>           <none>
kube-system   azure-cns-8zmqm                                        2/2     Running   0               16m     10.20.0.5      aks-system-26917399-vmss000001   <none>           <none>
kube-system   azure-ip-masq-agent-txfbg                              1/1     Running   0               16m     10.20.0.4      aks-system-26917399-vmss000000   <none>           <none>
kube-system   azure-ip-masq-agent-x9m52                              1/1     Running   0               16m     10.20.0.5      aks-system-26917399-vmss000001   <none>           <none>
kube-system   azure-npm-8flqp                                        1/1     Running   0               16m     10.20.0.4      aks-system-26917399-vmss000000   <none>           <none>
kube-system   azure-npm-vrq66                                        1/1     Running   0               16m     10.20.0.5      aks-system-26917399-vmss000001   <none>           <none>
kube-system   azure-wi-webhook-controller-manager-5bcdc6f8bf-98zkp   1/1     Running   0               16m     10.244.1.10    aks-system-26917399-vmss000000   <none>           <none>
kube-system   azure-wi-webhook-controller-manager-5bcdc6f8bf-9swt4   1/1     Running   0               16m     10.244.1.209   aks-system-26917399-vmss000000   <none>           <none>
kube-system   cloud-node-manager-8w8dh                               1/1     Running   0               16m     10.20.0.5      aks-system-26917399-vmss000001   <none>           <none>
kube-system   cloud-node-manager-d5t94                               1/1     Running   0               16m     10.20.0.4      aks-system-26917399-vmss000000   <none>           <none>
kube-system   coredns-5d474ff6db-hj4nh                               1/1     Running   0               16m     10.244.1.191   aks-system-26917399-vmss000000   <none>           <none>
kube-system   coredns-5d474ff6db-ssmbk                               1/1     Running   0               15m     10.244.0.88    aks-system-26917399-vmss000001   <none>           <none>
kube-system   coredns-autoscaler-6769f8f9b-cf9fh                     1/1     Running   0               16m     10.244.1.93    aks-system-26917399-vmss000000   <none>           <none>
kube-system   csi-azuredisk-node-85vgs                               3/3     Running   0               16m     10.20.0.4      aks-system-26917399-vmss000000   <none>           <none>
kube-system   csi-azuredisk-node-x7fwd                               3/3     Running   0               16m     10.20.0.5      aks-system-26917399-vmss000001   <none>           <none>
kube-system   csi-azurefile-node-l5dnp                               4/4     Running   0               16m     10.20.0.5      aks-system-26917399-vmss000001   <none>           <none>
kube-system   csi-azurefile-node-xzhfj                               4/4     Running   0               16m     10.20.0.4      aks-system-26917399-vmss000000   <none>           <none>
kube-system   konnectivity-agent-5789666589-gflnc                    1/1     Running   0               16m     10.244.1.88    aks-system-26917399-vmss000000   <none>           <none>
kube-system   konnectivity-agent-5789666589-rdzp5                    1/1     Running   0               15m     10.244.0.219   aks-system-26917399-vmss000001   <none>           <none>
kube-system   konnectivity-agent-autoscaler-57c596c6fd-l97b8         1/1     Running   0               16m     10.244.1.230   aks-system-26917399-vmss000000   <none>           <none>
kube-system   kube-proxy-84mwm                                       1/1     Running   0               16m     10.20.0.5      aks-system-26917399-vmss000001   <none>           <none>
kube-system   kube-proxy-spvvb                                       1/1     Running   0               16m     10.20.0.4      aks-system-26917399-vmss000000   <none>           <none>
kube-system   metrics-server-85768b658b-8d4pz                        2/2     Running   0               15m     10.244.0.43    aks-system-26917399-vmss000001   <none>           <none>
kube-system   metrics-server-85768b658b-zrkh5                        2/2     Running   0               15m     10.244.0.150   aks-system-26917399-vmss000001   <none>           <none>
tim@Timothys-MacBook-Air grid-meter-app % 

tim@Timothys-MacBook-Air grid-meter-app % ./k8s/deploy-observability.sh 
== Adding/updating the prometheus-community Helm repo ==
== Generating ConfigMaps from observability/ source files ==
configmap/grid-meter-grafana-alerting created
configmap/grid-meter-grafana-dashboard created
configmap/grid-meter-tempo-config created
configmap/grid-meter-alloy-config created
== Installing/upgrading kube-prometheus-stack ==
Release "kube-prometheus-stack" does not exist. Installing it now.
NAME: kube-prometheus-stack
LAST DEPLOYED: Thu Sep 24 15:09:33 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace default get pods -l "release=kube-prometheus-stack"

Get Grafana 'admin' user password by running:

  kubectl --namespace default get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

Access Grafana local instance:

  export POD_NAME=$(kubectl --namespace default get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kube-prometheus-stack" -oname)
  kubectl --namespace default port-forward $POD_NAME 3000

Get your grafana admin user password by running:

  kubectl get secret --namespace default -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo


Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
== Applying Loki, Tempo, Alloy ==
deployment.apps/loki created
service/loki created
deployment.apps/tempo created
service/tempo created
serviceaccount/alloy created
clusterrole.rbac.authorization.k8s.io/alloy created
clusterrolebinding.rbac.authorization.k8s.io/alloy created
deployment.apps/alloy created
== Applying the api ServiceMonitor (needs the CRD kube-prometheus-stack just installed) ==
servicemonitor.monitoring.coreos.com/grid-meter-api created
== Waiting for rollouts ==
Waiting for deployment "loki" rollout to finish: 0 of 1 updated replicas are available...
deployment "loki" successfully rolled out
Waiting for deployment "tempo" rollout to finish: 0 of 1 updated replicas are available...
deployment "tempo" successfully rolled out
Waiting for deployment "alloy" rollout to finish: 0 of 1 updated replicas are available...
deployment "alloy" successfully rolled out
deployment "kube-prometheus-stack-grafana" successfully rolled out

Done. Grafana: kubectl port-forward svc/kube-prometheus-stack-grafana 3001:80
      Prometheus: kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090
tim@Timothys-MacBook-Air grid-meter-app % ./k8s/check-resources-azure.sh                        
== Checking Kubernetes-deployed app layer (context: grid-meter-app-aks) ==

-- Traefik --
  PASS  Traefik Deployment ready: 1/1
  PASS  traefik-web Service type: LoadBalancer
  PASS  traefik-web external IP assigned: 4.150.160.117
  PASS  traefik-metrics Service exists: ClusterIP

-- Kafka --
  PASS  Kafka StatefulSet ready replicas: 3
  PASS  kafka-headless Service exists: None
  PASS  Kafka PVCs bound (expect 3): 3

-- api / frontend --
  PASS  api Deployment ready: 2/2
  PASS  api Service exists: ClusterIP
  PASS  frontend Deployment ready: 1/1
  PASS  frontend Service exists: ClusterIP

-- Config/secrets/routing --
  PASS  grid-meter-config ConfigMap exists: grid-meter-config
  PASS  grid-meter-secrets Secret exists: grid-meter-secrets
  PASS  IngressRoute exists: grid-meter
  PASS  managed-csi-xfs StorageClass is default: true

-- Observability (optional; only checked if deployed via k8s/deploy-observability.sh) --
  PASS  kube-prometheus-stack-grafana Deployment ready: 1/1
  PASS  Prometheus StatefulSet ready replicas: 1
  PASS  Loki Deployment ready: 1/1
  PASS  Tempo Deployment ready: 1/1
  PASS  Alloy Deployment ready: 1/1
  PASS  grid-meter-api ServiceMonitor exists: grid-meter-api

== Summary: 21 passed, 0 failed ==
All expected Kubernetes-deployed resources confirmed present and healthy.
tim@Timothys-MacBook-Air grid-meter-app % 

tim@Timothys-MacBook-Air grid-meter-app % ./k8s/teardown-azure.sh 
Using Azure resource group 'grid-meter-app-rg' (node resource group: 'MC_grid-meter-app-rg_grid-meter-app-aks_centralus')
== Confirming kubectl is pointed at the right cluster ==
Current context: grid-meter-app-aks
Proceed with teardown against this context? [y/N] y

== Step 1: scale 'api' to 0, releasing its live Postgres connections before terraform destroy ever attempts DROP DATABASE ==
deployment.apps/api scaled
Waiting for 'api' pods to fully terminate (releases their Postgres connections) ...
pod/api-55795c5fdf-kzwbw condition met
pod/api-55795c5fdf-wb2fq condition met
Confirmed: 'api' pods terminated.

== Step 2: delete the LoadBalancer Service, wait for the real Azure Load Balancer/Public IP to actually disappear ==
Found public IP for 4.150.160.117: kubernetes-a5901fa6b0007494cbe63177ae769dc1
service "traefik-web" deleted from default namespace
Waiting for Azure to actually delete it (polling, not a fixed sleep) ...
Confirmed: public IP for 4.150.160.117 is gone.

== Step 3: stop Kafka (releases its volumes), then delete the PVCs, then wait for the real Managed Disks to actually disappear ==
Found Azure Disks backing current PVs (by resource ID): /subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/MC_grid-meter-app-rg_grid-meter-app-aks_centralus/providers/Microsoft.Compute/disks/pvc-080060e7-b84b-45ab-9de0-911a47be5e73 /subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/MC_grid-meter-app-rg_grid-meter-app-aks_centralus/providers/Microsoft.Compute/disks/pvc-359e1bdf-783b-47dd-a7e3-bf450575a7c1 /subscriptions/3caa5ec0-0d3e-4cd0-98ec-a584c3421a54/resourceGroups/MC_grid-meter-app-rg_grid-meter-app-aks_centralus/providers/Microsoft.Compute/disks/pvc-8968b3ac-a06a-4a2b-97e5-8d0c1c61421d
statefulset.apps "kafka" deleted from default namespace
Waiting for Kafka pods to fully terminate (releases the volumes) ...
pod/kafka-0 condition met
pod/kafka-1 condition met
pod/kafka-2 condition met
No resources found
Waiting for Azure to actually delete the disks (polling, not a fixed sleep) ...
Confirmed: all Azure Disks are gone.

== Step 4: tear down the observability follow-up slice (kube-prometheus-stack + Loki/Tempo/Alloy), if deployed ==
release "kube-prometheus-stack" uninstalled
servicemonitor.monitoring.coreos.com "grid-meter-api" deleted from default namespace
serviceaccount "alloy" deleted from default namespace
clusterrole.rbac.authorization.k8s.io "alloy" deleted
clusterrolebinding.rbac.authorization.k8s.io "alloy" deleted
deployment.apps "alloy" deleted from default namespace
deployment.apps "tempo" deleted from default namespace
service "tempo" deleted from default namespace
deployment.apps "loki" deleted from default namespace
service "loki" deleted from default namespace
configmap "grid-meter-grafana-alerting" deleted from default namespace
configmap "grid-meter-grafana-dashboard" deleted from default namespace
configmap "grid-meter-tempo-config" deleted from default namespace
configmap "grid-meter-alloy-config" deleted from default namespace
Confirmed: observability follow-up slice removed.

== Kubernetes-provisioned Azure resources cleared. Now run: ==
    cd /Users/tim/Documents/workspace/java/apps/grid-meter-app/terraform/azure
    terraform plan -destroy
    terraform destroy

(Deliberately not run automatically from this script - real, hard-to-reverse infrastructure
 teardown should be a deliberate, reviewed step, not chained onto a kubectl cleanup script.)
tim@Timothys-MacBook-Air grid-meter-app % ./k8s/check-resources-azure.sh 
== Checking Kubernetes-deployed app layer (context: grid-meter-app-aks) ==

-- Traefik --
  PASS  Traefik Deployment ready: 1/1
  FAIL  traefik-web Service type: not found / error - Error from server (NotFound): services "traefik-web" not found
  FAIL  traefik-web external IP assigned: not found / error - Error from server (NotFound): services "traefik-web" not found
  PASS  traefik-metrics Service exists: ClusterIP

-- Kafka --
  FAIL  Kafka StatefulSet ready replicas: not found / error - Error from server (NotFound): statefulsets.apps "kafka" not found
  PASS  kafka-headless Service exists: None
  FAIL  Kafka PVCs bound (expect 3): expected '3', got '0'

-- api / frontend --
  FAIL  api Deployment ready: expected '2/2', got '/0'
  PASS  api Service exists: ClusterIP
  PASS  frontend Deployment ready: 1/1
  PASS  frontend Service exists: ClusterIP

-- Config/secrets/routing --
  PASS  grid-meter-config ConfigMap exists: grid-meter-config
  PASS  grid-meter-secrets Secret exists: grid-meter-secrets
  PASS  IngressRoute exists: grid-meter
  PASS  managed-csi-xfs StorageClass is default: true

-- Observability (optional; only checked if deployed via k8s/deploy-observability.sh) --
  (not deployed - skipping; run k8s/deploy-observability.sh first if this cluster should have it)

== Summary: 10 passed, 5 failed ==
One or more expected Kubernetes objects are missing or unhealthy - investigate before demoing.
tim@Timothys-MacBook-Air grid-meter-app % kubectl get nodes -A
NAME                             STATUS   ROLES    AGE   VERSION
aks-system-26917399-vmss000000   Ready    <none>   41m   v1.35.7
aks-system-26917399-vmss000001   Ready    <none>   41m   v1.35.7
tim@Timothys-MacBook-Air grid-meter-app % kubectl get pods -A 
NAMESPACE     NAME                                                   READY   STATUS    RESTARTS   AGE
default       frontend-56b7d965cd-xt2bz                              1/1     Running   0          29m
default       traefik-7b75595b65-cbx4w                               1/1     Running   0          29m
kube-system   azure-cns-4gng7                                        2/2     Running   0          41m
kube-system   azure-cns-8zmqm                                        2/2     Running   0          41m
kube-system   azure-ip-masq-agent-txfbg                              1/1     Running   0          41m
kube-system   azure-ip-masq-agent-x9m52                              1/1     Running   0          41m
kube-system   azure-npm-8flqp                                        1/1     Running   0          41m
kube-system   azure-npm-vrq66                                        1/1     Running   0          41m
kube-system   azure-wi-webhook-controller-manager-5bcdc6f8bf-98zkp   1/1     Running   0          41m
kube-system   azure-wi-webhook-controller-manager-5bcdc6f8bf-9swt4   1/1     Running   0          41m
kube-system   cloud-node-manager-8w8dh                               1/1     Running   0          41m
kube-system   cloud-node-manager-d5t94                               1/1     Running   0          41m
kube-system   coredns-5d474ff6db-hj4nh                               1/1     Running   0          41m
kube-system   coredns-5d474ff6db-ssmbk                               1/1     Running   0          40m
kube-system   coredns-autoscaler-6769f8f9b-cf9fh                     1/1     Running   0          41m
kube-system   csi-azuredisk-node-85vgs                               3/3     Running   0          41m
kube-system   csi-azuredisk-node-x7fwd                               3/3     Running   0          41m
kube-system   csi-azurefile-node-l5dnp                               4/4     Running   0          41m
kube-system   csi-azurefile-node-xzhfj                               4/4     Running   0          41m
kube-system   konnectivity-agent-847db89cc4-5mcj2                    1/1     Running   0          14m
kube-system   konnectivity-agent-847db89cc4-n5qqc                    1/1     Running   0          14m
kube-system   konnectivity-agent-autoscaler-57c596c6fd-l97b8         1/1     Running   0          41m
kube-system   kube-proxy-84mwm                                       1/1     Running   0          41m
kube-system   kube-proxy-spvvb                                       1/1     Running   0          41m
kube-system   metrics-server-85768b658b-8d4pz                        2/2     Running   0          40m
kube-system   metrics-server-85768b658b-zrkh5                        2/2     Running   0          40m
tim@Timothys-MacBook-Air grid-meter-app % kubectl top nodes
NAME                             CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
aks-system-26917399-vmss000000   124m         6%       2459Mi          42%         
aks-system-26917399-vmss000001   79m          4%       2085Mi          36%         
tim@Timothys-MacBook-Air grid-meter-app % kubectl top pods 
NAME                        CPU(cores)   MEMORY(bytes)   
frontend-56b7d965cd-xt2bz   0m           3Mi             
traefik-7b75595b65-cbx4w    1m           65Mi            
tim@Timothys-MacBook-Air grid-meter-app % kubectl top pods -A
NAMESPACE     NAME                                                   CPU(cores)   MEMORY(bytes)   
default       frontend-56b7d965cd-xt2bz                              0m           3Mi             
default       traefik-7b75595b65-cbx4w                               1m           65Mi            
kube-system   azure-cns-4gng7                                        2m           89Mi            
kube-system   azure-cns-8zmqm                                        2m           89Mi            
kube-system   azure-ip-masq-agent-txfbg                              1m           38Mi            
kube-system   azure-ip-masq-agent-x9m52                              1m           38Mi            
kube-system   azure-npm-8flqp                                        2m           46Mi            
kube-system   azure-npm-vrq66                                        2m           17Mi            
kube-system   azure-wi-webhook-controller-manager-5bcdc6f8bf-98zkp   2m           15Mi            
kube-system   azure-wi-webhook-controller-manager-5bcdc6f8bf-9swt4   2m           13Mi            
kube-system   cloud-node-manager-8w8dh                               1m           98Mi            
kube-system   cloud-node-manager-d5t94                               1m           98Mi            
kube-system   coredns-5d474ff6db-hj4nh                               2m           102Mi           
kube-system   coredns-5d474ff6db-ssmbk                               2m           101Mi           
kube-system   coredns-autoscaler-6769f8f9b-cf9fh                     1m           22Mi            
kube-system   csi-azuredisk-node-85vgs                               1m           32Mi            
kube-system   csi-azuredisk-node-x7fwd                               1m           26Mi            
kube-system   csi-azurefile-node-l5dnp                               2m           142Mi           
kube-system   csi-azurefile-node-xzhfj                               3m           137Mi           
kube-system   konnectivity-agent-847db89cc4-5mcj2                    3m           15Mi            
kube-system   konnectivity-agent-847db89cc4-n5qqc                    3m           39Mi            
kube-system   konnectivity-agent-autoscaler-57c596c6fd-l97b8         1m           8Mi             
kube-system   kube-proxy-84mwm                                       1m           20Mi            
kube-system   kube-proxy-spvvb                                       1m           21Mi            
kube-system   metrics-server-85768b658b-8d4pz                        2m           28Mi            
kube-system   metrics-server-85768b658b-zrkh5                        2m           28Mi            
tim@Timothys-MacBook-Air grid-meter-app % 

