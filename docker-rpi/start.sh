#!/usr/bin/env bash

docker run -it --name qewd --rm -p 3000:8080 -v /home/pi/qewd:/opt/qewd/mapped rtweed/qewd-server-rpi
