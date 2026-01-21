#!/bin/bash
set -e
if [ -d /tmp/nodejs-ec2-with-codedeploy ]; then
  sudo rm -R /tmp/nodejs-ec2-with-codedeploy
  mkdir /tmp/nodejs-ec2-with-codedeploy
fi