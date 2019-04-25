# 1. Environment variables
* `CLUSTER_USER`: the user to use over the cluster nodes
* `MASTER_HOST`: the ip address of the master node
* `MASTER_PORT`: the default port for the master node (e.g. 6443)
* `WORKERS`: a string listing the worker nodes (e.g., "192.168.50.11 192.168.50.12")
* `SSH_KEY_PATH`: the local path to the private key to be used to ssh to the nodes (e.g., "$HOME/Documents/k8s-setup/nodes/key")
* `CIDR_NET`: e.g. "192.168.0.0/16"
* `KUBE_VERSION`: the kubernetes version, e.g. "1.14.1"

# 2. Setup
* `start.sh`: exports the environment variables and calls the setup script
* `setup.sh`: performs the installation operations on the master and the worker nodes

# 3. Installation Operations
The setup script loads the private ssh key to the master node, along with the setup script itself. The setup script is also uploaded on each of the worker nodes.
The main difference is that the `init` action is called on the setup script for the master node, while the `add` action is called on the same script on each of the worker nodes.

# 3.1 Master setup
The following operations are performed:
* installation of docker, using overlay2 as file system
* deactivation of memory swapping (otherwise the kubelet won't start)
* installation of kubeadm, kubectl, cni (container network interface)
* cluster init, using kubeadm init
* exporting of the join tokens, uploading of the join string on the worker nodes
* setting KUBECONFIG to the just generated (by kubeadm) admin.conf file, so that kubectl can be used to interact with the cluster
* adding flannel as cluster resource to manage container networking
* adding kubernetes dashboard to manage the cluster

# 3.2 Worker setup
The following operations are performed:
* installation of docker, using overlay2 as file system
* deactivation of memory swapping (otherwise the kubelet won't start)
* installation of kubeadm, kubectl, cni
* addition of the worker to the cluster using kubeadm join
* when using vagrant the kubelet config file is modified to overwrite the node ip, as otherwise the vagrant eth0 is used

# 3.3 Interaction with the cluster across the network
To use kubectl on the master we did set `KUBECONFIG=~/.kube/admin.conf`. 
We can copy this file and use the same approach to be able to interact with the cluster from any node in the network.

Example:
```
pilillo@ryzen shell-setup]$ kubectl get pods --kubeconfig admin.conf --all-namespaces
NAMESPACE     NAME                                    READY   STATUS             RESTARTS   AGE
data-mill     example-pod                             0/1     Error              0          19h
kube-system   coredns-fb8b8dccf-8c4lb                 1/1     Running            1          21h
kube-system   coredns-fb8b8dccf-c6g5t                 1/1     Running            1          20h
kube-system   etcd-k8s-master                         1/1     Running            1          21h
kube-system   kube-apiserver-k8s-master               1/1     Running            1          21h
kube-system   kube-controller-manager-k8s-master      1/1     Running            1          20h
kube-system   kube-flannel-ds-amd64-5pxjw             1/1     Running            1          20h
kube-system   kube-flannel-ds-amd64-9sxsb             1/1     Running            1          19h
kube-system   kube-flannel-ds-amd64-zgg4h             1/1     Running            1          20h
kube-system   kube-proxy-7tzx4                        1/1     Running            1          20h
kube-system   kube-proxy-ld26g                        1/1     Running            1          21h
kube-system   kube-proxy-t8kb6                        1/1     Running            1          19h
kube-system   kube-scheduler-k8s-master               1/1     Running            1          21h
```

We can delete the example pod which remained up upon an error.
```
[pilillo@ryzen shell-setup]$ kubectl delete pod --kubeconfig admin.conf -n=data-mill example-pod
pod "example-pod" deleted
```
