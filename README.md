# Mesosphere DC/OS Kubernetes training

https://docs.google.com/spreadsheets/d/1DNbpYQCXQ7sXu5hGm8qyTH4gr1bBXwwt80U2imoftok/edit?usp=sharing

## Introduction

During this training, you'll learn how to use the main capabilities of Kubernetes on DC/OS:

- Deploy a Kubernetes cluster
- Scale a Kubernetes cluster
- Upgrade a Kubernetes cluster
- Expose a Kubernetes Application using a Service Type Load Balancer (L4)
- Expose a Kubernetes Application using an Ingress (L7)


[Let's get started!  Move to Lab 0 - Prerequisites](https://github.com/c-mcinerney/dcos-kubernetes-training/blob/master/lab0_prerequisites.md)

## Jumpserver

In the event your client does not allow for the installation of the required components a provided jump server can be used.  First, go to the above spreadsheet and download the ssh-private-key and execute an ssh-add.  Then ssh to the ipaddress of your assigned jumpserver.
```
ssh-add ClassroomJumpServer.pem
ssh centos@jumpserver-ip-address
```
