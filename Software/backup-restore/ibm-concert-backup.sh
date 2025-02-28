#!/bin/bash

#Get registry & image tag from configmap
IMG_PREFIX=$(kubectl get cm app-build-cfg-cm -n ${INSTANCE_NAMESPACE} -o jsonpath='{.data.IMG_PREFIX}')
IMG_TAG=$(kubectl get cm app-build-cfg-cm -n ${INSTANCE_NAMESPACE} -o jsonpath='{.data.IMG_TAG}')


validate_inputs()
{
    while [ $# -gt 0 ] ; do
      if [[ "$1" == --instance_ns=* ]]
      then
          INSTANCE_NAMESPACE=$(echo $1 | cut -f2 -d=) ;
      fi

      if [[ "$1" == --schedule=* ]]
      then
          SCHEDULE=$(echo $1 | cut -f2 -d=) ;
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


ConcertBackup()

{
cat <<EOF > backup.yaml
kind: CronJob
apiVersion: batch/v1
metadata:
  name: concert-backup
  namespace: ${INSTANCE_NAMESPACE}
spec:
  schedule: "${SCHEDULE}"
  suspend: false
  jobTemplate:
    spec:
      backoffLimit: 6
      template:
        spec:
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
