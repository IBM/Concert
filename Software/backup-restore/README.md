
# IBM  Concert Backup and Restore Script
Backup and restore requires a shared volume PersistentVolumeClaim (PVC) to be created and bounded to the cluster. You can create a PVC from a storage class. Ensure that the PV is a shared volume with the ReadWriteMany access mode.

## Creating a PVC from a storage class
The following example creates yaml file that is named concert-backup-restore-pvc.yaml. You use this yaml file to create an NFS volume that is named concert-backup-restore-pvc. The PVC is created by using the storage class managed-nfs-storage.

cat <<EOF > concert-backup-restore-pvc.yaml

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
      storage: 200Gi
EOF
```

After creating the yaml , run the following to create PVC 

```
export INSTANCE_NAMESPACE=<your-namespace>
oc apply -f concert-backup-restore-pvc.yaml -n ${INSTANCE_NAMESPACE}
```

For more information about storage classes that IBM Concert supports, see [Storage considerations](https://www.ibm.com/docs/en/concert?topic=requirements-storage-considerations).

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

Once your cronjob completed the back up , it will be stored in the path /mnt/infra/backup/ folder. 
Eg: /mnt/infra/backup/v1.0.3-141-20241016.114004-main/20241106_125702 . Here backup of your data  will be stored in the timestamp folder. 


## Restore concert backup

Export variables to run the script
Eg: 
BACKUP_ENTITY can be configdb,appdb,EL and LZ

```

 export INSTANCE_NAMESPACE=<your-namespace>
 export BACKUP_ENTITY=appdb
 export BACKUP_LOCATION=/mnt/infra/backup/v1.0.3-141-20241016.114004-main/20241106_125702

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


## To suspend/resume the backup cronjob
To suspend/resume the backup cronjob set the value true/false respectively. 

```
kubectl patch cronjob concert-backup -n ${INSTANCE_NAMESPACE} --type=json -p '[{"op": "replace", "path": "/spec/suspend", "value": true}]'
```

## To kill the job once it's completes the restore. 

```
kubectl delete job concert-restore -n ${INSTANCE_NAMESPACE}
```

