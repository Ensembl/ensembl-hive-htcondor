
export EHIVE_ROOT_DIR=$HOME/ensembl-hive
export PERL5LIB=$EHIVE_ROOT_DIR/modules:$HOME/ensembl-hive-htcondor/modules
export EHIVE_TEST_PIPELINE_URLS='sqlite:///ehive_test_pipeline_db'

echo -e '\n*******************\n* What about running "prove -rv ensembl-hive-htcondor/t" ?\n*******************\n'

