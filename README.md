# TKG POC Guide
This guide covers some basic POC pre-requisites and general setup for Tanzu Kubernetes Grid proof of concept testing using the integrated TKG service on Vsphere 7.

Assumptions:

1. vSphere 7 with TKG Service
3. Internet connectivity from jumpbox and vsphere environment
4. Perimeter firewall is not doing SSL cracking / Cert spoofing for public URLs.  We can use an offline content library if this is the case.


## Quicklinks

1. [vSphere Infrastructure Prepration](#vsphere-infrastructure-preparation)
2. [Working with the Supervisor Cluster](#working-with-the-supervisor-cluster)
3. [Working with vSphere Namespaces](#working-with-vsphere-namespaces)
4. [Creating TKG Workload Clusters](#creating-tkg-workload-clusters)
5. [Working with TKG Workload Clusters](#working-with-tkg-workload-clusters)


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
- ESXi >= 7.0u1
- 2-3 ESXi hosts with >=96 GB of Ram each
- 2.5 TB shared storage for ESXi cluster (Block, vSAN, NFS)
- vSphere Cluster with DRS and HA Enabled
- Storage Class created (can be tag based)
- Network requirements to be discussed.  Requirements differ between NSX-T and Non-NSX-T envrionments
    https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-9E6B00BB-DB04-4203-A3E5-97A21B610015.html
- Create a subscribed content library to pull TKG node OVAs https://wp-content.vmware.com/v2/latest/lib.json


## Tanzu Service Installation

Covered in official Documentation
https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-21ABC792-0A23-40EF-8D37-0367B483585E.html


## Working with the Supervisor Cluster

When you enable Tanzu Kubernetes Grid Service (TKGs) in vSphere 7 a new Namespaces resource object is created along with the Supervisor cluster.  The Supervisor cluster is a group of 3 virtual machines running Kubernetes and is the control plane for the vSphere Cluster where TKGs was enabled.  

- One Supervisor cluster per vSphere cluster that has Workload Management (Tanzu) enabled
- Hosts supervisor cluster (vsphere) namespaces which provide rbac, policy and resource allocations for developer teams
- Runs Cluster API and VMware Tanzu controllers/operators
- Runs VM Service, Network Service and Storage Service compnents
- Considered part of the infrastructure

When operators or developers need to authenticate to Tanzu to create or access Tanzu Kubernetes Grid clusters they will authenticate to the supervisor cluster API for the cluster they are working with.  The Supervisor cluster uses Identity souces configured in vCenter SSO to provide Kubernetes authentication.

### High Level Workflow

1. NSX-T, NSX Advanced Load Balnacer (AVI) or HA Proxy base install
2. VI Admin / Operator enables Workload Management on vSphere Cluster
3. VI Admin / Operator creates a vsphere namespace for application, developement team, LOB, etc
4. VI Admin / Operator configures rbac, storage policy, resource limits (optional) on the vsphere cluster namespace
5. VI Admin / Operator may create a TKG workload cluster for development teams in their namespace or simply hand off the namespace to the team for self-service TKG cluster creation
6. VI Admin / Operator will invite development team to access their configured namespace by sending them the link to the supervisor cluster API IP, vsphere namespace(s) and any TKG cluster(s) created for them
7. Developer team will access supervisor cluster landing page and download kubectl and vshphere plugins for their developement environment OS
8. Developer team will authenticate to supervisor cluster and change into desired vsphere namespace
9. Developer may create a TKG workload cluster using self-service in their vsphere namespaces (optional)
10. Developer will authenticate and change context to TKG workload clusters and deploy applications

### Determine the Supervisor Cluster Kubernetes API Address

Each Supervisor Cluster has its own load-balanced VIP for the Kubernetes API.  This VIP is currently serviced by NSX-T, NST Advanced Load Balancer (AVI) or HA Proxy depending on how it was installed.  To find the Supervisor Cluster API VIP do one of the following:

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


## Working with vSphere Namespaces

vSphere Namespaces are created on the Supervisor Cluster.  You can use vSphere Namespaces as a boundry for application, application teams, lines of businesses or however you want separate permissions.

https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-177C23C4-ED81-4ADD-89A2-61654C18201B.html

### Creating vSphere Namespace

1. Select the vSphere cluster with Tanzu enabled in the left pane
2. Select `Namespaces` from the right horizontal menu
3. Click `New Namespace`
4. Select the vSphere cluster with Tanzu enable and give the namespace a name using lowercase letters and numbers.
5. Follow the documentation to set permissions, storageclass, resource limits and VM images.

    ![alt text](/assets/namespaces.png)

### Authentication to Supervisor Cluster

To authenticate to the supervisor use the kubectl with the kubectl-vsphere plugin.  You can enter `kubectl vsphere login` without anything else to see all of the parameters

`kubectl vsphere login --server {supervisor cluster ip} -u administrator@vsphere.local --insecure-skip-tls-verify`

You will the supervisor cluster context as well as any vSphere namespaces the account you logged in with has access to

   ![alt text](/assets/vsphere-login.png)

### Namespaces and Contexts

In the screenshot from the former section you will see a number of contexts listed.

- 10.0.103.20 - This is the supervisor cluster context.  You can view system namespaces, cluster API objects, controllers and pods.  You cannot create/delete or change most objects in the supervisor cluster context.  
- app01, demo-app-01, infra-app - You can change your context into any of the namespaces you have access to and create TKG clusters or deploy vSphere Pods (NSX-T required for vSphere Pods)

Change context to vSphere namespace 

`kubectl config use-context demo-app-01`

### Important kubectl commands to explore Namespace

View Tanzu Kubernetes Grid Clusters
`kubectl get tkc`

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

Change into vSphere Namespace 

`kubectl config use-context demo-app-01`
`kubectl apply -f /manifests/cluster01.yaml`

### Examine cluster progress and objects

`kubectl get tkc`
`kubectl describe tkc {clustername}`

https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-6B21C37B-91ED-4218-B7B8-C40417ADBF8A.html


## Working with TKG Workload Clusters

### Scale TKG cluster

`kubectl config use-context demo-app-01`
`kubectl get tkc cluster01` - view current number of control-plane and worker nodes
`kubectl edit tkc cluster01`

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

`kubectl get tkc`
`kubectl edit tkc cluster01 -n demo-app-01`

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
