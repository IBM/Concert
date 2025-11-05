#!/bin/bash
#Get registry & image tag from configmap


print_usage()
{
cat << EOM
    ibm-concert-backup
    -----
   Perfrom the pre-steps by setting up a PVC called `concert-backup-restore-pvc` and create a secret `backup-secret` of the backup bucket.
   For more details, please refer the Concert documentation.  
   To take the concert backup run ./ibm-concert-backup.sh after exporting below values:
   - --instance_ns
   - --schedule

    Instead of passing the values as command line parameters, you could also export variables to run the script as listed below:
    Eg: 

    export INSTANCE_NAMESPACE=<your-namespace>
    export SCHEDULE=<schedule-value>

  To schedule the cronjob refer k8s documentation. You can set the cronjob for once a night or twice a day etc with this. [Schedule K8s Job](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#writing-a-cronjob-spec)

  Here's an example of schedule to run a job once a night at midnight. 

  Eg: schedule: "0 0 * * *"


  The script picks up USERID, GROUPID, FS_GROUPID and SUPP_GROUPID from app-cfg-cm config map that is generated at the time of deployment.
  It would run into error, if any of the values are missing in app-cfg-cm.  If you run into error, please verify app-cfg-cm configmap. 
  

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

      if [[ "$1" == --schedule=* ]]
      then
          SCHEDULE="${1#*=}"
      fi     
      shift
    done


    if [ "X$INSTANCE_NAMESPACE" == "X" ];
    then
      echo "--instance_ns=<INSTANCE_NAMESPACE> argument is required"
      exit 1
    fi

    if [ "X$SCHEDULE" == "X" ];
    then
      echo "--schedule=<SCHEDULE> argument is required"
      exit 1
    fi
}
validate_inputs "$@"

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

ConcertBackup()

{
cat <<EOF > backup.yaml
kind: CronJob
apiVersion: batch/v1
metadata:
  name: concert-backup
  namespace: ${INSTANCE_NAMESPACE}
spec:
  schedule: "$SCHEDULE"
  suspend: false
  jobTemplate:
    spec:
      backoffLimit: 6
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
              terminationMessagePath: /dev/termination-log
              name: concert-backup
              command:
                - /app/bin/backup-restore/backup-dbs-buckets.sh
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
                - name: app-cfg-oob-secret-mount
                  readOnly: true
                  mountPath: /mnt/infra/app-cfg-oob-secret
                - name: app-cfg-internal-tls-mount
                  readOnly: true
                  mountPath: /app/tmp/self-signed-ssl
                - name: concert-backup-restore
                  mountPath: /mnt/infra/backup
                - name: backup-secret
                  mountPath: /mnt/infra/backup-secret
                - name: tmp
                  mountPath: /tmp
              terminationMessagePolicy: File
              envFrom:
                - configMapRef:
                    name: app-cfg-cm
                - configMapRef:
                    name: app-build-cfg-cm
                    optional: true
              image: "${IMG_PREFIX}/ibm-roja-py-utils:${IMG_TAG}"
                
EOF

# Apply the backup job to the cluster
kubectl apply -f backup.yaml

}

echo "... Taking concert backup .."
ConcertBackup
