# Lab 1: Deploy a Kubernetes cluster

### Objectives
- Create a DC/OS service account for kubernetes and assign permissions to deploy a cluster
- Connect to the kubernetes cluster using kubectl and access the dashboard through a browser on your local machine

### Why is this Important?
There are many ways to deploy a kubernetes cluster from a fully manual procedure to using a fully automated or opinionated SaaS. Cluster sizes can also widely vary from a single node deployment on your laptop, to thousands of nodes in a single logical cluster, or even across multiple clusters. Thus, picking a deployment model that suits the scale that you need as your business grows is important. 

## 1. Install the DC/OS Kubernetes CLI:
The DC/OS Kubernetes CLI aims to help operators deploy, operate, maintain, and troubleshoot Kubernetes clusters running on DC/OS
```
dcos package install kubernetes --cli --yes
```

## 2. Create Kubernetes cluster service account, assign permissions, and deploy a cluster
First we need to create and configure permissions for our kubernetes cluster to be deployed

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



## 3. Deploy Kubernetes
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

Deploy your Kubernetes cluster using the following command:

Mac/Linux

To deploy your kubernetes cluster:
```
dcos kubernetes cluster create --yes --options=options-kubernetes-cluster${CLUSTER}.json --package-version=2.2.1-1.13.4
```

To see the status of your Kubernetes cluster deployment run:
```
dcos kubernetes cluster debug plan status deploy --cluster-name=${APPNAME}/prod/k8s/cluster${CLUSTER}
```

## 4. Connect to Kubernetes cluster using kubectl
Configure the Kubernetes CLI using the following command:
```
dcos kubernetes cluster kubeconfig --context-name=${APPNAME}-prod-k8s-cluster${CLUSTER} --cluster-name=${APPNAME}/prod/k8s/cluster${CLUSTER} \
    --apiserver-url https://${APPNAME}.prod.k8s.cluster${CLUSTER}.mesos.lab:8443 \
    --insecure-skip-tls-verify
```

Change the name of the kubectl config file and copy to your local directory because this config is temporary
```
mv ~/.kube/config ./config.cluster${CLUSTER}
```

Run the following command to check that everything is working properly:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} get nodes
```

Output should look similar to below:
```
$ kubectl get nodes
NAME                                                           STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.trainingprodk8scluster01.mesos   Ready    master   17m   v1.13.4
kube-node-0-kubelet.trainingprodk8scluster01.mesos             Ready    <none>   16m   v1.13.4
kube-node-1-kubelet.trainingprodk8scluster01.mesos             Ready    <none>   16m   v1.13.4
```

## 5. Connect to the Kubernetes dashboard
Run the following command **in a different shell** to run a proxy that will allow you to access the Kubernetes Dashboard:

```
kubectl --kubeconfig=./config.cluster${CLUSTER} proxy
```

Open the following page in your web browser:

[http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/](http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/)

Login using the config file.

![Kubernetes dashboard](https://github.com/ably77/dcos-kubernetes-training/blob/master/images/lab1_1.png)

## Finished with the Lab 1 - Deploying Kubernetes

[Move to Lab 2 - Scaling](https://github.com/c-mcinerney/dcos-kubernetes-training/blob/master/lab2_scaling.md)
