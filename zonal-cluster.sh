# Define targeted variables
export PROJECT_ID=$(gcloud config get-value project)
export CLUSTER_NAME=vllm-zonal-cluster
export ZONE=us-central1-a

# Create the cluster explicitly inside us-central1-a
gcloud container clusters create $CLUSTER_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --num-nodes=1 \
    --machine-type=e2-standard-16 \
    --release-channel=stable
