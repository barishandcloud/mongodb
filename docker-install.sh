#!/bin/bash
{
#docker_installation
apt-get remove docker docker-engine docker.io containerd runc -y
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"	
apt update -y
apt-cache policy docker-ce 
apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y 
usermod -aG docker ${USER}       
echo "docker successfully installed"
#docker_installation
} | tee -a /tmp/logfile.txt