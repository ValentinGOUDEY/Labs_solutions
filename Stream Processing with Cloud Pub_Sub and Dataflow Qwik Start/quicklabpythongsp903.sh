


gcloud config set compute/region $REGION

gcloud services disable dataflow.googleapis.com
gcloud services enable dataflow.googleapis.com
gcloud services enable cloudscheduler.googleapis.com

sleep 20

PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="${PROJECT_ID}-bucket"
TOPIC_ID=my-id

gsutil mb gs://$BUCKET_NAME

gcloud pubsub topics create $TOPIC_ID

if [ "$REGION" == "us-central1" ]; then
  gcloud app create --region us-central
elif [ "$REGION" == "europe-west1" ]; then
  gcloud app create --region europe-west
else
  gcloud app create --region "$REGION"
fi

gcloud scheduler jobs create pubsub publisher-job --schedule="* * * * *" \
    --topic=$TOPIC_ID --message-body="Hello!"

sleep 60

gcloud scheduler jobs run publisher-job --location=$REGION

sleep 60

gcloud scheduler jobs run publisher-job --location=$REGION

cat > automate_commands.sh <<EOF_END
#!/bin/bash

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
cd python-docs-samples/pubsub/streaming-analytics
pip install -U -r requirements.txt
python PubSubToGCS.py \
--project=$PROJECT_ID \
--region=$REGION \
--input_topic=projects/$PROJECT_ID/topics/$TOPIC_ID \
--output_path=gs://$BUCKET_NAME/samples/output \
--runner=DataflowRunner \
--window_size=2 \
--num_shards=2 \
--temp_location=gs://$BUCKET_NAME/temp
EOF_END

chmod +x automate_commands.sh


docker run -it -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID -e BUCKET_NAME=$BUCKET_NAME -e PROJECT_ID=$PROJECT_ID -e REGION=$REGION -e TOPIC_ID=$TOPIC_ID -v $(pwd)/automate_commands.sh:/automate_commands.sh python:3.7 /bin/bash -c "/automate_commands.sh"
