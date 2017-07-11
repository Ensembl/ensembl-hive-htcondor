#!/bin/sh

exec docker run -it -v "$HOME:$HOME" docker-ehive-htcondor-test

