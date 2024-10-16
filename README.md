
HTCondor Meadow for eHive
=========================

> [!IMPORTANT]  
> As per eHive version 2.7.0, all the meadows other than `SLURM` and `Local` are deprecated and not supported anymore.
> This repository should remain in sync with eHive's `version/2.6`, as we do not plan to apply any change to it.
> The `main` branch is expected to go out of sync over time as we apply changes to eHive.
>
> Please, do not hesitate to contact us, should this be a problem.

[![Build Status](https://travis-ci.org/Ensembl/ensembl-hive-htcondor.svg?branch=version/2.6)](https://travis-ci.org/Ensembl/ensembl-hive-htcondor)

[eHive](https://github.com/Ensembl/ensembl-hive) is a system for running computation pipelines on distributed computing resources - clusters, farms or grids.
This repository is the implementation of eHive's _Meadow_ interface for the [HTCondor](https://research.cs.wisc.edu/htcondor/) job scheduler.


Version numbering and compatibility
-----------------------------------

This repository is versioned the same way as eHive itself, and both
checkouts are expected to be on the same branch name to function properly.
* `version/2.5`, `version/2.6`, etc. are stable branches that work with eHive's branches
  of the same name. These branches are _stable_ and _only_ receive bugfixes.
* `main` is the development branch and follows eHive's `main`. We
  primarily maintain eHive, so both repos may sometimes go out of sync
  until we upgrade the HTCondor module too


Testing the HTCondor meadow
---------------------------

The module is continuously tested under HTCondor 8.0.5 as shipped in
Ubuntun 14.04 (Trusty) thanks to the Docker infrastructure.
We provide two Docker images:

1. [ensemblorg/docker-htcondor](https://hub.docker.com/r/ensemblorg/docker-htcondor/)
   This container only adds HTCondor to a service-oriented Ubuntu.
2. [ensemblorg/ensembl-hive-htcondor](https://hub.docker.com/r/ensemblorg/ensembl-hive-htcondor/)
   This container extends ensemblorg/docker-htcondor by adding the
   ensembl-hive and ensembl-hive-htcondor repositories (and their
   dependencies)

The latter can be used to test new versions of the code by running
``scripts/ensembl-hive-htcondor/start_test_docker.sh``. The script
will start a new ``ensemblorg/ensembl-hive-htcondor`` container with
your own copies of ensembl-hive and ensembl-hive-htcondor mounted.

```
scripts/ensembl-hive-htcondor/start_test_docker.sh /path/to/your/ensembl-hive /path/to/your/ensembl-hive-htcondor name_of_docker_image

```

The last argument can be skipped and defaults to `ensemblorg/ensembl-hive-htcondor`.

Contributors
------------

This module has been written by [Matthieu Muffato](https://github.com/ensemblorg) (EMBL-EBI).


Contact us
----------

eHive is maintained by the [Ensembl](http://www.ensembl.org/info/about/) project.
We (Ensembl) are only using SLURM to run our computation
pipelines, and can only test HTCondor on the Docker image indicated above.

There is eHive users' mailing list for questions, suggestions, discussions and announcements.
To subscribe to it please visit [this link](http://listserver.ebi.ac.uk/mailman/listinfo/ehive-users)

