#!/bin/sh

RUNNER_CONTAINER_ID=$1
RUNNER_TAG=$2
GITLAB_RUNNER_REG_TOKEN=$3
GITLAB_SERVER_HOST=$4

GITLAB_SUBNET=$(docker network ls | grep gitlab_ce | cut -d " " -f 4)

echo "Registering ...";

docker exec -it $RUNNER_CONTAINER_ID bash -c 'gitlab-runner register \
  --non-interactive \
  --executor "shell" \
  --docker-image alpine:latest \
  --url "'$GITLAB_SERVER_HOST'" \
  --registration-token "'$GITLAB_RUNNER_REG_TOKEN'" \
  --description "docker-'$RUNNER_TAG'-runner" \
  --maintenance-note "Docker runner for gitlab-ce" \
  --tag-list "docker,'$RUNNER_TAG'" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected" \
  echo "    network_mode = \"'$GITLAB_SUBNET'\"" >> /etc/gitlab-runner/config.toml'; 

echo "Done"
