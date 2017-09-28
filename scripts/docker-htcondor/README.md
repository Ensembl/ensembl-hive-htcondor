
This container is a _Personal installation_ (i.e. single node) of HTCondor.  The installation is based on [phusion/baseimage](https://hub.docker.com/r/phusion/baseimage/) as it manages the services [better](http://phusion.github.io/baseimage-docker/).  The version of HTCondor is 8.0.5 as shipped in Ubuntun 14.04 (Trusty).

As _root_ is not allowed to submit jobs to HTCondor, the default user is _condoradmin_ (which has _sudo_-capabilities). To use it, just do:

```
docker run -it ensemblorg/docker-htcondor
```

Otherwise, to open a _root_-session, do

```
docker run -it ensemblorg/docker-htcondor /bin/bash
```

Contributors
------------

This module has been written by [Matthieu Muffato](https://github.com/ensemblorg) (EMBL-EBI).

