# Mesosphere DC/OS Kubernetes training

https://docs.google.com/spreadsheets/d/1g3UG2e-1LVGmBH8LORRIvgTXUJoHMI-ZI9IIuiLgvLM/edit?usp=sharing

## Introduction

During this training, you'll learn how to use the main capabilities of Kubernetes on DC/OS:

- Deploy a Kubernetes cluster
- Scale a Kubernetes cluster
- Upgrade a Kubernetes cluster
- Expose a Kubernetes Application using a Service Type Load Balancer (L4)
- Expose a Kubernetes Application using an Ingress (L7)


During the labs, replace X by the number assigned by the instructor (starting with 00).

## Pre requisites

Run the following command to export the environment variables needed during the labs:
MAC/LINUX
```
export APPNAME=training
export PUBLICIP=52.39.200.235
export CLUSTER=<the number assigned by the instructor: 00, 01, ..>
```
Windows
```
set APPNAME=training
set PUBLICIP=52.39.200.235
set CLUSTER=<the number assigned by the instructor: 00, 01, ..>
```
Log into the DC/OS Kubernetes cluster with the information provided by your instructor and download the DC/OS CLI.

Set Up DC/OS Command Line from the web interface of the classroom cluster

https://mcinerneyui-1752945458.us-west-2.elb.amazonaws.com/

http://mcinerneyui-1752945458.us-west-2.elb.amazonaws.com/

Set up the DC/OS command line by clicking on the top right and choosing "install CLI"

![CLI](https://i.imgur.com/p4kqIj6.png)

Click in the dialogue box to copy the command based off of your OS:

![Copy Command](https://i.imgur.com/3rQ2Unj.png)

When prompted for a password:
```
Username: bootstrapuser
Password: deleteme
```

Output should look like this:
```
[centos@ip-10-0-0-243 ~]$ [ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin &&
> curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.11/dcos -o dcos &&
> sudo mv dcos /usr/local/bin &&
> sudo chmod +x /usr/local/bin/dcos &&
> dcos cluster setup https://34.201.120.43 &&
> dcos
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 14.0M  100 14.0M    0     0  3834k      0  0:00:03  0:00:03 --:--:-- 3835k
SHA256 fingerprint of cluster certificate bundle:
91:31:31:A8:83:E8:05:94:E1:9B:23:34:EE:41:21:32:C8:A1:EB:7F:0D:B1:4C:A5:67:5A:BF:ED:70:B0:1D:C2 [yes/no] yes
34.201.120.43's username: bootstrapuser
bootstrapuser@34.201.120.43's password:
Command line utility for the Mesosphere Datacenter Operating
System (DC/OS). The Mesosphere DC/OS is a distributed operating
system built around Apache Mesos. This utility provides tools
for easy management of a DC/OS installation.

Available DC/OS commands:

	auth           	Authenticate to DC/OS cluster
	cluster        	Manage your DC/OS clusters
	config         	Manage the DC/OS configuration file
	help           	Display help information about DC/OS
	job            	Deploy and manage jobs in DC/OS
	marathon       	Deploy and manage applications to DC/OS
	node           	View DC/OS node information
	package        	Install and manage DC/OS software packages
	service        	Manage DC/OS services
	task           	Manage DC/OS tasks

Get detailed command description with 'dcos <command> --help'.
```

Confirm that dcos is installed and connected to your cluster by running following command

```
dcos node
```

The output should be a list of nodes in the cluster:
```

   HOSTNAME        IP                         ID                     TYPE                 REGION          ZONE       
  10.0.0.101   10.0.0.101  94141db5-28df-4194-a1f2-4378214838a7-S0   agent            aws/us-west-2  aws/us-west-2a  
  10.0.2.100   10.0.2.100  94141db5-28df-4194-a1f2-4378214838a7-S4   agent            aws/us-west-2  aws/us-west-2a
```

Run the following command to setup the DC/OS CLI:

```
dcos cluster setup https://34.217.146.46 --username=bootstrapuser --password=deleteme

dcos auth login --username=bootstrapuser --password=deleteme
```

Run the following command to add the DC/OS Enterprise extensions to the DC/OS CLI:

```
dcos package install --yes --cli dcos-enterprise-cli
```

Install the kubectl CLI using the instructions available at the URL below:

[https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl)

Add the following line to your /etc/hosts (or c:\Windows\System32\Drivers\etc\hosts) file:

```
<PUBLICIP variable> training.prod.k8s.cluster<CLUSTER variable>.mesos.lab
```

## 1. Deploy a Kubernetes cluster

Create a file called options-kubernetes-cluster${CLUSTER}.json using the following command:

```
cat <<EOF > options-kubernetes-cluster${CLUSTER}.json
{
  "service": {
    "name": "training/prod/k8s/cluster${CLUSTER}",
    "service_account": "training-prod-k8s-cluster${CLUSTER}",
    "service_account_secret": "/training/prod/k8s/cluster${CLUSTER}/private-training-prod-k8s-cluster${CLUSTER}"
  },
  "kubernetes": {
    "authorization_mode": "RBAC",
    "high_availability": false,
    "private_node_count": 2,
    "private_reserved_resources": {
      "kube_mem": 4096
    }
  }
}
EOF
```

It will allow you to deploy a Kubernetes cluster with RBAC enabled, HA disabled (to limit the resource needed) and with 2 private nodes.

Create a file called deploy-kubernetes-cluster.sh with the following content:

```
path=${APPNAME}/prod/k8s/cluster${1}

serviceaccount=$(echo $path | sed 's/\//-/g')
role=$(echo $path | sed 's/\//__/g')-role

dcos security org service-accounts keypair private-${serviceaccount}.pem public-${serviceaccount}.pem
dcos security org service-accounts delete ${serviceaccount}
dcos security org service-accounts create -p public-${serviceaccount}.pem -d /${path} ${serviceaccount}
dcos security secrets delete /${path}/private-${serviceaccount}
dcos security secrets create-sa-secret --strict private-${serviceaccount}.pem ${serviceaccount} /${path}/private-${serviceaccount}

dcos security org users grant ${serviceaccount} dcos:secrets:default:/${path}/* full
dcos security org users grant ${serviceaccount} dcos:secrets:list:default:/${path} full
dcos security org users grant ${serviceaccount} dcos:adminrouter:ops:ca:rw full
dcos security org users grant ${serviceaccount} dcos:adminrouter:ops:ca:ro full
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:role:${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:principal:${serviceaccount} delete
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:role:${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:principal:${serviceaccount} delete
dcos security org users grant ${serviceaccount} dcos:mesos:master:task:user:nobody create
dcos security org users grant ${serviceaccount} dcos:mesos:master:task:user:root create
dcos security org users grant ${serviceaccount} dcos:mesos:agent:task:user:root create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public/${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public/${role} read
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:role:slave_public/${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:role:slave_public/${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public read
dcos security org users grant ${serviceaccount} dcos:mesos:agent:framework:role:slave_public read

dcos kubernetes cluster create --yes --options=options-kubernetes-cluster${1}.json --package-version=2.1.1-1.12.5
```

It will allow you to create the DC/OS service account with the right permissions and to deploy a Kubernetes cluster with the version 1.12.5.

Deploy your Kubernetes cluster using the following command:

Mac/Linux
```
dcos package install kubernetes --cli --yes
chmod +x deploy-kubernetes-cluster.sh
./deploy-kubernetes-cluster.sh ${CLUSTER}
```
Windows
```
dcos package install kubernetes --cli --yes
deploy-kubernetes-cluster.bat %CLUSTER%
```
Configure the Kubernetes CLI using the following command:

Mac/Linux
```
dcos kubernetes cluster kubeconfig --context-name=${APPNAME}-prod-k8s-cluster${CLUSTER} --cluster-name=${APPNAME}/prod/k8s/cluster${CLUSTER} \
    --apiserver-url https://${APPNAME}.prod.k8s.cluster${CLUSTER}.mesos.lab:8443 \
    --insecure-skip-tls-verify
```
Windows
```
dcos kubernetes cluster kubeconfig --context-name=%APPNAME%-prod-k8s-cluster%CLUSTER% --cluster name=%APPNAME%/prod/k8s/cluster%CLUSTER% --apiserver-url https://%APPNAME%.prod.k8s.cluster%CLUSTER%.mesos.lab:443 --insecure-skip-tls-verify
```
Run the following command to check that everything is working properly:

```
kubectl get nodes
NAME                                                           STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.trainingprodk8scluster${CLUSTER}.mesos   Ready    master   23m   v1.12.5
kube-node-0-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   21m   v1.12.5
kube-node-1-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   21m   v1.12.5
```

Copy the Kubernetes config file in your current directory

Mac/Linux
```
cp ~/.kube/config .
```

Windows
```
copy %HOME%\.kube\config .
```

Run the following command **in a different shell** to run a proxy that will allow you to access the Kubernetes Dashboard:

```
kubectl proxy
```

Open the following page in your web browser:

[http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/](http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/)

Login using the config file.

![Kubernetes dashboard](images/kubernetes-dashboard.png)

## 2. Scale your Kubernetes cluster

Run the following command to scale your Kubernetes cluster:

Edit the options-kubernetes-cluster${CLUSTER}.json file to set the private_node_count to 3.


Run the following command to update your cluster:

```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${CLUSTER} --options=options-kubernetes-cluster${CLUSTER}.json --yes
Using Kubernetes cluster: training/prod/k8s/cluster1
2019/01/26 14:40:51 starting update process...
2019/01/26 14:40:58 waiting for update to finish...
2019/01/26 14:42:10 update complete!
```

You can check that the new node is shown in the Kubernetes Dashboard:

![Kubernetes dashboard scaled](images/kubernetes-dashboard-scaled.png)

## 3. Upgrade your Kubernetes cluster

Run the following command to upgrade your Kubernetes cluster:

Run the following command to upgrade your cluster:

```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${CLUSTER} --package-version=2.2.0-1.13.3 --yes

```

You can check that the cluster has been updated using the Kubernete CLI:

```
kubectl get nodes
NAME                                                          STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.trainingprodk8scluster${CLUSTER}.mesos   Ready    master   94m   v1.13.3
kube-node-0-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   92m   v1.13.3
kube-node-1-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   92m   v1.13.3
kube-node-2-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   36m   v1.13.3
```

## 4. Expose a Kubernetes Application using a Service Type Load Balancer (L4)

This feature leverage the DC/OS EdgeLB and a new service called dklb.

To be able to use dklb, you need to deploy it in your Kubernetes cluster using the following commands:

```
kubectl create -f dklb-prereqs.yaml
kubectl create -f dklb-deployment.yaml
```

You can use the Kubernetes Dashboard to check that the deployment dklb is running in the kube-system namespace:

![Kubernetes dashboard dklb](images/kubernetes-dashboard-dklb.png)

You can now deploy a redis Pod on your Kubernetes cluster running the following command:

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: redis
  name: redis
spec:
  containers:
  - name: redis
    image: redis:5.0.3
    ports:
    - name: redis
      containerPort: 6379
      protocol: TCP
EOF
```

Finally, to expose the service, you need to run the following command to create a Service Type Load Balancer:

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubernetes.dcos.io/edgelb-pool-name: "dklb"
    kubernetes.dcos.io/edgelb-pool-size: "2"
    kubernetes.dcos.io/edgelb-pool-portmap.6379: "80${CLUSTER}"
  labels:
    app: redis
  name: redis
spec:
  type: LoadBalancer
  selector:
    app: redis
  ports:
  - protocol: TCP
    port: 6379
    targetPort: 6379
EOF
```

A dklb EdgeLB pool is automatically created on DC/OS:

You can validate that you can access the redis POD from your laptop using telnet:

```
telnet ${PUBLICIP} 80${CLUSTER}
Trying 34.227.199.197...
Connected to ec2-34-227-199-197.compute-1.amazonaws.com.
Escape character is '^]'.
```

## 5. Expose a Kubernetes Application using an Ingress (L7)

Update the PUBLICIP environment variable to use the Public IP of one of the DC/OS public node. It's needed because there is a limited number of listeners we can set on the AWS Load Balancer we use in front of the DC/OS public nodes.

This feature leverage the DC/OS EdgeLB and the dklb service that has been deployed in the previous section.

You can now deploy 2 web application Pods on your Kubernetes cluster running the following command:

```
kubectl run --restart=Never --image hashicorp/http-echo --labels app=http-echo-1,owner=dklb --port 80 http-echo-1 -- -listen=:80 --text='Hello from http-echo-1!'
kubectl run --restart=Never --image hashicorp/http-echo --labels app=http-echo-2,owner=dklb --port 80 http-echo-2 -- -listen=:80 --text='Hello from http-echo-2!'
```

Then, expose the Pods with a Service Type NodePort using the following commands:

```
kubectl expose pod http-echo-1 --port 80 --target-port 80 --type NodePort --name "http-echo-1"
kubectl expose pod http-echo-2 --port 80 --target-port 80 --type NodePort --name "http-echo-2"
```

Finally create the Ingress to expose the application to the ourside world using the following command:

```
cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: edgelb
    kubernetes.dcos.io/edgelb-pool-name: "dklb"
    kubernetes.dcos.io/edgelb-pool-size: "2"
    kubernetes.dcos.io/edgelb-pool-port: "90${CLUSTER}"
  labels:
    owner: dklb
  name: dklb-echo
spec:
  rules:
  - host: "http-echo-${CLUSTER}-1.com"
    http:
      paths:
      - backend:
          serviceName: http-echo-1
          servicePort: 80
  - host: "http-echo-${CLUSTER}-2.com"
    http:
      paths:
      - backend:
          serviceName: http-echo-2
          servicePort: 80
EOF
```

The dklb EdgeLB pool is automatically updated on DC/OS:

You can validate that you can access the web application PODs from your laptop using the following commands:

```
curl -H "Host: http-echo-${CLUSTER}-1.com" http://${PUBLICIP}:90${CLUSTER}
curl -H "Host: http-echo-${CLUSTER}-2.com" http://${PUBLICIP}:90${CLUSTER}
```


