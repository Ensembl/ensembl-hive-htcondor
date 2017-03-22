#!/bin/bash

## This script has to run as root because "/sbin/my_init" (the init system
## of the Docker image) does things that require root permissions

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

# Install some packages inside the container
apt-get update
apt-get install -qqy sqlite3 libdbd-sqlite3-perl libdbi-perl libcapture-tiny-perl libxml-simple-perl libdatetime-perl libjson-perl libtest-exception-perl perl-modules libtest-warn-perl

# It seems that non-root users cannot execute anything from /home/travis
# so we copy the whole directory for the condoradmin user
CONDORADMIN_HOME=/home/condoradmin
cp -a /home/travis/build/muffato/ensembl-hive-htcondor $CONDORADMIN_HOME
chown -R condoradmin: $SGEADMIN_HOME/ensembl-hive-htcondor
sudo --login -u condoradmin $SGEADMIN_HOME/ensembl-hive-htcondor/travisci/run_tests.sh

