# Dockerfile to build a Condor-enabled container with extra packages needed to
# test eHive

# Cloned and updated version of our docker-htcondor container
FROM docker-htcondor

# maintained by Ensembl
MAINTAINER Ensembl

# run everything as root to start with
USER root

# install required extra software
RUN apt-get update -y
RUN apt-get install -y sqlite3 libdbd-sqlite3-perl libdbi-perl libcapture-tiny-perl libxml-simple-perl libdatetime-perl libjson-perl libtest-exception-perl perl-modules libtest-warn-perl
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Location of the ensembl-hive and ensembl-hive-condor checkouts on the host
ARG HIVE_CONDOR_LOCATION
ARG EHIVE_LOCATION

# Place symlinks for ensembl-hive and ensembl-hive-condor in condoradmin's home directory
RUN ln -s "$HIVE_CONDOR_LOCATION" /home/condoradmin/ensembl-hive-condor
RUN ln -s "$EHIVE_LOCATION" /home/condoradmin/ensembl-hive
RUN ln -s ensembl-hive-condor/scripts/docker-ehive-htcondor-test/setup_environment.sh /home/condoradmin/

# start my_init on execution and pass bash to runit
ENTRYPOINT ["/sbin/my_init", "--"]
CMD ["/bin/bash"]
