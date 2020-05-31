# Configure the Microsoft Azure Provider.
provider "azurerm" {
  version = "~>2.0.0"
  subscription_id = ""
  client_id = ""
  client_secret = ""
  tenant_id = ""
  
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "RGMonoVM" {
  name     = "RGMonoVM-resource"
  location = "westeurope"
}

# Create virtual network - "192.168.0.0/16"
resource "azurerm_virtual_network" "Network1" {
  name                = "RGMonoVM-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = "westeurope"
  resource_group_name = "${azurerm_resource_group.RGMonoVM.name}"
}

# Create subnet - "192.168.1.0/24"
resource "azurerm_subnet" "Network2" {
  name                 = "RGMonoVM-subnet1"
  resource_group_name  = "${azurerm_resource_group.RGMonoVM.name}"
  virtual_network_name = "${azurerm_virtual_network.Network1.name}"
  address_prefix       = "192.168.1.0/24"
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "RGMonoVM-PublicIP1"
  location            = "westeurope"
  resource_group_name = "${azurerm_resource_group.RGMonoVM.name}"
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "VMnsg1" {
  name                = "RGMonoVM-VMnsg"
  location            = "${azurerm_resource_group.RGMonoVM.location}"
  resource_group_name = "${azurerm_resource_group.RGMonoVM.name}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "eth0" {
  name                      = "eth0"
  location                  = "${azurerm_resource_group.RGMonoVM.location}"
  resource_group_name       = "${azurerm_resource_group.RGMonoVM.name}"
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${azurerm_subnet.Network2.id}"
    private_ip_address_allocation = "dynamic"
  }
}

# Create a Windows virtual machine
resource "azurerm_windows_virtual_machine" "VMAZ" {
  name                = "VMAZ"
  resource_group_name = "${azurerm_resource_group.RGMonoVM.name}"
  location            = "${azurerm_resource_group.RGMonoVM.location}"
  size                = "Standard_F2"
  computer_name       = "VMAzure"
  admin_username      = "adminuser"
  admin_password      = "Tounkarabala2020!"
  network_interface_ids = [
    "${azurerm_network_interface.eth0.id}"
    ]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "data" {
  name                 = "acctestmd"
  location             = "West US 2"
  resource_group_name  = "${azurerm_resource_group.RGMonoVM.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    environment = "staging"
  }
}