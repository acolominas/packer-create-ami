#!/bin/bash

# Verify input parameters are correct
if [ $# -ne 4 ]; then
    echo "Usage: $0 <bucket_name> <vm_output> <instance_name> <region>"
    exit 1
fi

# Variables
BUCKET_NAME="$1"
VM_OUTPUT="$2"
INSTANCE_NAME="$3"
REGION="$4"

# Upload Virtual Machine Disk to S3
echo "Uploading Virtual Machine Disk to S3..."
aws s3 cp output/$VM_OUTPUT s3://$BUCKET_NAME/ --region $REGION

# Start import snapshot task from S3 uploaded disk
IMPORT_TASK_ID=$(aws ec2 import-snapshot \
  --description $INSTANCE_NAME \
  --disk-container file://scripts/import_opnsense.json \
  --region $REGION \
  --output text \
  --query 'ImportTaskId')

echo "Import task started with ID: $IMPORT_TASK_ID"

# Check import task progress
STATUS="active"
while [ "$STATUS" == "active" ]; do
    echo "Waiting for the import to finish... (It may take several minutes)"
    sleep 60
    STATUS=$(aws ec2 describe-import-snapshot-tasks --import-task-ids $IMPORT_TASK_ID \
      --region $REGION \
      --output text \
      --query "ImportSnapshotTasks[0].SnapshotTaskDetail.Status")
done

# Register an AMI from imported snapshot
if [ "$STATUS" == "completed" ]; then
    SNAPSHOT_ID=$(aws ec2 describe-import-snapshot-tasks --import-task-ids $IMPORT_TASK_ID \
      --region $REGION \
      --output text \
      --query "ImportSnapshotTasks[0].SnapshotTaskDetail.SnapshotId")

    echo "Snapshot import task completed correctly with Snapshot ID: $SNAPSHOT_ID"
    echo "Creating AMI from Snapshot..."

    IMAGE_ID=$(aws ec2 register-image --name "$INSTANCE_NAME" \
      --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,SnapshotId=$SNAPSHOT_ID,VolumeType=gp3}" \
      --root-device-name "/dev/sda1" \
      --virtualization-type hvm \
      --architecture x86_64 \
      --ena-support \
      --region $REGION \
      --output text --query 'ImageId')

    echo "AMI created with ID: $IMAGE_ID"
    aws ec2 create-tags --resources $IMAGE_ID --tags Key=Name,Value=$INSTANCE_NAME --region $REGION
else
    echo "Error: The import task of snapshot has not completed correctly. State: $STATUS"
fi

echo "Process finished correclty."
