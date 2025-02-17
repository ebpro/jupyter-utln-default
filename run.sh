#!/usr/bin/env bash

WORKDIR=$HOME/JUPYTER_WORK
IMAGE_REPO=brunoe
IMAGE=docker.io/${IMAGE_REPO}/${PWD##*/}:${ENV:+$ENV-}$(git rev-parse --abbrev-ref HEAD|tr '/' '-') 

docker run --rm -it \
    --user root --name ${PWD##*/} \
    --volume jupyter-workdir:/home/jovyan/work \
    ${IMAGE} $@
