# Dockerfile to build a Condor-enabled container with extra packages needed to
# run and test eHive

# Cloned and updated version of our docker-htcondor container
FROM muffato/docker-htcondor

# install required extra software
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
                          # Taken from ensembl-hive's Dockerfile
    && apt-get install -y cpanminus git build-essential \
                          sqlite3 libdbd-sqlite3-perl postgresql-client libdbd-pg-perl mysql-client libdbd-mysql-perl libdbi-perl \
                          libcapture-tiny-perl libdatetime-perl libhtml-parser-perl libjson-perl libproc-daemon-perl \
                          libtest-exception-perl libtest-simple-perl libtest-warn-perl libtest-warnings-perl libtest-file-contents-perl libtest-perl-critic-perl libgraphviz-perl \
                          libgetopt-argvfile-perl libchart-gnuplot-perl libbsd-resource-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN mkdir /repo \
    && git clone -b master https://github.com/Ensembl/ensembl-hive.git /repo/ensembl-hive \
    && git clone -b master https://github.com/muffato/ensembl-hive-htcondor.git /repo/ensembl-hive-htcondor

# Install the missing dependencies (if any)
RUN cpanm --installdeps --with-recommends /repo/ensembl-hive
RUN cpanm --installdeps --with-recommends /repo/ensembl-hive-htcondor

ENV EHIVE_ROOT_DIR "/repo/ensembl-hive/"
ENV PATH "/repo/ensembl-hive/scripts:$PATH"
ENV PERL5LIB "/repo/ensembl-hive/modules:/repo/ensembl-hive-htcondor/modules:$PERL5LIB"

# Since the environment is set for the root user, but root is not allowed
# to submit jobs, we need to login as condoradmin and preserve the environment
CMD ["/bin/login", "-p", "-f", "condoradmin"]
