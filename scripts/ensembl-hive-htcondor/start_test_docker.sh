#!/bin/bash

docker_name=${1:-muffato/ensembl-hive-htcondor}

HIVE_CONDOR_LOCATION=
EHIVE_LOCATION=

exec docker run -it -v "$EHIVE_LOCATION:/repo/ensembl-hive" -v "$HIVE_CONDOR_LOCATION:/repo/ensembl-hive-htcondor" "$docker_name"

