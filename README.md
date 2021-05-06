# TKG POC Guide
This guide covers some basic POC pre-requisites and general setup for Tanzu Kubernetes Grid proof of concept testing using the integrated TKG service on Vsphere 7.

Assumptions:

1. vSphere 7 with TKG Service
3. Internet connectivity from jumpbox and vsphere environment
4. Perimeter firewall is not doing SSL cracking / Cert spoofing for public URLs.  We can use an offline content library if this is the case.


## Quicklinks

1. [Working with TKG CLI](#working-with-tkg-cli)
2. [Working with the TKG Management cluster](#working-with-the-tkg-management-cluster)
3. [Creating TKG Workload clusters](#creating-tkg-workload-clusters)
4. [Working with TKG Workload clusters](#working-with-tkg-workload-clusters)
5. [Deploying test applications]()


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

## vSphere Infrastructure Prepration

- vCenter >= 7.0u2
- ESXi >= 7.0u1
- 2-3 ESXi hosts with >=96 GB of Ram each
- 2.5 TB shared storage for ESXi cluster (Block, vSAN, NFS)
- vSphere Cluster with DRS and HA Enabled
- Network requirements to be discussed.  Requirements differ between NSX-T and Non-NSX-T envrionments
    https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-9E6B00BB-DB04-4203-A3E5-97A21B610015.html

## Tanzu Service Installation

Covered in official Documentation
https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-21ABC792-0A23-40EF-8D37-0367B483585E.html


## Working with the TKG Supervisor Cluster

When you enable Tanzu Kubernetes Grid Service (TKGs) in vSphere 7 a new Namespaces resource object is created along with the Supervisor cluster.  The Supervisor cluster is a group of 3 virtual machines running Kubernetes and is the control plane for the vSphere Cluster where TKGs was enabled.  

- One Supervisor cluster per vSphere cluster that has Workload Management (Tanzu) enabled
- Hosts supervisor cluster (vsphere) namespaces which provide rbac, policy and resource allocations for developer teams
- Runs Cluster API and VMware Tanzu controllers/operators
- Runs VM Service, Network Service and Storage Service compnents
- Considered part of the infrastructure

When operators or developers need to authenticate to Tanzu to create or access Tanzu Kubernetes Grid clusters they will authenticate to the supervisor cluster API for the cluster they are working with.  The Supervisor cluster uses Identity souces configured in vCenter SSO to provide Kubernetes authentication.

### High Level Workflow

1. VI Admin / Operator enables Workload Management on vSphere Cluster
2. VI Admin / Operator creates a vsphere namespace for application, developement team, LOB, etc
3. VI Admin / Operator configures rbac, storage policy, resource limits (optional) on the vsphere cluster namespace
4. VI Admin / Operator may create a TKG workload cluster for development teams in their namespace or simply hand off the namespace to the team for self-service TKG cluster creation
5. VI Admin / Operator will invite development team to access their configured namespace by sending them the link to the supervisor cluster API IP, vsphere namespace(s) and any TKG cluster(s) created for them
6. Developer team will access supervisor cluster landing page and download kubectl and vshphere plugins for their developement environment OS
7. Developer team will authenticate to supervisor cluster and change into desired vsphere namespace
8. Developer may create a TKG workload cluster using self-service in their vsphere namespaces (optional)
9. Developer will authenticate and change context to TKG workload clusters and deploy applications


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


    `tkg get mc` to view management clusters
    You will see all TKG management clusters you've installed from this jumpbox.  The management cluster with the asterisk is the currently set cluster.

    ![alt text](/assets/tkg-get-mc.png)

- Set TKG mangement cluster 
    `tkg set mc tkg-mgmt` will set the mc context for the TKG cli.  Any further TKG commands you run will be executed by the selected TKG management cluster.

    ![alt text](/assets/tkg-set-mc.png)

- View TKG workload clusters managed by selected TKG management cluster
    `tkg get clusters` or `tkg get clusters --include-management-cluster`

    ![alt text](/assets/tkg-set-mc.png)

### Accessing TKG managemnt cluster nodes using kubectl

By default during installation of the Management cluster, the credentials are added to the jumpbox kubeconfig file (~/.kube/config).  You can access the management cluster nodes using kubectl.

- Set kubectl cli context
    `kubectl config use-context [mgmt-cluster-name]`

example for tkg-mgmt management cluster name

    `kubectl config use-context tkg-mgmt-admin@tkg-mgmt`

    ![alt text](/assets/kubectl-config.png)

- View nodes
    `kubectl get nodes`

    ![alt text](/assets/kubectl-get-nodes.png)

- View namespaces
    `kubectl get ns`

    ![alt text](/assets/kubectl-get-ns.png)

- View all pods
    `kubectl get pods -A`

- View pods in a specific namespace
    `kubectl get pods -n kube-system`

## Creating TKG Workload clusters

Once you have your TKG management cluster created you can create TKG workload clusters for your applications.  You can leverage the TKG cli to create clusters.

- Set TKG management cluster if you have multiple management clusters.  Ignore if you only have a single TKG management cluster
- Create TKG cluster from dev plan (single control plane node and single worker node)

    `tkg create cluster test-cluster -p dev --vsphere-controlplane-endpoint 172.31.3.80`

    *note the controlplane IP is an IP address from the same dhcp network that your nodes are deployed on but outside the dhcp scope.  This IP is used by kube-vip to provide a reliable IP to the workload clusters kubernetes API*

    ![alt text](/assets/tkg-create-cluster.png)

- Create a TKG cluster from prod plan with custom node size and number of worker nodes (3 control plane nodes and workers based on command line input)

    `tkg create cluster test-cluster -p prod --controlplane-size large -w 10 --worker-size extra-large --vsphere-control-endpoint 172.31.3.80`

- Pre-configured node sizes
    - small = Cpus: 2, Memory: 2048, Disk: 20
    - medium = Cpus: 2, Memory: 4096, Disk: 40
    - large = Cpus: 2, Memory: 8192, Disk: 40
    - extra-large = Cpus: 4, Memory: 16384, Disk: 80

## Working with TKG Workload clusters

### Exporting TKG workload cluster credentials

1. Get credentials to workload cluster for the first time.  You can either have the credentials merged into the default kubeconfig file in ~/.kube/config or have it exported to a separate file.

**Merge credentials to existing ~/.kube/config**

`tkg get credentials test-cluster`

**Export credentials to separate kubeconfig file**

`tkg get credentials test-cluster --kubeconfig tkgkubeconfig`  
**Note:** if you export to separate file you need to specify the kubeconfig file on all kubectl commands `kubecctl --kubeconfig tkgkubeconfig {command}`

### Accessing TKG workload cluster using kubectl

1. Set kubectl context to workload cluster
`kubectl config set-context test-cluster`
2. View nodes
`kubectl get nodes`
3. View namespaces
`kubectl get ns`
4. View Pods
`kubectl get pods` or `kubectl get pods -A` or `kubectl get pods -n {namespace}`
