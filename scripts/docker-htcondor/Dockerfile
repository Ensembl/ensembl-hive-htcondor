# Dockerfile to build a Condor-enabled container

# Better than ubuntu
FROM phusion/baseimage:0.9.18

# maintained by Ensembl
MAINTAINER Ensembl

# run everything as root to start with
USER root

# set environment variables
ENV HOME /root

# regenerate host ssh keys
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# add pin priority to some graphical packages to stop them installing and borking the build
RUN echo "Package: xserver-xorg*\nPin: release *\nPin-Priority: -1" >> /etc/apt/preferences
RUN echo "Package: unity*\nPin: release *\nPin-Priority: -1" >> /etc/apt/preferences
RUN echo "Package: gnome*\nPin: release *\nPin-Priority: -1" >> /etc/apt/preferences

# Faster when built from abroad
RUN sed -i 's/\/archive.ubuntu.com/\/kr.archive.ubuntu.com/' /etc/apt/sources.list

# install required software as per README.BUILD
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y man htcondor

# add files to container from local directory
ADD docker_condor_init.sh /etc/my_init.d/01_docker_condor_init.sh

RUN chmod ug+x /etc/my_init.d/01_docker_condor_init.sh

# change to home directory
WORKDIR $HOME

# install Condor user
RUN mkdir /opt/condor
RUN useradd -r -m -U -d /home/condoradmin -s /bin/bash -c "Docker Condor Admin" condoradmin
RUN usermod -a -G sudo condoradmin

# return to home directory
WORKDIR $HOME

# clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# start my_init on execution and pass bash to runit
ENTRYPOINT ["/sbin/my_init", "--"]
CMD ["/bin/bash"]