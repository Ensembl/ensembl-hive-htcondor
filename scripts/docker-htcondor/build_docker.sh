#!/bin/bash

THIS_PATH=$(dirname "$(readlink -f "$0")")
cd "$THIS_PATH"
docker build -t docker-htcondor .

