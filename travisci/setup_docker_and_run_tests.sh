#!/bin/bash

## This script has to run as root because "/sbin/my_init" (the init system
## of the Docker image) does things that require root permissions

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

# It seems that non-root users cannot execute anything from /home/travis
# so we copy the whole directory for the condoradmin user
CONDORADMIN_HOME=/home/condoradmin
cp -a /home/travis/build/Ensembl/ensembl-hive-htcondor $CONDORADMIN_HOME
CONDOR_CHECKOUT_LOCATION=$CONDORADMIN_HOME/ensembl-hive-htcondor
chown -R condoradmin: $CONDOR_CHECKOUT_LOCATION
HIVE_CHECKOUT_LOCATION=$CONDOR_CHECKOUT_LOCATION/ensembl-hive

# Install extra packages inside the container
export DEBIAN_FRONTEND=noninteractive
$HIVE_CHECKOUT_LOCATION/docker/setup_cpan.Ubuntu-16.04.sh $CONDOR_CHECKOUT_LOCATION

sudo --login -u condoradmin $CONDOR_CHECKOUT_LOCATION/travisci/run_tests.sh

