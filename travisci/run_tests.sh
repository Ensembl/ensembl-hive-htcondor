#!/bin/bash

## This script runs as a normal user (condoradmin) because the default
## configuration of Condor does not allow root to submit any jobs

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

#BUILD_DIR=/home/condoradmin/ensembl-hive-htcondor
BUILD_DIR=/home/travis/build/Ensembl/ensembl-hive-htcondor
#cd $BUILD_DIR
export EHIVE_ROOT_DIR=/repo/ensembl-hive
export PERL5LIB=$EHIVE_ROOT_DIR/modules:$BUILD_DIR/modules
export EHIVE_TEST_PIPELINE_URLS='sqlite:///ehive_test_pipeline_db'
export EHIVE_MEADOW_TO_TEST=HTCondor

prove -rv --ext .t --ext .mt $BUILD_DIR/t "$EHIVE_ROOT_DIR/t/04.meadow/meadow-longmult.mt"

