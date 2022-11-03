#!/bin/bash
sudo apt-get update
sudo snap install  docker
sudo snap start docker
sudo usermod -aG docker ubuntu
sudo docker run -p 8080:80 nginx