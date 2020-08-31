#!/bin/bash

## This script runs as a normal user (condoradmin) because the default
## configuration of Condor does not allow root to submit any jobs

# Stop the script at the first failure
set -e

echo "DEBUG: Environment of $0"; env; id; echo "END_DEBUG"

CONDOR_CHECKOUT_LOCATION=/repo/ensembl-hive-htcondor
export EHIVE_ROOT_DIR=/repo/ensembl-hive
export PERL5LIB=$EHIVE_ROOT_DIR/modules:$CONDOR_CHECKOUT_LOCATION/modules
export EHIVE_TEST_PIPELINE_URLS='sqlite:///ehive_test_pipeline_db'
export EHIVE_MEADOW_TO_TEST=HTCondor

prove -rv --ext .t --ext .mt $CONDOR_CHECKOUT_LOCATION/t "$EHIVE_ROOT_DIR/t/04.meadow/meadow-longmult.mt"

