#!/bin/bash

# Define targeted variables
export PROJECT_ID=$(gcloud config get-value project)
export CLUSTER_NAME=vllm-zonal-cluster
export ZONE=europe-west2-a

# Create the GKE zonal cluster
gcloud container clusters create $CLUSTER_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --num-nodes=1 \
    --machine-type=e2-highmem-16 \
    --release-channel=stable
