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

      if [[ "$1" == --backup_entity=* ]]
      then
          BACKUP_ENTITY=$(echo $1 | cut -f2 -d=) ;
      fi

      if [[ "$1" == --backup_location=* ]]
      then
          BACKUP_LOCATION=$(echo $1 | cut -f2 -d=) ;
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

    if [ "X$BACKUP_LOCATION" == "X" ];
    then
      echo "--backup_location=<BACKUP_LOCATION> argument is required"
      exit 1
    fi
}

validate_inputs "$@"


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
          name: concert-restore-server
          command:
            - /app/bin/backup-restore/restore-db-bucket.sh
          securityContext:
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
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
          terminationMessagePolicy: File
          image: "${IMG_PREFIX}/ibm-roja-py-utils:${IMG_TAG}"
          args:
            - ${BACKUP_ENTITY}
            - ${BACKUP_LOCATION}

                
EOF

# Apply the restore job to the cluster
kubectl apply -f restore.yaml

}

echo "... Restoring concert backup .."
ConcertRestore
