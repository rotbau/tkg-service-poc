# Tanzu Kubernetes Service on vSphere 7 POC Guide
This guide covers some basic POC pre-requisites and general setup for Tanzu Kubernetes Grid proof of concept testing using the integrated TKG service on Vsphere 7.

Assumptions:

1. vSphere 7 with TKG Service
3. Internet connectivity from jumpbox and vsphere environment
4. Perimeter firewall is not doing SSL cracking / Cert spoofing for public URLs.  We can use an offline content library if this is the case.


## Quicklinks

1. [vSphere Infrastructure Prepration](#vsphere-infrastructure-prepration)
2. [Working with the Supervisor Cluster](#the-supervisor-cluster)
3. [Working with vSphere Namespaces](#working-with-vsphere-namespaces)
4. [Creating TKG Workload Clusters](#creating-tkg-workload-clusters)
5. [Working with TKG Workload Clusters](#working-with-tkg-workload-clusters)
6. [Deploy Test Applications](#deploy-test-applications)


## Documentation

This POC guide is meant to supplement the official VMware documentation.  Always consult the latest VMware documentation.

https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-152BE7D2-E227-4DAA-B527-557B564D9718.html


## Jumpbox Requirements

During a POC it's best practice to have a jumpbox with common developer tools installed.  This jumpbox can be Linux, MacOS or Windows.  You can use your own desktop as long as you have connectivity to the environment where vSphere 7 with Tanzu is deployed.  The jumpbox can also be a VM or VDI desktop if desired.

Required Tools

- kubectl and vsphere kubectl plugin - see below for instructions

Optional but helpful tools

- Git Tools - https://git-scm.com/downloads
- jq - https://stedolan.github.io/jq/download/
- Code editor like vscode or notepad++
- SSH / SCP Tools
- Grep or similar


## vSphere Infrastructure Prepration

- vCenter >= 7.0u2
- ESXi >= 7.0u2
- 2-3 ESXi hosts with >=96 GB of Ram each
- 2.5 TB shared storage for ESXi cluster (Block, vSAN, NFS)
- vSphere Cluster with DRS and HA Enabled
- Storage Class created (can be tag based)
- Network requirements to be discussed.  Requirements differ between NSX-T and Non-NSX-T envrionments
    https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-9E6B00BB-DB04-4203-A3E5-97A21B610015.html
- Create a subscribed content library to pull TKG node OVAs.  
    Subscribed library URL https://wp-content.vmware.com/v2/latest/lib.json


## Tanzu Service Installation

Covered in official Documentation
https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-21ABC792-0A23-40EF-8D37-0367B483585E.html

### High Level Workflow

1. NSX-T, NSX Advanced Load Balnacer (AVI) or HA Proxy base install
2. VI Admin / Operator enables Workload Management on vSphere Cluster
3. VI Admin / Operator creates a vsphere namespace for application, developement team, LOB, etc
4. VI Admin / Operator configures rbac, storage policy, vm classes allowed and resource limits (optional) on the vsphere cluster namespace
5. VI Admin / Operator may create a TKG workload cluster for development teams in their namespace or simply hand off the namespace to the team for self-service TKG cluster creation
6. VI Admin / Operator will invite development team to access their configured namespace by sending them the link to the supervisor cluster API IP, vsphere namespace(s) and any TKG cluster(s) created for them
7. Developer team will access supervisor cluster landing page and download kubectl and vshphere plugins for their developement environment OS
8. Developer team will authenticate to supervisor cluster and change into desired vsphere namespace
9. Developer may create a TKG workload cluster using self-service in their vsphere namespaces (optional)
10. Developer will authenticate and change context to TKG workload clusters and deploy applications

### Determine the Supervisor Cluster Kubernetes API Address

Each Supervisor Cluster has its own load-balanced VIP for the Kubernetes API.  This VIP is currently serviced by NSX-T, NSX Advanced Load Balancer (AVI) or HA Proxy depending on how it was installed.  To find the Supervisor Cluster API VIP do one of the following:

- Option 1: Through Workload Management View
    - vCenter -> Menu -> Workload Management -> Clusters tab
    - Control Plane Node IP for desired vSphere Cluster

    ![alt text](/assets/cp-option1.png)

- Option 2: Hosts and Clusters Monitor View
    - vCenter -> Menu -> Hosts and Clusters -> Highlight desired vsphere cluster -> Monitor tab -> Namespaces -> Overview
    - Control Plane Node IP

    ![alt text](/assets/cp-option2.png)

You will use the address to access the landing web page to download kubectl and vsphere plugin and will also be used as part of the `kubectl vsphere login` sequence.  NOTE: If you have enabled Workload Management (Tanzu) on multiple vsphere clusters, each cluster will have its own supervisor cluster and VIP.  You only need to download the kubectl and vsphere logins once and they can be used for all clusters.

### Download Kubectl and vSphere Kubectl plugin

The Supervisor Cluster API hosts a webpage you can use to directly download the kubectl and vsphere kubectl plugin for various Operating Systems

- Select your operating system and click download kubect + kubectl vsphere plugin
- Unzip the vsphere-plugin.zip
- Move the kubectl and kubectl-vsphere plugin in your path or location you rememeber

    ![alt text](/assets/download.png)


## The Supervisor Cluster

Once you enable Tanzu Kubernetes Grid Service (TKGs) in vSphere 7 a new Namespaces resource object is created along with the Supervisor cluster.  The Supervisor cluster is a group of 3 virtual machines running Kubernetes and is the control plane for the vSphere Cluster where Tanzu was enabled.  

- One Supervisor cluster per vSphere cluster that has Workload Management (Tanzu) enabled (as of 7.0u2
- Hosts vSphere namespaces which provide rbac, policy and resource allocations for developer teams
- Cluster API and VMware Tanzu controllers/operators run on hosted on Supervisor Cluster
- VM Service, Network Service and Storage Service Operators
- Considered part of the infrastructure

When operators or developers need to authenticate to Tanzu to create or access Tanzu Kubernetes Grid clusters they will authenticate to the supervisor cluster API VIP associated with namespace or ESXi cluster they are working with.  The Supervisor cluster uses Identity souces configured in vCenter SSO to provide Kubernetes authentication.


## Working with vSphere Namespaces

vSphere Namespaces are created through vCenter UI and run the Supervisor Cluster.  You can use vSphere Namespaces as a boundry for application, application teams, lines of businesses or however you want separate permissions.  Now that Tanzu has been enabled on a vSphere cluster the next step is to create a vSphere Namespace.

https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-177C23C4-ED81-4ADD-89A2-61654C18201B.html

### High Level Workflow
1. Infrastructure Operator creates vSphere Namespace in vCenter UI
2. Developer/Opertator authenticates to the Supervisor Cluster via kubectl cli
3. Developer/Opertator changes context to the desired vSphere Namespace via kubectl cli
4. Developer/Opertator creates Tanzu Kubernetes Grid (TKG) workload cluster using kubectl and cluster spec yaml
5. Developer authenticates to new TKG cluster
6. Developer changes kubectl context to TKG cluster and deploys applications

### Creating vSphere Namespace

1. In vCenter, Select the vSphere cluster with Tanzu enabled in the left pane
2. Select `Namespaces` from the right horizontal menu
3. Click `New Namespace`
4. Select the vSphere cluster with Tanzu enable and give the namespace a name using lowercase letters and numbers (i.e app01)
5. Follow the documentation to set permissions, storageclass, resource limits and VM images used for TKG clusters

    ![alt text](/assets/namespaces.png)

### Authentication to Supervisor Cluster

To authenticate to the supervisor use the kubectl cli along with the kubectl-vsphere plugin.  You can enter `kubectl vsphere login` without anything else to see all of the parameters

`kubectl vsphere login --server {supervisor cluster ip} -u administrator@vsphere.local --insecure-skip-tls-verify`

You can determine your supervisor cluster control plane IP [here](#determine-the-supervisor-cluster-kubernetes-api-address)

alternately you can use the `sc-auth.sh` script in the `/manifests` directory.  Edit the script with the appropriate supervisor cluster control plane IP and username.

You will the see the supervisor cluster context as well as any vSphere namespaces the account you logged in with has access to

   ![alt text](/assets/vsphere-login.png)

### Namespaces and Contexts

In the screenshot from the former section you will see a number of contexts listed.

- 10.0.103.20 - This is the supervisor cluster context.  If your user is a member of the vsphere.local admin group, You can view system namespaces, cluster API objects, controllers and pods.  You cannot create/delete or change most objects in the supervisor cluster context.  
- app01, infra-app - these are vsphere namespaces and can represent applications, developement teams or whatever schema you use to create an RBAC and resource boundary for teams accessing Tanzu

Change context to vSphere namespace
`kubectl config use-context app01`

### Important kubectl commands to explore Namespace

View Tanzu Kubernetes Grid Clusters
`kubectl get tkc` or `kubectl get tkc -A`

View Tanzu Kubernetes Release versions available for use
`kubectl get tkr`

View VM Classes avaialbe in selected vSphere namespace
`kubectl get vmclassbinding`

View All VM Classes defined
`kubectl get vmclass`

View Storageclass available
`kubectl get sc`

View Cluster API Objects
`kubectl get ms`
`kubectl get md`
`kubectl get ma`
`kubectl get vm`


## Creating TKG Workload Clusters

Tanzu Kubernetes Grid (TKG) workload clusters are where you development teams will deploy applications.  TKG clusters are created inside vSphere Namespaces and their LCM is managed via ClusterAPI and the VMware operators.  TKG clusters are created using simple YAML files.

### Create TKG cluster from manifest

Change into vSphere Namespace you will create TKG cluster in
`kubectl config use-context app01`

Apply cluster manifest
`kubectl apply -f /manifests/tkg-app-01.yaml`

### Examine cluster progress and objects

`kubectl get tkc`
`kubectl describe tkc {clustername}`

https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-3040E41B-8A54-4D23-8796-A123E7CAE3BA.html

When cluster status phase is `running` the cluster creation is complete

![alt text](/assets/tkc-status.png)


## Working with TKG Workload Clusters

### Authenticate to TKG Workload Cluster

Once the cluster phase is running, Use the `kubectl vsphere login` command to log into TKG workload cluster.  If your user has `edit` in the vsphere namespace you will automatically mapped to `cluster-admin` role on the TKG Workload cluster.  If you have `view` you will need someone with admin rights on the cluster to map your user/group to a  Kubernetes role.  See `manifests/cluster-edit-role-binding.yaml` for examples.

`kubectl vsphere login --server {supervisor cluster ip} -u administrator@vsphere.local --insecure-skip-tls-verify --tanzu-kubernetes-cluster-namespace {cluster namespace} --tanzu-kubernetes-cluster-name {clustername}`

   ![alt text](/assets/tkg-login.png)

alternately you can use the `/manifests/cluster-auth.sh` script.  Edit the script with the appropriate supervisor cluster control plane IP and username.  Supply the TKG cluster namespace and TKG clustername when exectuting the script.

` ./cluster-auth.sh app01 tkg-app-01`

You can determine your supervisor cluster control plane IP [here](#determine-the-supervisor-cluster-kubernetes-api-address)

You will the see the supervisor cluster context as well as any vSphere namespaces the account you logged in with has access to

### Change context to TKG Workload cluster

`kubectl config use-context tkg-app-01`

### Explore TKG Workload cluster

```
kubectl get nodes
```
```
kubectl get ns
```
```
kubectl get pods -A
```

### Apply PSP to TKG cluster after creation

TKG ships with Pod Security Policies enabled so before deploying application you need to bind users to a PSP.  Here we will bind all authenticated users to the vmware-system-privileged PSP.

`kubectl create clusterrolebinding default-tkg-admin-privileged-binding --clusterrole=psp:vmware-system-privileged --group=system:authenticated`

You can also apply from mainifest
`kubectl apply -f /manifests/psp.yaml`

### Scale TKG cluster

```
kubectl config use-context app01
```
```
kubectl get tkc tkg-app-01 - view current number of control-plane and worker nodes
```
```
kubectl edit tkc tkg-app-01
```

Locate the `spec.topology.controlPlane.count` or `spec.topology.workers.count` section and edit the number of nodes as desired

```
ControlPlane:
    count: 3
```
```
workers:
    count: 4
```

### Delete TKG cluster

`kubectl delete tkc {clustername}`

### Upgrade TKG cluster

Determine TKG versions available
`kubectl get tkr`

Edit TKG Cluster deployment

```
kubectl get tkc
```
```
kubectl edit tkc tkg-app-01 -n app01
```

Edit the version and full version string in the mainifest

```
spec:
  distribution:
    fullVersion: v1.17.8+vmware.1-tkg.1.5417466
    version: v1.17.8
```
to
```
spec:
  distribution:
    fullVersion: null
    version: v1.20
```

https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-6B21C37B-91ED-4218-B7B8-C40417ADBF8A.html


## Deploy Test Applications

### Kuard

Simple test application.  From Joe Beda's "Kubernetes Up and Running"

Deployment (3 replicas)
```
kubectl apply -f kuard/kuard.yaml
```

Run as Pod
```
kubectl run --restart=Never --image=gcr.io/kuar-demo/kuard-amd64:blue kuard
kubectl port-forward kuard 8080:8080
```

### Busybox

Deploy Pod
```
kubectl apply -f busybox/busybox.yaml
```

Run Pod
```
kubectl run busybox --image=busybox:1.28 -- sleep 3600
```

### Tinytools

Simple pod that includes ping, curl, wget, traceroute commands

Deploy Pod
```
kubectl apply -f tinytools/tinytools.yaml
```

Run as Pod
```
kubectl run tinytools  --image=docker.io/giantswarm/tiny-tools -- sleep 36000
```

Exec into Pod
```
kubectl exec -ti tinytools -- sh
```

### Nginx

Simple Nginx deployment.  2 replicas, service type LoadBalancer
```
kubectl apply -f nginx/nginx.yaml
```
Yon get the nginx service IP using `kubectl get svc`
