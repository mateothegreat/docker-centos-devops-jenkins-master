#!/bin/bash

docker rm -f jenkins-master

docker run -id   \
                -v /var/jenkins_home \
                -p 8081:8080 -p 50001:50000 \
                --name jenkins-master \
                appsoa/docker-centos-devops-jenkins-master:1.0

