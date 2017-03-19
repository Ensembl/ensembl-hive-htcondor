#!/bin/bash

exec docker run -it -v "$HOME:$HOME" docker-ehive-htcondor-test login -f condoradmin

