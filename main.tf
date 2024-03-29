resource "random_pet" "rg-name" {
  prefix = var.resource_group_name_prefix
}

resource "random_id" "id" {
	  byte_length = 5
}

resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg-name.id
  location = var.resource_group_location
}

#storage account
resource "azurerm_storage_account" "storageaccount" {
  name                     = "sa${random_id.id.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "share" {
  name                 = "swarmfileshare"
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
    source_address_prefix      = "*" #"223.227.13.102"
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
resource "azurerm_network_interface" "bas_nic" {
  name                = "bas_nic"
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

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "bnic_assoc" {
  network_interface_id      = azurerm_network_interface.bas_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

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


data "template_file" "script_run" {
  template = templatefile("docker-install.sh",
    {
      vm_user_id = "azureuser",
      sa_name    = azurerm_storage_account.storageaccount.name,
      sa_key     = sensitive(azurerm_storage_account.storageaccount.primary_access_key)
    }
  )
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "bastion" {
  name                  = "bastion"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.bas_nic.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "basdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "bastion"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  custom_data = base64encode(data.template_file.script_run.rendered)

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("swarmvm.pub")
  }
}


resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "swarmvm1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "myOsDisk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "swarmvm1"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  custom_data = base64encode(data.template_file.script_run.rendered)

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("swarmvm.pub")
  }
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                  = "swarmvm2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic2.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "myOsDisk2"
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
  name                  = "swarmvm3"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic3.id]
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

  computer_name                   = "swarmvm3"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  custom_data = base64encode(data.template_file.script_run.rendered)

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("swarmvm.pub")
  }  
}
