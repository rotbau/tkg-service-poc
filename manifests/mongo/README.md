# MongoDB Statefulset Deployment

### Create Storage Class
```kubectl apply -f mongodb-sc.yaml``

### Deploy Mongo Headless Service
```kubectl apply -f mongo-service.yaml```

### Deploy Mongo Statefulset
```kubectl apply -f mongo-statefulset.yaml```

### Define Mongo Replica Set and Administrator
```kubectl exec -it mongod-0 -c mongod-container -- bash```

Bash Shell
$ hostname -f
mongod-0.mongodb-service.default.svc.cluster.local

Mongo Shell
$ mongo

Generate Replica Set
rs.initiate({_id: "MainRepSet", version: 1, members: [
	{ _id: 0, host : "mongod-0.mongodb-service.default.svc.cluster.local:27017" }
]}); 

then verify
rs.status();

Create Admin User
db.getSiblingDB("admin").createUser({
	      user : "admin",
	      pwd  : "admin123",
	      roles: [ { role: "root", db: "admin" } ]
	 });