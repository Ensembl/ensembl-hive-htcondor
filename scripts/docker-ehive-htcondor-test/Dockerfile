# Dockerfile to build a Condor-enabled container with extra packages needed to
# run and test eHive

# Cloned and updated version of our docker-htcondor container
FROM muffato/docker-htcondor

# install required extra software
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
                          # Taken from ensembl-hive's Dockerfile
    && apt-get install -y curl git \
                          sqlite3 libdbd-sqlite3-perl postgresql-client libdbd-pg-perl mysql-client libdbd-mysql-perl libdbi-perl \
                          libcapture-tiny-perl libdatetime-perl libhtml-parser-perl libjson-perl libproc-daemon-perl \
                          libtest-exception-perl libtest-simple-perl libtest-warn-perl libtest-warnings-perl libtest-file-contents-perl libtest-perl-critic-perl libgraphviz-perl \
                          libgetopt-argvfile-perl libchart-gnuplot-perl libbsd-resource-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Location of the ensembl-hive and ensembl-hive-htcondor checkouts on the host
ARG HIVE_CONDOR_LOCATION
ARG EHIVE_LOCATION

# NOTE: We don't have access to $HIVE_CONDOR_LOCATION and $EHIVE_LOCATION
# at build-time, so we can't run cpanm. We hope all the dependencies are
# correctly installed with the above apt-get commands.

# Place symlinks for ensembl-hive and ensembl-hive-htcondor in condoradmin's home directory
RUN ln -s "$HIVE_CONDOR_LOCATION" /home/condoradmin/ensembl-hive-htcondor
RUN ln -s "$EHIVE_LOCATION" /home/condoradmin/ensembl-hive

ENV EHIVE_ROOT_DIR "/home/condoradmin/ensembl-hive"
ENV PATH "/home/condoradmin/ensembl-hive/scripts:$PATH"
ENV PERL5LIB "/home/condoradmin/ensembl-hive/modules:/home/condoradmin/ensembl-hive-htcondor/modules:$PERL5LIB"
ENV EHIVE_TEST_PIPELINE_URLS='sqlite:////home/condoradmin/'

# Since the environment is set for the root user, we need to add the "-p"
# option to transfer it to "condoradmin" (only condoradmin is allowed to
# submit jobs)
CMD ["/bin/login", "-p", "-f", "condoradmin"]
