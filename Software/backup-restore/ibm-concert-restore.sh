#!/bin/bash


print_usage()
{
 cat << EOM
    ibm-concert-restore
    -----
    Perfrom the pre-steps by setting up a PVC called concert-backup-restore-pvc and create a secret backup-secret of the bucket where the data is stored.
    For more details, please refer the Concert documentation.  
    To take the concert backup run ./ibm-concert-backup.sh after exporting below values:
    - --instance_ns
    - --backup_version
    - --backup_timestamp
    - --backup_entity
    Instead of passing the values as command line parameters, you could also export variables to run the script as listed below:

      export INSTANCE_NAMESPACE=<your-namespace>
      export BACKUP_ENTITY=>configdb,appdb,EL or LZ>
      export BACKUP_VERSION=<version of Concert>
      export BACKUP_TIMESTAMP=<timestamp of the backup you want to restore>

      Example:
      export INSTANCE_NAMESPACE=<your-namespace>
      export BACKUP_ENTITY=appdb
      export BACKUP_VERSION=v1.0.5-199-20250111.044001-main
      export BACKUP_TIMESTAMP=20250210_194423

    Run the below restore script 
    ./ibm-concert-restore.sh

    The sample output looks like this below: 
      ... Restoring concert backup ..
      job.batch/concert-restore created

EOM
}



validate_inputs()
{
    while [ $# -gt 0 ] ; do
      if [[ "$1" == --help ]]
      then
        print_usage
        exit 0
      fi
      if [[ "$1" == --instance_ns=* ]]
      then
          INSTANCE_NAMESPACE=$(echo $1 | cut -f2 -d=) ;
      fi

      if [[ "$1" == --backup_entity=* ]]
      then
          BACKUP_ENTITY=$(echo $1 | cut -f2 -d=) ;
      fi
      if [[ "$1" == --backup_version=* ]]
      then
          BACKUP_VERSION=$(echo $1 | cut -f2 -d=) ;
      fi
      if [[ "$1" == --backup_timestamp=* ]]
      then
          BACKUP_TIMESTAMP=$(echo $1 | cut -f2 -d=) ;
      fi

      shift
    done

    if [ "X$INSTANCE_NAMESPACE" == "X" ];
    then
      echo "--instance_ns=<INSTANCE_NAMESPACE> argument is required"
      exit 1
    fi

    if [ "X$BACKUP_ENTITY" == "X" ];
    then
      echo "--backup_entity=<BACKUP_ENTITY> argument is required"
      exit 1
    fi

    if [ "X$BACKUP_VERSION" == "X" ];
    then
      echo "--backup_version=<BACKUP_VERSION> argument is required"
      exit 1
    fi

    if [ "X$BACKUP_TIMESTAMP" == "X" ];
    then
      echo "--backup_timestamp=<BACKUP_TIMESTAMP> argument is required"
      exit 1
    fi
}

validate_inputs "$@"

#Get registry & image tag from configmap
IMG_PREFIX=$(kubectl get cm app-build-cfg-cm -n ${INSTANCE_NAMESPACE} -o jsonpath='{.data.IMG_PREFIX}')
IMG_TAG=$(kubectl get cm app-build-cfg-cm -n ${INSTANCE_NAMESPACE} -o jsonpath='{.data.IMG_TAG}')

RUNASUSER=${USER_ID:-$(kubectl get cm app-cfg-cm -n ${INSTANCE_NAMESPACE} -o jsonpath='{.data.RUNASUSER}')}
RUNASGROUP=${GROUP_ID:-$(kubectl get cm app-cfg-cm -n ${INSTANCE_NAMESPACE} -o jsonpath='{.data.RUNASGROUP}')}
FS_GROUPID=${FS_GROUPID:-$(kubectl get cm app-cfg-cm -n ${INSTANCE_NAMESPACE} -o jsonpath='{.data.FS_GROUPID}')}
SUPP_GROUPID=${SUPP_GROUPID:-$(kubectl get cm app-cfg-cm -n ${INSTANCE_NAMESPACE} -o jsonpath='{.data.SUPP_GROUPID}')}
if [ "X$RUNASUSER" == "X" ];
then
  echo "Please enter USER_ID"
  exit 1
fi
if [ "X$RUNASGROUP" == "X" ];
then
  echo "Please enter GROUP_ID"
  exit 1
fi
if [ "X$FS_GROUPID" == "X" ];
then
  echo "Please enter FS_GROUPID"
  exit 1
fi
if [ "X$SUPP_GROUPID" == "X" ];
then
  echo "Please enter SUPP_GROUPID"
  exit 1
fi

ConcertRestore()

{
cat <<EOF > restore.yaml
kind: Job
apiVersion: batch/v1
metadata:
  name: concert-restore
  namespace: ${INSTANCE_NAMESPACE}
  labels:
    job-name: concert-restore
spec:
  backoffLimit: 6
  suspend: false
  template:
    spec:
      serviceAccount: app-sa
      serviceAccountName: app-sa
      securityContext:
        runAsNonRoot: true
        fsGroupChangePolicy: OnRootMismatch
        fsGroup: ${FS_GROUPID}
        supplementalGroups:
        - ${SUPP_GROUPID}
      restartPolicy: OnFailure
      volumes:
        - name: concert-backup-restore
          persistentVolumeClaim:
            claimName: concert-backup-restore-pvc
        - name: app-cfg-oob-secret-mount
          projected:
            sources:
              - secret:
                  name: app-cfg-oob-secret
                  optional: true
              - secret:
                  name: concert-configdb-creds
                  optional: true
              - secret:
                  name: concert-appdb-creds
                  optional: true
              - secret:
                  name: concert-lzbucket-creds
                  optional: true
              - secret:
                  name: concert-elbucket-creds
                  optional: true
            defaultMode: 420
        - name: backup-secret
          secret:
            secretName: backup-secret
            defaultMode: 420
            optional: true
        - name: app-cfg-internal-tls-mount
          secret:
            secretName: app-cfg-internal-tls
            defaultMode: 420
        - name: tmp
          emptyDir: {}
      containers:
        - resources:
            limits:
              cpu: 1024m
              ephemeral-storage: 512Mi
              memory: 512Mi
            requests:
              cpu: 512m
              ephemeral-storage: 256Mi
              memory: 256Mi
          name: concert-restore-server
          command: ["bash", "-c"]
          securityContext:
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            readOnlyRootFilesystem: true
            runAsUser: ${RUNASUSER}
            runAsGroup: ${RUNASGROUP}
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - name: concert-backup-restore
              mountPath: /mnt/infra/backup
            - name: app-cfg-oob-secret-mount
              readOnly: true
              mountPath: /mnt/infra/app-cfg-oob-secret
            - name: app-cfg-internal-tls-mount
              readOnly: true
              mountPath: /app/tmp/self-signed-ssl
            - name: backup-secret
              mountPath: /mnt/infra/backup-secret
            - name: tmp
              mountPath: /tmp
          terminationMessagePolicy: File
          image: "${IMG_PREFIX}/ibm-roja-py-utils:${IMG_TAG}"
          args: ["/app/bin/backup-restore/restore-from-bucket.sh ${BACKUP_ENTITY} ${BACKUP_VERSION} ${BACKUP_TIMESTAMP}"]

                
EOF

# Apply the restore job to the cluster
kubectl apply -f restore.yaml

}

echo "... Restoring concert backup .."
ConcertRestore
