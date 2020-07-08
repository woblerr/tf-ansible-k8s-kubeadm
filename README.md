# Terraform, Ansible, and kubeadm for Kubernetes Cluster on DigitalOcean

Creates a cluster with 1 master and multiple worker nodes (by default, 2) with Flannel networking.

[terraform-inventory](https://github.com/adammck/terraform-inventory) is used for Ansible inventory.

## Usage

```bash
git clone https://github.com/woblerr/tf-ansible-k8s-kubeadm-do.git

cd tf-ansible-k8s-kubeadm-do

export TF_VAR_do_token="DO-Token"
export TА_VAR_do_ssh_fingerprint="DO-SSH-Fingerprint"

terraform init
```

Where:

* `"DO-Token"` - your [Personal Access Token](https://www.digitalocean.com/docs/apis-clis/api/create-personal-access-token/);
* `"DO-SSH-Fingerprint"` - MD5 fingerprint of your ssh public key.

You can get it by running the command on local machine:

```bash
ssh-keygen -E md5 -lf ~/.ssh/id_rsa.pub | awk '{print $2}'|awk -F'MD5:' '{$1=""; print $2}'
```

### Create droplets in DO

Create droplets in DigitalOcean:

```bash
ansible-playbook k8s-cluster-create.yml
```

Droplet parameters in `do-k8s.tf` (see <https://slugs.do-api.dev/> for more informations):

|Variable| Description| Default|
|---|---|---|
|do_region|Default DO region|ams2|
|do_image|Default DO image|ubuntu-18-04-x64|
|do_master_size|Default master size|s-2vcpu-2gb|
|do_node_size|Default node size|s-1vcpu-1gb|

The number of working nodes can be set in the file `variables.tf`:

|Variable| Description| Default|
|---|---|---|
|master_cnt|Default count of masters|1|
|node_cnt|Default count of nodes|2|

Playbook is also download [terraform-inventory](https://github.com/adammck/terraform-inventory) on your local machine for further use.

### Install K8S

Configure droplets and install Kubernetes (packages version 1.18.5-00):

```bash
TF_HOSTNAME_KEY_NAME=name TF_STATE=.  ansible-playbook -i ./terraform-inventory k8s-install.yml
```

After completing the playbook, you can connect to the master by user `kuber` and  view the cluster:

```bash
kuber@master-1:~$ kubectl get cs
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true"}
kuber@master-1:~$ kubectl get nodes
NAME       STATUS   ROLES    AGE   VERSION
master-1   Ready    master   50m   v1.18.5
node-1     Ready    <none>   50m   v1.18.5
node-2     Ready    <none>   50m   v1.18.5
kuber@master-1:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
kube-system   coredns-66bff467f8-8545f           1/1     Running   0          50m
kube-system   coredns-66bff467f8-dv7fh           1/1     Running   0          50m
kube-system   etcd-master-1                      1/1     Running   1          50m
kube-system   kube-apiserver-master-1            1/1     Running   1          50m
kube-system   kube-controller-manager-master-1   1/1     Running   1          50m
kube-system   kube-flannel-ds-amd64-56w49        1/1     Running   0          50m
kube-system   kube-flannel-ds-amd64-w4wqf        1/1     Running   1          50m
kube-system   kube-flannel-ds-amd64-ws9rm        1/1     Running   1          50m
kube-system   kube-proxy-jl6rz                   1/1     Running   0          50m
kube-system   kube-proxy-ll62t                   1/1     Running   1          50m
kube-system   kube-proxy-nn5sj                   1/1     Running   0          50m
kube-system   kube-scheduler-master-1            1/1     Running   1          50m
```

### Destroy droplets in DO

Destroy droplets in DigitalOcean:

```bash
ansible-playbook k8s-cluster-destroy.yml
```
