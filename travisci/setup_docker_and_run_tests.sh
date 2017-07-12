#!/bin/bash

## This script has to run as root because "/sbin/my_init" (the init system
## of the Docker image) does things that require root permissions

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

# Install some packages inside the container
apt-get update
# Taken from ensembl-hive's Dockerfile
apt-get install -y cpanminus git build-essential \
		  sqlite3 libdbd-sqlite3-perl postgresql-client libdbd-pg-perl mysql-client libdbd-mysql-perl libdbi-perl \
		  libcapture-tiny-perl libdatetime-perl libhtml-parser-perl libjson-perl libproc-daemon-perl \
		  libtest-exception-perl libtest-simple-perl libtest-warn-perl libtest-warnings-perl libtest-file-contents-perl libtest-perl-critic-perl libgraphviz-perl \
		  libgetopt-argvfile-perl libchart-gnuplot-perl libbsd-resource-perl

# It seems that non-root users cannot execute anything from /home/travis
# so we copy the whole directory for the condoradmin user
CONDORADMIN_HOME=/home/condoradmin
cp -a /home/travis/build/muffato/ensembl-hive-htcondor $CONDORADMIN_HOME
CONDOR_CHECKOUT_LOCATION=$CONDORADMIN_HOME/ensembl-hive-htcondor
chown -R condoradmin: $CONDOR_CHECKOUT_LOCATION

# Install the missing dependencies (if any)
cpanm --installdeps --with-recommends $CONDOR_CHECKOUT_LOCATION/ensembl-hive
cpanm --installdeps --with-recommends $CONDOR_CHECKOUT_LOCATION

sudo --login -u condoradmin $CONDOR_CHECKOUT_LOCATION/travisci/run_tests.sh

