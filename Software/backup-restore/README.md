
# IBM  Concert Backup and Restore Script
Backup and restore requires a shared volume PersistentVolumeClaim (PVC) to be created and bounded to the cluster. You can create a PVC from a storage class. Ensure that the PV is a shared volume with the ReadWriteMany access mode.

## Creating a PVC from a storage class
The following example creates yaml file that is named concert-backup-restore-pvc.yaml. You use this yaml file to create an NFS volume that is named concert-backup-restore-pvc. The PVC is created by using the storage class managed-nfs-storage.

cat concert-backup-restore-pvc.yaml

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: concert-backup-restore-pvc 
spec:
  storageClassName: managed-nfs-storage 
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
```

After creating the yaml , run the following to create PVC 

```
export INSTANCE_NAMESPACE=<your-namespace>
oc apply -f concert-backup-restore-pvc.yaml -n ${INSTANCE_NAMESPACE}
```

For more information about storage classes that IBM Concert supports, see [Storage considerations](https://www.ibm.com/docs/en/concert?topic=requirements-storage-considerations).


User need to create backup-secret with below bucket details. 

```
BACKUP_HOST:
BACKUP_PORT:
BACKUP_BUCKET:
BACKUP_ACCESS_KEY:
BACKUP_SECRET_KEY:
BACKUP_SECURE:

```

Example : 

```
apiVersion: v1
kind: Secret
metadata:
  name: backup-secret
  namespace: <your-namespace>
data:
  BACKUP_BUCKET: eW91ci1idWNrZXQtbmFtZQo=
  BACKUP_HOST: eW91ci1idWNrZXQtaG9zdAo=
  BACKUP_SECRET_KEY: YnVja2V0LXNlY3JldC1rZXkK
  BACKUP_PORT: cG9ydAo=
  BACKUP_ACCESS_KEY: YWNjZXNzLWtleQo=
  BACKUP_SECURE: dHJ1ZQo=
type: Opaque

```

## Take concert backup

To take concert backup run ./ibm-concert-backup.sh after exporting the namespace and schedule. To schedule the cronjob refer k8s documentation. You can set the cronjob for once a night or twice a day etc with this. [Schedule K8s Job](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#writing-a-cronjob-spec)

Here's an example of schedule to run a job once a night at midnight. 

```
Eg: schedule: "0 0 * * *"
```

Export variables to run the script

Eg: 

```
export INSTANCE_NAMESPACE=<your-namespace>
export SCHEDULE=<schedule-value>
```

Run the below backup script 

```
./ibm-concert-backup.sh

```

The sample output looks like this below: 

```
... Taking concert backup ..
cronjob.batch/concert-backup configured
```

Once your cronjob completed the back up will be stored in the timestamp folder in your bucket. 
Eg: v1.0.5-199-20250111.044001-main/20250210_194423/backup.tar.gz

## To suspend/resume the backup cronjob
To suspend/resume the backup cronjob set the value true/false respectively. 

```
kubectl patch cronjob concert-backup -n ${INSTANCE_NAMESPACE} --type=json -p '[{"op": "replace", "path": "/spec/suspend", "value": true}]'
```

## Restore concert backup

Export variables to run the script
Eg: 
BACKUP_ENTITY can be configdb,appdb,EL and LZ

```

 export INSTANCE_NAMESPACE=<your-namespace>
 export BACKUP_ENTITY=appdb
 export BACKUP_VERSION=v1.0.5-199-20250111.044001-main
 export BACKUP_TIMESTAMP=20250210_194423
```

Run the below backup script 
```
 ./ibm-concert-restore.sh
```

The sample output looks like this below: 
```
  ... Restoring concert backup ..
  job.batch/concert-restore created

```


## To kill the job once it's completes the restore. 

```

kubectl delete job concert-restore -n ${INSTANCE_NAMESPACE}

```
Note : Once the restore is finished, please use the command __*kubectl delete*__ to kill the existing job and run the restore again for any other db or bucket. We are taking the backup for the entire db or buckets, while restore only needs for specific reasons. 




