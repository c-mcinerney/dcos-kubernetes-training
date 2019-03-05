SET marathon-path=%APPNAME%/prod/k8s/cluster%1

SET serviceaccount=%APPNAME%-prod-k8s-cluster%1
SET role=%APPNAME%-prod-k8s-cluster%1-role

dcos security org service-accounts keypair private-%serviceaccount%.pem public-%serviceaccount%.pem
dcos security org service-accounts delete %serviceaccount%
dcos security org service-accounts create -p public-%serviceaccount%.pem -d /%marathon-path% %serviceaccount%
dcos security secrets delete /%marathon-path%/private-%serviceaccount%
dcos security secrets create-sa-secret --strict private-%serviceaccount%.pem %serviceaccount% /%marathon-path%/private-%serviceaccount%

dcos security org users grant %serviceaccount% dcos:secrets:default:/%marathon-path%/* full
dcos security org users grant %serviceaccount% dcos:secrets:list:default:/%marathon-path% full
dcos security org users grant %serviceaccount% dcos:adminrouter:ops:ca:rw full
dcos security org users grant %serviceaccount% dcos:adminrouter:ops:ca:ro full
dcos security org users grant %serviceaccount% dcos:mesos:master:framework:role:%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:reservation:role:%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:reservation:principal:%serviceaccount% delete
dcos security org users grant %serviceaccount% dcos:mesos:master:volume:role:%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:volume:principal:%serviceaccount% delete
dcos security org users grant %serviceaccount% dcos:mesos:master:task:user:nobody create
dcos security org users grant %serviceaccount% dcos:mesos:master:task:user:root create
dcos security org users grant %serviceaccount% dcos:mesos:agent:task:user:root create
dcos security org users grant %serviceaccount% dcos:mesos:master:framework:role:slave_public/%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:framework:role:slave_public/%role% read
dcos security org users grant %serviceaccount% dcos:mesos:master:reservation:role:slave_public/%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:volume:role:slave_public/%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:framework:role:slave_public read
dcos security org users grant %serviceaccount% dcos:mesos:agent:framework:role:slave_public read

dcos kubernetes cluster create --yes --options=options-kubernetes-cluster%1.json --package-version=2.1.1-1.12.5