# Dockerfile to build a Condor-enabled container with extra packages needed to
# run and test eHive

# Cloned and updated version of our docker-htcondor container
FROM ghcr.io/muffato/docker-htcondor

LABEL org.opencontainers.image.source https://github.com/muffato/ensembl-hive-htcondor

# Clone the ensembl-hive repo and install its dependencies
RUN mkdir /repo \
    && git clone -b version/2.5 https://github.com/Ensembl/ensembl-hive.git /repo/ensembl-hive \
    && /repo/ensembl-hive/docker/setup_os.Ubuntu-14.04.sh \
    && /repo/ensembl-hive/docker/setup_cpan.Ubuntu-14.04.sh /repo/ensembl-hive

