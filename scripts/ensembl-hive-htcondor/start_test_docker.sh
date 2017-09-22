#!/bin/bash

HIVE_CONDOR_LOCATION=$1
EHIVE_LOCATION=$2
DOCKER_NAME=${3:-muffato/ensembl-hive-htcondor}

exec docker run -it -v "$EHIVE_LOCATION:/repo/ensembl-hive" -v "$HIVE_CONDOR_LOCATION:/repo/ensembl-hive-htcondor" "$DOCKER_NAME"

