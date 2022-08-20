##############
#CORE CONCEPTS
##############
- Create Pod 
kubectl  run nginx --image=nginx  --dry-run -n mynamespace -o yaml > pod.yaml

- Create busybox pod, run command and delete
kubectl  run busybox --image=busybox --restart=Never --command  -it --rm=True  -- en
kubectl  run busybox --image=busybox --command --rm -it --restart=Never  -- echo "hello world"

- Create a busybox pod (using YAML) that runs the command "env". Run it and see the output
kubectl  run busybox --image=busybox --restart=Never --dry-run --command -o yaml   -- env  > create_pod_run_command.yaml

- Get the YAML for a new ResourceQuota called 'myrq' with hard limits of 1 CPU, 1G memory and 2 pods without creating it
kubectl create quota myResourceQuota --hard=cpu=1,memory=1G,pods=2 --dry-run -o yaml  > myResourceQuota.yaml

- Start a single instance and let the container expose port 80
kubectl run  nginx --image=nginx --restart=Never --port=80

- Change pod's image to nginx:1.7.1
Eg: kubectl set image POD/POD_NAME CONTAINER_NAME=IMAGE_NAME:TAG
kubectl set image pod/nginx nginx=nginx:1.7.1

- Get nginx POD IP, use a temp busybox to wget its "/"
NGINX_POD_IP = `kubectl  get pod nginx  -o jsonpath='{.status.podIP}'`
kubectl run busybox --image=busybox --env="NGINX_IP=$NGINX_IP" --rm -it --restart=Never -- sh -c 'wget -O- $NGINX_IP:80'

Or : kubectl run busybox --image=busybox --rm -it --restart=Never -- wget -O- $(kubectl get pod nginx -o jsonpath='{.status.podIP}:{.spec.containers[0].ports[0].containerPort}')

- Using Environment
kubectl  run  nginx-new --image=nginx --restart=Never --env="var1=val1" --command -it --rm -- env|grep var1


#####################
#Multi-container Pods
#####################
- Create a Pod with two containers, both with image busybox and command "echo hello; sleep 3600"
kubectl run busybox --image=busybox --dry-run -o yaml -- /bin/sh  -c 'echo hello;sleep 3600' > create_pod_with_2_containers.yaml
- check on container: 
kubectl exec -it pod/busybox-79db556896-d6bpk -c busybox-one -- /bin/sh

- Create a pod with an nginx container exposed on port 80. Add a busybox init container which downloads a page using "wget -O /work-dir/index.html http://neverssl.com/online". Make a volume of type emptyDir and mount it in both containers. For the nginx container, mount it on "/usr/share/nginx/html" and for the initcontainer, mount it on "/work-dir"
kubectl run nginx-multicontainer --image=nginx --dry-run --port=80 -o yaml > init-pod.yaml
#edit yaml file

      initContainers:
      - name: init-nginx-web
        image: busybox
        command: ['sh', '-c', 'wget -O /work-dir/index.html http://neverssl.com/online']
        volumeMounts:
        - name: web-storage
          mountPath: /work-dir
      volumes:
      - name: web-storage
        emptyDir: {}

================
POD Design
================
-Create 3 pods with names nginx1,nginx2,nginx3. All of them should have the label app=v1
kubectl run nginx1 --image=nginx --dry-run --labels="app=v1" -o yaml  > Create_3_Pod.yaml

- Change the labels of Pod to app=v2
kubectl label po nginx2 app=v2 --overwrite

- Get all Pod that have label "app"
kubectl get po -L (--label-columns) app -o wide

- Get only the  "app=v2" pods
kubectl get po -l (--selector) app=v2

- Add a new label to all pods having  app=v2 or app=v1 labels
kubectl  label po tier1=web1 -l "app in (v1,v2,v3)"

- Remove a label
kubectl label po PONAME app-

- Remove a label on all Po
kubectl  label po  -l app app-

- Add an annotation
kubectl annotate po PONAME owner=marketing

- Remove an annotation
kubectl  annotate po PONAME app-

- Create a pod that will be deployed to a Node that has the label 'accelerator=nvidia-tesla-p100'
#nodeName: foo-node
kubectl label node k8s-test-3   accelerator=nvidia-tesla-p100

===========
Deployment

- Create a deployment  with image nginx:1.18.0, define port 80 as the port container exposes

kubectl create deploy nginx --image=nginx:1.18.0  --dry-run -o yaml  > deploy_create.yaml
        ports:
        - containerPort: 80

- Update Image Version
3 ways:
  + edit Yaml ->  apply
  + kubectl set deploy nginx nginx=nginx:1.19.8
  + kubectl edit deploy nginx

- Check how the deployment rollout is going
kubectl rollout status deploy nginx

- Show rollout history
kubectl rollout history deploy nginx

- View detail of history revision 3
kubectl rollout history deploy nginx --revision=3

- rollout back to specified version
kubectl  rollout undo deploy nginx --to-revision=3

- Pause/resume the rollout of the deployment
kubectl rollout pause/resume deploy nginx

- Scale the deployment to 5 replicas
kubectl scale deploy nginx --replicas=5

- Autoscale the deployment, pods between 5 and 10, targetting CPU utilization at 80%
kubectl  autoscale deployment nginx --min=5 --max=10 --cpu-percent=80
kubectl get hpa  (Horizonal Pod Autoscaling - auto update a workload resource)
kubectl delete hpa nginx

- Implement canary deployment by running two instances of nginx marked as version=v1 and version=v2 so that the load is balanced at 75%-25% ratio
kubectl create service clusterip svc-app-nginx  --tcp=80:80 --dry-run  -o yaml

===========
Jobs
===========
- Create a job named pi with image perl that runs the command with arguments "perl -Mbignum=bpi -wle 'print bpi(2000)'"
kubectl create job pi  --image=perl:5.34 -- perl -Mbignum=bpi -wle 'print bpi(2000)'

kubectl get/logs/describe/delete jobs

- Create the same job, make it run 5 times, one after the other
kubectl create job busybox --image=busybox --dry-run=client -o yaml -- /bin/sh -c 'echo hello;sleep 30;echo world' > job.yaml
spec:
  completions: 5 # add this line

- Create the same job, but make it run 5 parallel times
spec:
  parallelism: 5 # add this line

  

###################
# ConfigMaps
###################
kubectl create cm mconfigmap --from-literal=foo=lala
kubectl  describe  cm mconfigmap

kubectl  create cm file-configmap --from-file=config.txt

# Create a new configmap named my-config from an env file
kubectl create configmap my-config --from-env-file=path/to/bar.env

# Create a new configmap named my-config with specified keys instead of file basenames on disk
kubectl create configmap my-config --from-file=key1=/path/to/bar/file1.txt --from-file=key2=/path/to/bar/file2.txt


- Create a configMap called 'options' with the value var5=val5. Create a new nginx pod that loads the value from variable 'var5' in an env variable called 'option'
kubectl run  nginx --image=nginx --restart=Never --dry-run -o yaml  > create_pod_with_cm.yaml
    env:
    - name: option # name of the env variable
      valueFrom:
        configMapKeyRef:
          name: options # name of config map
          key: var5 # name of the entity in config map

- Create a configMap 'cmvolume' with values 'var8=val8', 'var9=val9'. Load this as a volume inside an nginx pod on path '/etc/lala'. Create the pod and 'ls' into the '/etc/lala' directory.
kubectl run nginx --image=nginx --restart=Never -o yaml --dry-run=client > pod.yaml
  volumes: # add a volumes list
  - name: myvolume # just a name, you will reference this in the pods
spec:
  volumes:
    configMap:
      name: cmvolume # name of your configmap

    volumeMounts: # your volume mounts are listed here
    - name: myvolume # the name that you specified in pod.spec.volumes.name
      mountPath: /etc/lala # the path inside your container


- Create the YAML for an nginx pod that runs with the user ID 101.
spec:
  securityContext:
    runAsUser: 101

- Create the YAML for an nginx pod that has the capabilities "NET_ADMIN", "SYS_TIME" added to its single container

==========
Secret
==========
- Create a secret called mysecret with the values password=mypass
kubectl  create secret generic mysecret --from-literal=password=mypass --dry-run -o yaml > secret_create.yaml

- Create a secret called mysecret2 that gets key/value from a file
kubectl create secret generic mysecret2  --from-file=username  --dry-run -o yaml

- Get secret
kubectl get secret mysecret2 -o yaml
Or: kubectl get secret mysecret2 -o jsonpath='{.data.username}' | base64 -d  # on MAC it is -D
Or: kubectl get secret mysecret2 --template '{{.data.username}}' | base64 -d  # on MAC it is -D
Or: kubectl get secret mysecret2 -o json | jq -r .data.username | base64 -d  # on MAC it is -D

- Create an nginx pod that mounts the secret mysecret2 in a volume on path /etc/foo

kubectl  exec -it nginx -- cat   /etc/foo/username
spec:
  volumes:
  - name: myvol
    secret:
      secretName: mysecret2
      ..
  containers:
    ..
    volumeMounts:
    - name: myvol
      mountPath: /etc/foo           

- Mount the variable 'username' from secret mysecret2 onto a new nginx pod in env variable called 'USERNAME'

kubectl exec -it nginx -- env|grep USERNAME
USERNAME=admin
spec:
  containers:
  ..
        env:
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: mysecret2
          key: username

================
ServiceAccounts
================

- Create a new serviceaccount called 'myuser'
kubectl create sa myuser

- Create an nginx pod that uses 'myuser' as a service account

spec:
  serviceAccount: myuser # we use pod.spec.serviceAccount
Or: 
spec:
  serviceAccountName: myuser # we use pod.spec.serviceAccountName

#Show : kubectl  describe pod nginx-sa
Volumes:
  myuser-token-xkvcp:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  myuser-token-xkvcp
    
#################
#Observability
#################
@Liveness probes - Many applications running for long periods of time eventually transition to broken states, and cannot recover except by being restarted
@Readiness probes - to know when a container is ready to start accepting traffic.
@Startup probes - to know when a container application has started

- Create an nginx pod with a liveness probe that just runs the command 'ls'. Save its YAML in pod.yaml
containers:
....
    livenessProbe: # our probe
      exec: # add this line
        command: # command definition
        - ls # ls command

- Modify the pod.yaml file so that liveness probe starts kicking in after 5 seconds whereas the interval between probes would be 5 seconds
livenessProbe:
    initialDelaySeconds: 5
    periodSeconds: 5
Liveness:       exec [ls /tmp] delay=5s timeout=1s period=5s

- Create an nginx pod (that includes port 80) with an HTTP readinessProbe on path '/' on port 80
containers:
...
    ports:
      - containerPort: 80 # Note: Readiness probes runs on the container during its whole lifecycle. Since nginx exposes 80, containerPort: 80 is not required for readiness to work.
    readinessProbe: # declare the readiness probe
      httpGet: # add this line
        path: / #
        port: 80 #

Readiness:      http-get http://:nginx-port/

- Lots of pods are running in qa,alan,test,production namespaces. All of these pods are configured with liveness probe. Please list all pods whose liveness probe are failed in the format of <namespace>/<pod name> per line
kubectl get events -A |grep -i "Liveness probe failed"
      -> Liveness probe failed: Get http://10.8.8.184:10253/healthz: dial tcp 10.8.8.184:10253: connect: connection refused

================
Logging
================
- Create a busybox pod and checking:
kubectl run busybox --image=busybox --restart=Never -- /bin/sh -c 'i=0; while true; do echo "$i: $(date)"; i=$((i+1)); sleep 1; done'
kubectl logs busybox -f # follow the logs

======================
Services & Networking
======================
Kubernetes ServiceTypes allow you to specify what kind of Service you want. The default is ClusterIP.
Type values and their behaviors are:
*ClusterIP: Exposes the Service on a cluster-internal IP. Choosing this value makes the Service only reachable from within the cluster. This is the default ServiceType.
*NodePort: Exposes the Service on each Node's IP at a static port (the NodePort). A ClusterIP Service, to which the NodePort Service routes, is automatically created. You'll be able to contact the NodePort Service, from outside the cluster, by requesting <NodeIP>:<NodePort>.
*LoadBalancer: Exposes the Service externally using a cloud provider's load balancer. NodePort and ClusterIP Services, to which the external load balancer routes, are automatically created.
*ExternalName: Maps the Service to the contents of the externalName field (e.g. foo.bar.example.com), by returning a CNAME record with its value. No proxying of any kind is set up.
'
- Create a pod with image nginx called nginx and expose its port 80
kubectl  run nginx --image=nginx --restart=Never --port=80  --expose  --dry-run -o yaml

@      --expose=false: If true, a public, external service is created for the container(s) which are run
@      --port='': The port that this container exposes.  If --expose is true, this is also the port used by the service that is created
    ports:
    - containerPort: 80

- Get service''s ClusterIP

IP=$(kubectl get svc nginx --template={{.spec.clusterIP}}) # get the IP (something like 10.108.93.130)
kubectl run busybox --rm --image=busybox -it --restart=Never --env="IP=$IP" -- wget -O- $IP:80 --timeout 2
# Tip: --timeout is optional, but it helps to get answer more quickly when connection fails (in seconds vs minutes)

- Convert the ClusterIP to NodePort for the same service and find the NodePort port.
kubectl edit svc nginx
spec:
  type: NodePort

- Create a deployment called foo using image 'dgkanatsios/simpleapp' (a simple server that returns hostname) and 3 replicas. Label it as 'app=foo'. Declare that containers in this pod will accept traffic on port 8080 (do NOT create a service yet)

kubectl create deploy foo --image=dgkanatsios/simpleapp --port=8080 --replicas=3
kubectl label deployment foo --overwrite app=foo
metadata:
  labels:
    app: foo

containers:
        ports:
        - containerPort: 8080

- Get the pod IPs. Create a temp busybox pod and try hitting them on port 8080
kubectl get po -o wide -l app=foo | awk '{print $6}' | grep -v IP | xargs -L1 -I '{}' kubectl run --rm -ti tmp --restart=Never --image=busybox -- wget -O- http://\{\}:8080
Or: 
kubectl get po -l app=foo -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}' | xargs -L1 -I '{}' kubectl run --rm -ti tmp --restart=Never --image=busybox -- wget -O- http://\{\}:8080

- Create a service that exposes the deployment on port 6262. Verify its existence, check the endpoints
# Create the NetworkPolicy
kubectl create -f policy.yaml

# Check if the Network Policy has been created correctly
# make sure that your cluster ''s network provider supports Network Policy (https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/#before-you-begin)
kubectl run busybox --image=busybox --rm -it --restart=Never -- wget -O- http://nginx:80 --timeout 2                          # This should not work. --timeout is optional here. But it helps to get answer more quickly (in seconds vs minutes)
kubectl run busybox --image=busybox --rm -it --restart=Never --labels=access=granted -- wget -O- http://nginx:80 --timeout 2  # This should be fine

To limit the access to the nginx service so that only Pods with the label access: true can query it, create a NetworkPolicy object as follows:

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: access-nginx
spec:
  podSelector:
    matchLabels:
      app: nginx
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: "true"

########
VOLUME
########
@A persistentVolumeClaim volume is used to mount a PersistentVolume into a Pod. PersistentVolumeClaims are a way for users to "claim" durable storage (such as a GCE PersistentDisk or an iSCSI volume) without knowing the details of the particular cloud environment.

- Use emptyDir()

spec:
  volumes:
  - name: vol
    emptyDir: {}
containers:
    volumeMounts:
    - name: vol
      mountPath: /etc/foo

- Create a PersistentVolume
kind: PersistentVolume
persistentVolumeReclaimPolicy: Retain
storageClassName : normal
  hostPath:
    path: /etc/foo

- Create a PersistentVolumeClaim
kind: PersistentVolumeClaim

    
- Use PersistentVolumeClaim

    volumes:
    - name: site-data
      persistentVolumeClaim:
        claimName: my-lamp-site-data

