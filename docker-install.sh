#!/bin/bash
{
apt-get remove docker docker-engine docker.io containerd runc ansible -y
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"	
apt update -y
apt-cache policy docker-ce 
apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y 
usermod -aG docker ${vm_user_id}
echo "docker successfully installed"

echo "Mounting file share on the vms"
echo
echo "Creating smbcreds dir"; mkdir -p /etc/smbcredentials
echo
echo "Creating smbcreds dir and populating vals"; echo "username=${sa_name}" >> /etc/smbcredentials/${sa_name}.cred
 echo "password=${sa_key}" >> /etc/smbcredentials/${sa_name}.cred
sudo chmod 600 /etc/smbcredentials/${sa_name}.cred
echo
echo "Creating file mount dir"; mkdir /mnt/fileshare
echo "fstab entry"; echo "//${sa_name}.file.core.windows.net/fileshare /mnt/fileshare cifs nofail,credentials=/etc/smbcredentials/${sa_name}.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30" >> /etc/fstab
echo
echo "mounting the file share"; mount -t cifs //${sa_name}.file.core.windows.net/fileshare /mnt/fileshare -o credentials=/etc/smbcredentials/${sa_name}.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30
echo 
echo "Operation complete"
} | tee -a /tmp/logfile.txt