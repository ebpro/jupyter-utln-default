#!/bin/bash
REPO=brunoe
docker build \
	--progress=plain \
	-t ${REPO}/${PWD##*/}:$(git rev-parse --abbrev-ref HEAD|tr '/' '-') \
	$@ \
	.
