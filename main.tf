resource "random_pet" "rg-name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg-name.id
  location = var.resource_group_location
}

#storage account
resource "azurerm_storage_account" "storageaccount" {
  name                     = "mongopocsa01062022"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "share" {
  name                 = "fileshare"
  storage_account_name = azurerm_storage_account.storageaccount.name
  quota                = 50
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "vm1pip" {
  name                = "vm1pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "mynsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*" #"223.186.36.170"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "between-inbound"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }
  security_rule {
    name                       = "between-outbound"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }
}

# Create network interface
resource "azurerm_network_interface" "b_nic" {
  name                = "b_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.vm1pip.id
  }
}

variable "ip_addresses" {
  default = [
    "10.0.1.11",
    "10.0.1.12",
    "10.0.1.13",
  ]
}

variable "vm_username" {
  default = "azureuser"
}

resource "azurerm_network_interface" "nic" {
  name  = "nic${count.index}"
  count = length(var.ip_addresses)

  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nicconfiguration${count.index}"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = element(var.ip_addresses, count.index)
  }
}

/*
resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.11"
  }
}

resource "azurerm_network_interface" "nic2" {
  name                = "nic2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.12"
  }
}

resource "azurerm_network_interface" "nic3" {
  name                = "nic3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.13"
  }
}
*/

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "b_nic_assoc" {
  network_interface_id      = azurerm_network_interface.b_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nic_assoc" {
  count                     = length(var.ip_addresses)
  network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.nsg.id
}

/*
resource "azurerm_network_interface_security_group_association" "nic_assoc1" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nic_assoc2" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nic_assoc3" {
  network_interface_id      = azurerm_network_interface.nic3.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
*/


# Create virtual machine
resource "azurerm_linux_virtual_machine" "bastion" {
  name                  = "bastion"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.b_nic.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "basOsDisk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "mongovm"
  admin_username                  = var.vm_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm_username
    public_key = file("swarmvm.pub")
  }
}

/*
data "template_file" "script_run" {
  template = file("docker-install.sh")
}
*/

locals {
  vars = {
    sa_name = azurerm_storage_account.storageaccount.name
  }
}


data "template_file" "script_run" {
  template = templatefile("docker-install.sh",
    {
      vm_user_id = var.vm_username,
      sa_name    = "${azurerm_storage_account.storageaccount.name}",
      sa_key     = "${nonsensitive(azurerm_storage_account.storageaccount.primary_access_key)}"
    }
  )
}


resource "azurerm_linux_virtual_machine" "vm" {
  depends_on = [
    azurerm_storage_account.storageaccount
  ]
  count                 = length(var.ip_addresses)
  name                  = "swarmvm${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)] #["${element(azurerm_network_interface.nic.*.id, count.index)}"] #["${azurerm_network_interface.nic[count.index].id}"] 
  size                  = "Standard_B1s"

  os_disk {
    name                 = "OsDisk${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "swarmvm${count.index}"
  admin_username                  = var.vm_username
  disable_password_authentication = true

  custom_data = base64encode(data.template_file.script_run.rendered)

  admin_ssh_key {
    username   = var.vm_username
    public_key = file("swarmvm.pub")
  }
}

/*
resource "azurerm_linux_virtual_machine" "vm2" {
  depends_on = [
    azurerm_storage_account.storageaccount
  ]
  name                  = "swarmvm2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic2.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "myOsDisk3"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "swarmvm2"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  custom_data = base64encode(data.template_file.script_run.rendered)

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("swarmvm.pub")
  }  
}

resource "azurerm_linux_virtual_machine" "vm3" {
  depends_on = [
    azurerm_storage_account.storageaccount
  ]
  name                  = "swarmvm3"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic3.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "myOsDisk4"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "swarmvm3"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  custom_data = base64encode(data.template_file.script_run.rendered)

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("swarmvm.pub")
  }  
}
*/