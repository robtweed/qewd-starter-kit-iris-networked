#!/usr/bin/env bash

docker run -it --name qewd --rm -p 3000:8080 -v /home/ubuntu/qewd:/opt/qewd/mapped rtweed/qewd-server
