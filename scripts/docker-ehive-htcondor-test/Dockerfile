# Dockerfile to build a Condor-enabled container with extra packages needed to
# test eHive

# Cloned and updated version of our docker-htcondor container
FROM docker-htcondor

# install required extra software
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y sqlite3 libdbd-sqlite3-perl libdbi-perl libcapture-tiny-perl libxml-simple-perl libdatetime-perl libjson-perl libtest-exception-perl perl-modules libtest-warn-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Location of the ensembl-hive and ensembl-hive-htcondor checkouts on the host
ARG HIVE_CONDOR_LOCATION
ARG EHIVE_LOCATION

# Place symlinks for ensembl-hive and ensembl-hive-htcondor in condoradmin's home directory
RUN ln -s "$HIVE_CONDOR_LOCATION" /home/condoradmin/ensembl-hive-htcondor
RUN ln -s "$EHIVE_LOCATION" /home/condoradmin/ensembl-hive
RUN ln -s ensembl-hive-htcondor/scripts/docker-ehive-htcondor-test/setup_environment.sh /home/condoradmin/

# start my_init on execution and pass bash to runit
ENTRYPOINT ["/sbin/my_init", "--"]
CMD ["/bin/bash"]
