tim@Timothys-MacBook-Air grid-meter-app % ./k8s/deploy-gcp.sh
== Reading Terraform outputs ==
== Fetching kubeconfig for grid-meter-app-gke ==
Fetching cluster endpoint and auth data.
kubeconfig entry generated for grid-meter-app-gke.
== Authenticating Docker to Artifact Registry ==
WARNING: Your config file at [/Users/tim/.docker/config.json] contains these credential helper entries:

{
  "credHelpers": {
    "us-central1-docker.pkg.dev": "gcloud"
  }
}
Adding credentials for: us-central1-docker.pkg.dev
gcloud credential helpers already registered correctly.
== Building + pushing images (tag: latest, platform: linux/amd64) ==
[+] Building 166.1s (16/16) FINISHED                                                                                   docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                   0.0s
 => => transferring dockerfile: 373B                                                                                                   0.0s
 => [internal] load metadata for docker.io/library/eclipse-temurin:25-jre-alpine                                                       0.0s
 => [internal] load metadata for docker.io/library/maven:3.9-eclipse-temurin-25                                                        0.0s
 => [internal] load .dockerignore                                                                                                      0.0s
 => => transferring context: 2B                                                                                                        0.0s
 => [build 1/6] FROM docker.io/library/maven:3.9-eclipse-temurin-25@sha256:d67198007bb4441b07d45587320f83154de80ece3608f80408ef14c6ea  0.0s
 => => resolve docker.io/library/maven:3.9-eclipse-temurin-25@sha256:d67198007bb4441b07d45587320f83154de80ece3608f80408ef14c6ea847753  0.0s
 => [internal] load build context                                                                                                      0.0s
 => => transferring context: 62.57kB                                                                                                   0.0s
 => [stage-1 1/3] FROM docker.io/library/eclipse-temurin:25-jre-alpine@sha256:3137541deb3cac6626b5d9a4a2187bc0d6a34312f858bd2c67dd01e  0.0s
 => => resolve docker.io/library/eclipse-temurin:25-jre-alpine@sha256:3137541deb3cac6626b5d9a4a2187bc0d6a34312f858bd2c67dd01e732e6b68  0.0s
 => CACHED [build 2/6] WORKDIR /build                                                                                                  0.0s
 => [build 3/6] COPY pom.xml .                                                                                                         0.0s
 => [build 4/6] RUN mvn dependency:go-offline                                                                                        137.3s
 => [build 5/6] COPY src ./src                                                                                                         0.0s 
 => [build 6/6] RUN mvn package -DskipTests                                                                                           14.5s 
 => CACHED [stage-1 2/3] WORKDIR /app                                                                                                  0.0s 
 => [stage-1 3/3] COPY --from=build /build/target/*.jar app.jar                                                                        0.1s 
 => exporting to image                                                                                                                13.7s 
 => => exporting layers                                                                                                                2.2s 
 => => exporting manifest sha256:3bd4bf4dbc005e4c9efcafc2415a998860e8f25acae2eb53cd0133197e94dfdc                                      0.0s 
 => => exporting config sha256:8c142caade03a737b7fe7e10f6b7bbc111f66981ce58597ebbc918e0695777f7                                        0.0s
 => => naming to us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api/api:latest                               0.0s
 => => pushing layers                                                                                                                 11.0s
 => => pushing manifest for us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api/api:latest@sha256:3bd4bf4dbc  0.5s
 => [auth] project-4c5a8821-da4c-4c68-97f/grid-meter-app-api/api:pull,push token for us-central1-docker.pkg.dev                        0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/zr5wpoyrmvjtqtve7y7dcfjcm
[+] Building 3.0s (16/16) FINISHED                                                                                     docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                   0.0s
 => => transferring dockerfile: 337B                                                                                                   0.0s
 => [internal] load metadata for docker.io/library/nginx:1.27-alpine                                                                   0.0s
 => [internal] load metadata for docker.io/library/node:24-alpine                                                                      0.0s
 => [internal] load .dockerignore                                                                                                      0.0s
 => => transferring context: 2B                                                                                                        0.0s
 => [build 1/6] FROM docker.io/library/node:24-alpine@sha256:e67514e5d0f6c46656005e1b693b2ec9d52e80b641307de684d4a015ba7a4eaf          0.0s
 => => resolve docker.io/library/node:24-alpine@sha256:e67514e5d0f6c46656005e1b693b2ec9d52e80b641307de684d4a015ba7a4eaf                0.0s
 => [stage-1 1/3] FROM docker.io/library/nginx:1.27-alpine@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10     0.0s
 => => resolve docker.io/library/nginx:1.27-alpine@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10             0.0s
 => [internal] load build context                                                                                                      1.2s
 => => transferring context: 4.04MB                                                                                                    1.0s
 => CACHED [build 2/6] WORKDIR /build                                                                                                  0.0s
 => CACHED [build 3/6] COPY package.json package-lock.json ./                                                                          0.0s
 => CACHED [build 4/6] RUN npm ci                                                                                                      0.0s
 => CACHED [build 5/6] COPY . .                                                                                                        0.0s
 => CACHED [build 6/6] RUN npm run build                                                                                               0.0s
 => CACHED [stage-1 2/3] COPY --from=build /build/dist /usr/share/nginx/html                                                           0.0s
 => CACHED [stage-1 3/3] COPY nginx.conf /etc/nginx/conf.d/default.conf                                                                0.0s
 => exporting to image                                                                                                                 1.8s
 => => exporting layers                                                                                                                0.0s
 => => exporting manifest sha256:84b707d06b573d0b966201213a6a2fe21606bf20a7c7e5f35d3d9c410836a67a                                      0.0s
 => => exporting config sha256:53077f1e6d67a3710e1346f67449392cfbcd71390e725b33c0a1e9039fd46011                                        0.0s
 => => naming to us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend/frontend:latest                     0.0s
 => => pushing layers                                                                                                                  1.7s
 => => pushing manifest for us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend/frontend:latest@sha256:  0.1s
 => [auth] project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend/frontend:pull,push token for us-central1-docker.pkg.dev              0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/e265jlafhhdd7wblh1iomvywu
== Applying Traefik CRDs + RBAC (shared with kind/AWS) ==
customresourcedefinition.apiextensions.k8s.io/ingressroutes.traefik.io unchanged
customresourcedefinition.apiextensions.k8s.io/ingressroutetcps.traefik.io unchanged
customresourcedefinition.apiextensions.k8s.io/ingressrouteudps.traefik.io unchanged
customresourcedefinition.apiextensions.k8s.io/middlewares.traefik.io unchanged
customresourcedefinition.apiextensions.k8s.io/middlewaretcps.traefik.io unchanged
customresourcedefinition.apiextensions.k8s.io/serverstransports.traefik.io unchanged
customresourcedefinition.apiextensions.k8s.io/serverstransporttcps.traefik.io unchanged
customresourcedefinition.apiextensions.k8s.io/tlsoptions.traefik.io unchanged
customresourcedefinition.apiextensions.k8s.io/tlsstores.traefik.io unchanged
customresourcedefinition.apiextensions.k8s.io/traefikservices.traefik.io unchanged
clusterrole.rbac.authorization.k8s.io/traefik-ingress-controller unchanged
clusterrolebinding.rbac.authorization.k8s.io/traefik-ingress-controller unchanged
== Applying Traefik controller (GCP variant - LoadBalancer, not hostPort) ==
serviceaccount/traefik-ingress-controller unchanged
deployment.apps/traefik unchanged
service/traefik-web unchanged
service/traefik-metrics unchanged
== Un-defaulting GKE's own built-in default StorageClass (standard-rwo) ==
storageclass.storage.k8s.io/standard-rwo patched (no change)
== Applying default StorageClass (XFS-formatted, needed for Kafka's PVCs) ==
storageclass.storage.k8s.io/pd-balanced-xfs unchanged
== Fetching the real Cloud SQL password from Secret Manager (never hardcoded) ==
== Generating a fresh JWT signing secret for this deployment ==
== Applying secrets (generated at deploy time, never committed) ==
secret/grid-meter-secrets configured
== Applying config (real Cloud SQL/Memorystore endpoints, generated at deploy time) ==
configmap/grid-meter-config configured
== Applying Kafka (self-hosted in-cluster, unchanged from every other target) ==
service/kafka-headless unchanged
statefulset.apps/kafka configured
== Applying api + frontend (real image + GCP service account email baked in before the first apply, not patched after) ==
serviceaccount/grid-meter-app created
deployment.apps/api configured
service/api unchanged
deployment.apps/frontend unchanged
service/frontend unchanged
== Forcing a rollout restart (picks up a freshly-pushed :latest on a repeat run of this script) ==
deployment.apps/api restarted
deployment.apps/frontend restarted
== Applying IngressRoute (target-agnostic - only references Service names) ==
ingressroute.traefik.io/grid-meter unchanged
== Waiting for rollouts ==
deployment "traefik" successfully rolled out
partitioned roll out complete: 3 new pods have been updated...
Waiting for deployment "api" rollout to finish: 1 out of 2 new replicas have been updated...
error: timed out waiting for the condition
tim@Timothys-MacBook-Air grid-meter-app % ./k8s/check-resources-gcp.sh 
== Checking Kubernetes-deployed app layer (context: gke_project-4c5a8821-da4c-4c68-97f_us-central1-a_grid-meter-app-gke) ==

-- Traefik --
  PASS  Traefik Deployment ready: 1/1
  PASS  traefik-web Service type: LoadBalancer
  PASS  traefik-web external IP assigned: 34.9.29.158
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
  PASS  pd-balanced-xfs StorageClass is default: true

-- Observability (optional; only checked if deployed via k8s/deploy-observability.sh) --
  PASS  kube-prometheus-stack-grafana Deployment ready: 1/1
  PASS  Prometheus StatefulSet ready replicas: 1
  PASS  Loki Deployment ready: 1/1
  PASS  Tempo Deployment ready: 1/1
  PASS  Alloy Deployment ready: 1/1
  PASS  grid-meter-api ServiceMonitor exists: grid-meter-api

== Summary: 21 passed, 0 failed ==
All expected Kubernetes-deployed resources confirmed present and healthy.
tim@Timothys-MacBook-Air grid-meter-app % kubectl get nodes -A -o wide
NAME                                                  STATUS   ROLES    AGE    VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   Ready    <none>   138m   v1.35.8-gke.1036000   10.10.0.5     <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   Ready    <none>   70m    v1.35.8-gke.1036000   10.10.0.11    <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   Ready    <none>   70m    v1.35.8-gke.1036000   10.10.0.10    <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   Ready    <none>   70m    v1.35.8-gke.1036000   10.10.0.9     <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
tim@Timothys-MacBook-Air grid-meter-app % kubectl get pods -A -o wide
NAMESPACE         NAME                                                             READY   STATUS    RESTARTS      AGE     IP           NODE                                                  NOMINATED NODE   READINESS GATES
default           alloy-76bbd8597-j6n9l                                            1/1     Running   0             49m     10.11.3.8    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
default           api-688dbdf56f-sx8tj                                             0/1     Pending   0             7m42s   <none>       <none>                                                <none>           <none>
default           api-cdb86f4c8-8cxl6                                              1/1     Running   0             64m     10.11.1.8    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
default           api-cdb86f4c8-fvbj9                                              1/1     Running   0             65m     10.11.0.17   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
default           frontend-76cf558975-fjgzl                                        1/1     Running   0             7m42s   10.11.0.20   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
default           kafka-0                                                          1/1     Running   0             65m     10.11.3.5    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
default           kafka-1                                                          1/1     Running   0             64m     10.11.1.7    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
default           kafka-2                                                          1/1     Running   0             64m     10.11.2.6    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           kube-prometheus-stack-grafana-6f676576f9-w4bdm                   3/3     Running   0             51m     10.11.2.8    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           kube-prometheus-stack-kube-state-metrics-5c4dd95655-46xzc        1/1     Running   0             51m     10.11.0.18   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
default           kube-prometheus-stack-operator-5f8985d899-bzb4j                  1/1     Running   0             51m     10.11.2.7    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           kube-prometheus-stack-prometheus-node-exporter-hw5tf             1/1     Running   0             51m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           kube-prometheus-stack-prometheus-node-exporter-m98p6             1/1     Running   0             51m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
default           kube-prometheus-stack-prometheus-node-exporter-pt2wd             1/1     Running   0             51m     10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
default           kube-prometheus-stack-prometheus-node-exporter-tmzj4             1/1     Running   0             51m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
default           loki-8574bfc78d-jnxhq                                            1/1     Running   0             49m     10.11.0.19   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
default           prometheus-kube-prometheus-stack-prometheus-0                    2/2     Running   0             51m     10.11.3.7    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
default           tempo-6cc5f67c89-b67rt                                           1/1     Running   1 (19m ago)   49m     10.11.2.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           traefik-7b75595b65-dx5zn                                         1/1     Running   0             65m     10.11.1.4    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
gke-managed-cim   kube-state-metrics-0                                             2/2     Running   0             143m    10.11.0.7    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
gmp-system        collector-5k2p4                                                  2/2     Running   0             70m     10.11.3.3    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
gmp-system        collector-gl4xc                                                  2/2     Running   0             70m     10.11.2.3    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
gmp-system        collector-j2d5b                                                  2/2     Running   0             138m    10.11.0.12   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
gmp-system        collector-qj8zb                                                  2/2     Running   0             70m     10.11.1.2    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
gmp-system        gmp-operator-7b55ccf99-fws95                                     1/1     Running   0             130m    10.11.0.13   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       event-exporter-gke-995cd68c5-6ppvk                               2/2     Running   0             143m    10.11.0.2    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       fluentbit-gke-kfdks                                              3/3     Running   0             70m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       fluentbit-gke-p46lf                                              3/3     Running   0             138m    10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       fluentbit-gke-xbnch                                              3/3     Running   0             70m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       fluentbit-gke-zlfvh                                              3/3     Running   0             70m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       gke-metadata-server-k8bhb                                        1/1     Running   0             138m    10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       gke-metadata-server-nj9g7                                        1/1     Running   0             70m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       gke-metadata-server-s96q7                                        1/1     Running   0             70m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       gke-metadata-server-vfd74                                        1/1     Running   0             70m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       gke-metrics-agent-44g4q                                          3/3     Running   0             70m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       gke-metrics-agent-c9p5m                                          3/3     Running   0             70m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       gke-metrics-agent-g9v74                                          3/3     Running   0             138m    10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       gke-metrics-agent-m5gjm                                          3/3     Running   0             70m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       konnectivity-agent-84dfd5c9fd-44dqs                              2/2     Running   0             70m     10.11.3.2    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       konnectivity-agent-84dfd5c9fd-4mbrt                              2/2     Running   0             143m    10.11.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       konnectivity-agent-84dfd5c9fd-hcfv2                              2/2     Running   0             70m     10.11.2.4    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       konnectivity-agent-84dfd5c9fd-mn9fj                              2/2     Running   0             70m     10.11.1.3    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       konnectivity-agent-autoscaler-7f44b76cdc-w28nd                   1/1     Running   0             143m    10.11.0.3    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       kube-dns-5954f9f47-fs2d6                                         4/4     Running   0             70m     10.11.2.2    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       kube-dns-5954f9f47-v7f6l                                         4/4     Running   0             143m    10.11.0.10   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       kube-dns-autoscaler-859854db85-t5tf8                             1/1     Running   0             143m    10.11.0.6    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   1/1     Running   0             138m    10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   1/1     Running   0             70m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   1/1     Running   0             70m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   1/1     Running   0             70m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       l7-default-backend-7d8d77ff56-52qmt                              1/1     Running   0             143m    10.11.0.9    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       metrics-server-v1.35.1-7cdd96f59b-7rf62                          1/1     Running   0             143m    10.11.0.11   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       netd-7jtgg                                                       3/3     Running   0             70m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       netd-j82ml                                                       3/3     Running   0             70m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       netd-qwd7c                                                       3/3     Running   0             70m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       netd-skhcz                                                       3/3     Running   0             138m    10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       node-local-dns-8bfqp                                             2/2     Running   0             70m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       node-local-dns-f4vgm                                             2/2     Running   0             138m    10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       node-local-dns-g8mn5                                             2/2     Running   0             70m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       node-local-dns-zsvp5                                             2/2     Running   0             70m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       pdcsi-node-j8s8s                                                 3/3     Running   0             70m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       pdcsi-node-lqhrk                                                 3/3     Running   0             70m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       pdcsi-node-rbfx2                                                 3/3     Running   0             138m    10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       pdcsi-node-sctnz                                                 3/3     Running   0             70m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
tim@Timothys-MacBook-Air grid-meter-app % 

tim@Timothys-MacBook-Air grid-meter-app % kubectl top nodes
NAME                                                  CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   319m         33%      2008Mi          71%         
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   250m         26%      2571Mi          91%         
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   214m         22%      2051Mi          73%         
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   223m         23%      2198Mi          78%         
tim@Timothys-MacBook-Air grid-meter-app % kubectl top pods 
NAME                                                        CPU(cores)   MEMORY(bytes)   
alloy-76bbd8597-j6n9l                                       10m          98Mi            
api-688dbdf56f-dsbl9                                        34m          415Mi           
api-688dbdf56f-m4smm                                        49m          369Mi           
frontend-76cf558975-fjgzl                                   0m           2Mi             
kafka-0                                                     29m          611Mi           
kafka-1                                                     33m          634Mi           
kafka-2                                                     30m          586Mi           
kube-prometheus-stack-grafana-6f676576f9-w4bdm              13m          304Mi           
kube-prometheus-stack-kube-state-metrics-5c4dd95655-46xzc   5m           22Mi            
kube-prometheus-stack-operator-5f8985d899-bzb4j             3m           21Mi            
kube-prometheus-stack-prometheus-node-exporter-hw5tf        1m           10Mi            
kube-prometheus-stack-prometheus-node-exporter-m98p6        1m           9Mi             
kube-prometheus-stack-prometheus-node-exporter-pt2wd        2m           11Mi            
kube-prometheus-stack-prometheus-node-exporter-tmzj4        2m           10Mi            
loki-8574bfc78d-jnxhq                                       12m          99Mi            
prometheus-kube-prometheus-stack-prometheus-0               38m          375Mi           
tempo-6cc5f67c89-b67rt                                      6m           33Mi            
traefik-7b75595b65-dx5zn                                    1m           24Mi            
tim@Timothys-MacBook-Air grid-meter-app % 

tim@Timothys-MacBook-Air grid-meter-app % ./k8s/teardown-gcp.sh 
Using GCP project 'project-4c5a8821-da4c-4c68-97f' in region 'us-central1'
== Confirming kubectl is pointed at the right cluster ==
Current context: gke_project-4c5a8821-da4c-4c68-97f_us-central1-a_grid-meter-app-gke
Proceed with teardown against this context? [y/N] y

== Step 1: scale 'api' to 0, releasing its live Cloud SQL connections before terraform destroy ever attempts DROP DATABASE ==
deployment.apps/api scaled
Waiting for 'api' pods to fully terminate (releases their Cloud SQL connections) ...
pod/api-f55996f5b-48s8b condition met
pod/api-f55996f5b-t8whn condition met
Confirmed: 'api' pods terminated.

== Step 2: delete the LoadBalancer Service, wait for the real GCP forwarding rule to actually disappear ==
Found forwarding rule for 34.9.29.158: a69a7bb82fbe645ae820fc4d1bc59f14
service "traefik-web" deleted from default namespace
Waiting for GCP to actually delete it (polling, not a fixed sleep) ...
Confirmed: forwarding rule for 34.9.29.158 is gone.

== Step 3: stop Kafka (releases its volumes), then delete the PVCs, then wait for the real persistent disks to actually disappear ==
Found persistent disks backing current PVs: projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/disks/pvc-0c63ff3f-c2ad-4c96-b028-667e33bdf618 projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/disks/pvc-1030f569-0777-4417-a6a8-56ea96872221 projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/disks/pvc-dfede204-bef5-4780-9c73-864f0462243b
statefulset.apps "kafka" deleted from default namespace
Waiting for Kafka pods to fully terminate (releases the volumes) ...
pod/kafka-0 condition met
pod/kafka-1 condition met
pod/kafka-2 condition met
No resources found
Waiting for GCP to actually delete the persistent disks (polling, not a fixed sleep) ...
Confirmed: all persistent disks are gone.

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

== Kubernetes-provisioned GCP resources cleared. Now run: ==
    cd /Users/tim/Documents/workspace/java/apps/grid-meter-app/terraform/gcp
    terraform plan -destroy
    terraform destroy

(Deliberately not run automatically from this script - real, hard-to-reverse infrastructure
 teardown should be a deliberate, reviewed step, not chained onto a kubectl cleanup script.)
tim@Timothys-MacBook-Air grid-meter-app % ./k8s/check-resources-gcp.sh 
== Checking Kubernetes-deployed app layer (context: gke_project-4c5a8821-da4c-4c68-97f_us-central1-a_grid-meter-app-gke) ==

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
  PASS  pd-balanced-xfs StorageClass is default: true

-- Observability (optional; only checked if deployed via k8s/deploy-observability.sh) --
  (not deployed - skipping; run k8s/deploy-observability.sh first if this cluster should have it)

== Summary: 10 passed, 5 failed ==
One or more expected Kubernetes objects are missing or unhealthy - investigate before demoing.
tim@Timothys-MacBook-Air grid-meter-app % kubectl get nodes -A -o wide
NAME                                                  STATUS   ROLES    AGE     VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   Ready    <none>   3h26m   v1.35.8-gke.1036000   10.10.0.5     <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   Ready    <none>   138m    v1.35.8-gke.1036000   10.10.0.11    <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   Ready    <none>   138m    v1.35.8-gke.1036000   10.10.0.10    <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   Ready    <none>   138m    v1.35.8-gke.1036000   10.10.0.9     <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
tim@Timothys-MacBook-Air grid-meter-app % kubectl get pods -A         
NAMESPACE         NAME                                                             READY   STATUS    RESTARTS   AGE
default           frontend-8546f95dd7-m2z2f                                        1/1     Running   0          48m
default           traefik-7b75595b65-dx5zn                                         1/1     Running   0          133m
gke-managed-cim   kube-state-metrics-0                                             2/2     Running   0          3h31m
gmp-system        collector-5k2p4                                                  2/2     Running   0          138m
gmp-system        collector-gl4xc                                                  2/2     Running   0          138m
gmp-system        collector-j2d5b                                                  2/2     Running   0          3h26m
gmp-system        collector-qj8zb                                                  2/2     Running   0          138m
gmp-system        gmp-operator-7b55ccf99-fws95                                     1/1     Running   0          3h18m
kube-system       event-exporter-gke-995cd68c5-6ppvk                               2/2     Running   0          3h31m
kube-system       fluentbit-gke-kfdks                                              3/3     Running   0          138m
kube-system       fluentbit-gke-p46lf                                              3/3     Running   0          3h26m
kube-system       fluentbit-gke-xbnch                                              3/3     Running   0          138m
kube-system       fluentbit-gke-zlfvh                                              3/3     Running   0          138m
kube-system       gke-metadata-server-k8bhb                                        1/1     Running   0          3h26m
kube-system       gke-metadata-server-nj9g7                                        1/1     Running   0          138m
kube-system       gke-metadata-server-s96q7                                        1/1     Running   0          138m
kube-system       gke-metadata-server-vfd74                                        1/1     Running   0          138m
kube-system       gke-metrics-agent-44g4q                                          3/3     Running   0          138m
kube-system       gke-metrics-agent-c9p5m                                          3/3     Running   0          138m
kube-system       gke-metrics-agent-g9v74                                          3/3     Running   0          3h26m
kube-system       gke-metrics-agent-m5gjm                                          3/3     Running   0          138m
kube-system       konnectivity-agent-84dfd5c9fd-44dqs                              2/2     Running   0          138m
kube-system       konnectivity-agent-84dfd5c9fd-4mbrt                              2/2     Running   0          3h31m
kube-system       konnectivity-agent-84dfd5c9fd-hcfv2                              2/2     Running   0          138m
kube-system       konnectivity-agent-84dfd5c9fd-mn9fj                              2/2     Running   0          138m
kube-system       konnectivity-agent-autoscaler-7f44b76cdc-w28nd                   1/1     Running   0          3h31m
kube-system       kube-dns-5954f9f47-fs2d6                                         4/4     Running   0          138m
kube-system       kube-dns-5954f9f47-v7f6l                                         4/4     Running   0          3h31m
kube-system       kube-dns-autoscaler-859854db85-t5tf8                             1/1     Running   0          3h31m
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   1/1     Running   0          3h26m
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   1/1     Running   0          138m
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   1/1     Running   0          138m
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   1/1     Running   0          138m
kube-system       l7-default-backend-7d8d77ff56-52qmt                              1/1     Running   0          3h31m
kube-system       metrics-server-v1.35.1-7cdd96f59b-7rf62                          1/1     Running   0          3h31m
kube-system       netd-7jtgg                                                       3/3     Running   0          138m
kube-system       netd-j82ml                                                       3/3     Running   0          138m
kube-system       netd-qwd7c                                                       3/3     Running   0          138m
kube-system       netd-skhcz                                                       3/3     Running   0          3h26m
kube-system       node-local-dns-8bfqp                                             2/2     Running   0          138m
kube-system       node-local-dns-f4vgm                                             2/2     Running   0          3h26m
kube-system       node-local-dns-g8mn5                                             2/2     Running   0          138m
kube-system       node-local-dns-zsvp5                                             2/2     Running   0          138m
kube-system       pdcsi-node-j8s8s                                                 3/3     Running   0          138m
kube-system       pdcsi-node-lqhrk                                                 3/3     Running   0          138m
kube-system       pdcsi-node-rbfx2                                                 3/3     Running   0          3h26m
kube-system       pdcsi-node-sctnz                                                 3/3     Running   0          138m
tim@Timothys-MacBook-Air grid-meter-app %              


