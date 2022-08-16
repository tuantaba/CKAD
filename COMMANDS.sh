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







