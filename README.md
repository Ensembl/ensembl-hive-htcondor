
HTCondor Meadow for eHive
=========================

[![Build Status](https://travis-ci.org/Ensembl/ensembl-hive-htcondor.svg?branch=master)](https://travis-ci.org/Ensembl/ensembl-hive-htcondor)

[eHive](https://travis-ci.org/Ensembl/ensembl-hive) is a system for running computation pipelines on distributed computing resources - clusters, farms or grids.
This repository is the implementation of eHive's _Meadow_ interface for the [HTCondor](https://research.cs.wisc.edu/htcondor/) job scheduler.


Version numbering and compatibility
-----------------------------------

This repository is versioned the same way as eHive itself, and both
checkouts are expected to be on the same branch name to function properly.
* `master` is the development branch and follows eHive's `master`. We
  primarily maintain eHive, so both repos may sometimes go out of sync
  until we upgrade the HTCondor module too
When future stable versions of eHive will be released (named `version/2.5`
etc) we'll create such branches here as well.

The module is continuously tested under HTCondor 8.0.5 as shipped in
Ubuntun 14.04 (Trusty). HTCondor is automatically configured for a
"Personal HTCondor installation" in a docker image that can be found under
[scripts/docker-htcondor/](scripts/docker-htcondor/).


Testing the HTCondor meadow
---------------------------

We ship two Dockerfile. One that merely consists of an Ubuntu image with
HTCondor installed, and one that adds the dependencies needed for eHive.
The former is useful to test HTCondor alone, the latter to test the eHive
integration.

To build the images, you first need to edit the `HIVE_CONDOR_LOCATION` and
`EHIVE_LOCATION` variables in
`scripts/docker-ehive-htcondor-test/Dockerfile`.
Then, run this from the root directory of this repo:

```
./scripts/docker-htcondor/build_docker.sh
./scripts/docker-ehive-htcondor-test/build_docker.sh
```

The images will be named `docker-htcondor` and `docker-ehive-htcondor-test`.
Then instantiate a new container with:

```
./scripts/docker-ehive-htcondor-test/start_docker.sh    # run as normal user on your machine. Will start the image as root and login as condoradmin
source setup_environment.sh                             # run as "condoradmin" on the image. Sets up $EHIVE_ROOT_DIR etc
prove -rv ensembl-hive-htcondor/t                       # run as "condoradmin" on the image. Uses sqlite
```

Both `build_docker.sh` and `start_docker.sh` are simple wrappers around `docker
build` and `docker run`, and you might as well run `docker` directly.


Contributors
------------

This module has been written by [Matthieu Muffato](https://github.com/muffato) (EMBL-EBI) based on the [SGE](https://github.com/Ensembl/ensembl-hive-sge) module.


Contact us
----------

eHive is maintained by the [Ensembl](http://www.ensembl.org/info/about/) project.
We (Ensembl) are only using Platform LSF to run our computation
pipelines, and can only test HTCondor on the Docker image indicated above.

There is eHive users' mailing list for questions, suggestions, discussions and announcements.
To subscribe to it please visit [this link](http://listserver.ebi.ac.uk/mailman/listinfo/ehive-users)

