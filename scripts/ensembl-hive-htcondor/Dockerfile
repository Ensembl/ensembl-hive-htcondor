# Dockerfile to build a Condor-enabled container with extra packages needed to
# run and test eHive

# Cloned and updated version of our docker-htcondor container
FROM docker.pkg.github.com/muffato/ensembl-hive-htcondor/docker-htcondor

# Clone the repos
RUN mkdir /repo \
    && git clone -b version/2.5 https://github.com/Ensembl/ensembl-hive.git /repo/ensembl-hive \
    && git clone -b version/2.5 https://github.com/Ensembl/ensembl-hive-htcondor.git /repo/ensembl-hive-htcondor

# Install all the dependencies
RUN /repo/ensembl-hive/docker/setup_os.Ubuntu-14.04.sh \
    && /repo/ensembl-hive/docker/setup_cpan.Ubuntu-14.04.sh /repo/ensembl-hive /repo/ensembl-hive-htcondor

