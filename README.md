
# Terraform Scripts for creating vms in Azure

Terraform script to create 4 vms, with one of them having Public IP for ssh Access


## Deployment

Prereq for running this script is an azure account & we are signed into azure cli. Ensure Terraform is installed on the machines. 
Ensure that the keypair bearing the name: swarmvm & swarmvm.pub is created in the folder that will run the terraform script
To deploy this project run

```bash
  git clone https://github.com/barishandcloud/mongodb.git  
  cd mongodb
  ssh-keygen -b 2048 -t rsa -f swarmvm
  chmod 400 swarmvm
  terraform init
  terraform plan
  terraform apply 
```

This provisions:
one resource group
4 nic - one with public ip
1 security group with rules allowing ssh 
nic to security group association
4 Ubuntu 18.04-LTS servers with Standard_B1s sizing in eastasia Region. The region can be modified in the variables.tf file. 

To change other parameters please alter main.tf accordingly.
terraform output yields the public ip of the machine to ssh.

In order to ssh into vm1
```bash
  ssh -i swarmvm azureuser@<public_ip>
```
Although there are better/more secure alternatives for logging into the other vms, I use a rudimentary method in which I scp the private key into vm1 and from there I ssh into other nodes. This is not production grade and I desist others from using it for anything other than transient vms.
```bash
  scp -i swarmvm swarmvm azureuser@<public_ip>:~  
```
Start a tmux session and synchronize panes after sshing into the three vms: ```setw synchronize-panes  ```
Issue the following commands to initialize the docker swarm:
1) note the ip of all vms: ```ip a ```
2) Edit the /etc/hosts 
```bash
sudo nano /etc/hosts #add the below entries
10.0.1.X swarmvm1 #ip of vm1
10.0.1.X swarmvm2 #ip of vm2
10.0.1.X swarmvm3 #ip of vm3
```
3) ```sudo apt update ```
4) ```sudo apt -y install apt-transport-https ca-certificates curl software-properties-common ```
5) ```curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ```
6) ```sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"```
7) ```sudo apt update ```
8) ```sudo apt-get install -y docker-ce ```
9) ```sudo systemctl start docker ```
10) ```sudo systemctl enable docker ```
11) ```sudo usermod -aG docker $USER ```
12) ```newgrp docker ```
13) Disable synchronize, as the sunsequent command will be issued on distinct vms rather than on collective: ```docker swarm init --advertise-addr 10.0.1.X #ip of vm1 ```
14) the above command yields a join token which needs to issued on vm2 an vm3
15) A ```docker node ls ``` should show the leader node and two worker nodes.
16) The terraform script also deploys a storage account and a file share. Navigate to the file share in Azure GUI Console. Click on the connect icon and select Linux. Copy the bash commands and run them through all three vms. This mounts the file share in ```/mnt/fileshare``` . This will be the persistent store to be used for all containers. 
17) Create directories to be used by the MongoDB replicaset Volumes from any of the three vms: ```mkdir -p /mnt/fileshare/mongo/data1 /mnt/fileshare/mongo/data2 /mnt/fileshare/mongo/data3 ```
18) Create a dir on vm1 and copy the compose file to the dir: ```scp -i swarmvm docker-compose.yml azureuser@<public_ip>:~/temp```
19) Issue the command: ```docker stack deploy --compose-file docker-compose.yml mongo ```, after a wait window of a min or so, a ```docker ps``` should yield 3 containers on three vms.
20) The containers will have a prefix of ```mongo_con*```, make a note of all three container names.
21) Exec into container running on leader node: ```docker exec -it mongo_con1.1.xxxxxx /bin/bash```
22) Issue the cluster initiate command from ```rs-init.sh``` (everything from 3 till end).

This should have bootstrapped a mongodb container replicaset.
