#!/bin/bash
REPO=brunoe
docker build \
	-t ${REPO}/${PWD##*/}:$(git rev-parse --abbrev-ref HEAD|tr '/' '-') \
	$@ \
	.
