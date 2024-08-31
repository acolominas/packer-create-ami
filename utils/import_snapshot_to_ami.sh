#!/bin/bash

# Verify input parameters are correct
if [ $# -ne 3 ]; then
    echo "Usage: $0 <bucket_name> <instance_name> <version>"
    exit 1
fi

# Variables
BUCKET_NAME="$1"
INSTANCE_NAME="$2"
VERSION="$3"
REGION=$AWS_REGION
VM_DISK="${INSTANCE_NAME}-${VERSION}-disk001.vmdk"
TODAY=`date +%Y%m%d`
DESCRIPTION="${INSTANCE_NAME}-${VERSION}-v${TODAY}"

# Upload Virtual Machine Disk to S3
echo "Uploading ${VM_DISK} to S3..."
aws s3 cp output/$VM_DISK s3://${BUCKET_NAME}/${INSTANCE_NAME}/${VERSION}/ --region $REGION

if [ $? -eq 0 ]; then
    echo "${VM_DISK} uploaded correctly"
else
    echo "There was an error trying to upload ${VM_DISK} to s3."
    exit 1
fi

# Modificar el archivo JSON y guardarlo en una variable
JSON_CONTENT=$(jq --arg bucket "${BUCKET_NAME}" \
                  --arg description "${DESCRIPTION}" \
                  --arg key "${INSTANCE_NAME}/${VERSION}/${VM_DISK}" \
   '.Description = $description |
   .UserBucket.S3Bucket = $bucket |
   .UserBucket.S3Key = $key' \
   utils/import_template.json)

# Start import snapshot task from S3 uploaded disk
IMPORT_TASK_ID=$(aws ec2 import-snapshot \
  --description "${DESCRIPTION}" \
  --disk-container "${JSON_CONTENT}" \
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

    IMAGE_ID=$(aws ec2 register-image --name "${DESCRIPTION}" \
      --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,SnapshotId=$SNAPSHOT_ID,VolumeType=gp3}" \
      --root-device-name "/dev/sda1" \
      --virtualization-type hvm \
      --architecture x86_64 \
      --ena-support \
      --region $REGION \
      --output text --query 'ImageId')

    echo "AMI created with ID: $IMAGE_ID"
    aws ec2 create-tags --resources $IMAGE_ID --tags Key=Name,Value=$INSTANCE_NAME-$VERSION --region $REGION
else
    echo "Error: The import task of snapshot has not completed correctly. State: $STATUS"
    exit 1
fi

echo "Process finished correclty."
