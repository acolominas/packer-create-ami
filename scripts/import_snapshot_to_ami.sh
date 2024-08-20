#!/bin/bash

# Verificar que se reciban todos los parámetros necesarios
#./import_snapshot_to_ami.sh acolominas-vmimport OPNsense-24.7-disk001.vmdk OPNsense-24.7 eu-west-1
if [ $# -ne 4 ]; then
    echo "Uso: $0 <bucket_name> <vm_output> <instance_name> <region>"
    exit 1
fi

# Variables - Asignadas a partir de los argumentos de entrada
BUCKET_NAME="$1"
VM_OUTPUT="$2"
INSTANCE_NAME="$3"
REGION="$4"

# Subir la máquina virtual a S3
echo "Subiendo la máquina virtual a S3..."
aws s3 cp output/$VM_OUTPUT s3://$BUCKET_NAME/ --region $REGION

# Iniciar la importación de la máquina virtual
IMPORT_TASK_ID=$(aws ec2 import-snapshot \
  --description $INSTANCE_NAME \
  --disk-container file://scripts/import_opnsense.json \
  --region $REGION \
  --output text \
  --query 'ImportTaskId')

echo "Importación iniciada con ID: $IMPORT_TASK_ID"

# Monitorear el progreso de la importación
STATUS="active"
while [ "$STATUS" == "active" ]; do
    echo "Esperando que termine la importación... (Puede tomar varios minutos)"
    sleep 60
    STATUS=$(aws ec2 describe-import-snapshot-tasks --import-task-ids $IMPORT_TASK_ID \
      --region $REGION \
      --output text \
      --query "ImportSnapshotTasks[0].SnapshotTaskDetail.Status")
done

# Crear una AMI a partir del snapshot importado
if [ "$STATUS" == "completed" ]; then
    SNAPSHOT_ID=$(aws ec2 describe-import-snapshot-tasks --import-task-ids $IMPORT_TASK_ID \
      --region $REGION \
      --output text \
      --query "ImportSnapshotTasks[0].SnapshotTaskDetail.SnapshotId")

    echo "Importación del snapshot completada con Snapshot ID: $SNAPSHOT_ID"
    echo "Creando la AMI a partir del Snapshot..."

    IMAGE_ID=$(aws ec2 register-image --name "$INSTANCE_NAME" \
      --block-device-mappings "DeviceName=/dev/sda1,Ebs={SnapshotId=$SNAPSHOT_ID}" \
      --root-device-name "/dev/sda1" \
      --virtualization-type hvm \
      --architecture x86_64 \
      --ena-support \
      --region $REGION \
      --output text --query 'ImageId')

    echo "AMI creada con ID: $IMAGE_ID"
    aws ec2 create-tags --resources $IMAGE_ID --tags Key=Name,Value=$INSTANCE_NAME --region $REGION
else
    echo "Error: La importación del snapshot no se completó correctamente. Estado: $STATUS"
fi

echo "Proceso terminado."
