# Dockerfile to build a Condor-enabled container

# Better than ubuntu
FROM phusion/baseimage:0.9.18

# set environment variables
ENV HOME /root

# regenerate host ssh keys
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# install required software
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y htcondor man \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# turn off password requirement for sudo groups users
RUN sed -i "s/^\%sudo\tALL=(ALL:ALL)\sALL/%sudo ALL=(ALL) NOPASSWD:ALL/" /etc/sudoers

# add files to container from local directory
ADD docker_condor_init.sh /etc/my_init.d/01_docker_condor_init.sh
ADD condor_config.local /etc/condor/condor_config.local

RUN chmod ug+x /etc/my_init.d/01_docker_condor_init.sh

# install Condor user
RUN useradd -r -m -U -G sudo -d /home/condoradmin -s /bin/bash -c "Docker Condor Admin" condoradmin

# start my_init on execution and pass bash to runit
ENTRYPOINT ["/sbin/my_init", "--"]
CMD ["/bin/bash"]
