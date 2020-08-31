#!/bin/bash

## This script has to run as root because "/sbin/my_init" (the init system
## of the Docker image) does things that require root permissions

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

CONDOR_CHECKOUT_LOCATION=/repo/ensembl-hive-htcondor

# Install extra packages inside the container
export DEBIAN_FRONTEND=noninteractive
$EHIVE_ROOT_DIR/docker/setup_cpan.Ubuntu-16.04.sh $CONDOR_CHECKOUT_LOCATION

sudo --login -u condoradmin $CONDOR_CHECKOUT_LOCATION/travisci/run_tests.sh

