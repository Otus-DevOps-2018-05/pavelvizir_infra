#!/usr/bin/bash
gcloud compute instances create reddit-app \
--boot-disk-size=11GB \
--image-family=reddit-full \
--image-project=infra-207711 \
--machine-type=f1-micro \
--tags=puma-server \
--restart-on-failure
