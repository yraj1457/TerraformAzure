terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      
    }
  }
}

#Terraform Remote backend
/* Uncomment this after creating the first resource group with storage account and containers
terraform {
  backend "azurerm" {
    resource_group_name  = "resourcegrouptohold"
    storage_account_name = "storageaccountremote111"
    container_name       = "storagecontainer111"
    key                  = "abc.tfstate"
  }
}

*/

provider "azurerm" {
  features {}
}

//The resource group to hold the remote backend
resource "azurerm_resource_group" "ab-tf1-rg1" {
  name     = var.ab_tf1_rg1
  location = var.ab_tf1_lc1
}

//Storage account for the container to hold 
resource "azurerm_storage_account" "ab-tf1-sa1" {
  name                     = var.ab_tf1_sa1
  resource_group_name      = var.ab_tf1_rg1
  location                 = var.ab_tf1_lc1
  account_tier             = "Standard"
  account_replication_type = "GRS"
  depends_on = [azurerm_resource_group.ab_tf1_rg1]
}

//Container to hold the tf state file
resource "azurerm_storage_container" "ab-tf1-sc1" {
  name                  = var.ab_tf1_sc1
  storage_account_name  = var.ab_tf1_sa1
  depends_on = [azurerm_resource_group.ab_tf1_rg1,
                azurerm_storage_account.ab_tf1_sa1]
}

//Second resource group to hold the other resources
resource "azurerm_resource_group" "ab-tf1-rg2" {
  name     = var.ab_tf1_rg2
  location = var.ab_tf1_lc1
  depends_on = [azurerm_resource_group.ab_tf1_rg1,
                azurerm_storage_account.ab_tf1_sa1,
                azurerm_storage_container.ab_tf1_sc1]
}

//Virtual netork
resource "azurerm_virtual_network" "ab-tf1-vn1" {
  name                = var.ab_tf1_vn1
  address_space       = var.ab_tf1_vnaddsp1
  location            = var.ab_tf1_lc1
  resource_group_name = var.ab_tf1_rg2
  depends_on = [azurerm_resource_group.ab_tf1_rg2]
}

//Subnet
resource "azurerm_subnet" "ab-tf1-sn1" {
  name                 = var.ab_tf1_sn1
  resource_group_name  = var.ab_tf1_rg2
  virtual_network_name = var.ab_tf1_vn1
  address_prefixes     = var.ab_tf1_snaddp1
  depends_on = [azurerm_resource_group.ab_tf1_rg2,
                azurerm_virtual_network.ab-tf1-vn1]
}

//Network interface to let the virtual machine communicate with other resources and the internet
resource "azurerm_network_interface" "ab-tf1-nic1" {
  name                = var.ab_tf1_nic1
  location            = var.ab_tf1_lc1
  resource_group_name = var.ab_tf1_rg2

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.ab_tf1_sn1
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_resource_group.ab_tf1_rg2,
                azurerm_virtual_network.ab-tf1-vn1,
                azurerm_subnet.ab-tf1-sn1]
}

//Virtual machine
resource "azurerm_windows_virtual_machine" "ab-tf1-vm1" {
  name                = var.ab_tf1_vm1
  resource_group_name = var.ab_tf1_rg2
  location            = var.ab_tf1_lc1
  size                = "Standard_F2"
  admin_username      = var.ab_tf1_user
  admin_password      = var.ab_tf1_pass
  network_interface_ids = [
    azurerm_network_interface.ab-tf1-nic1.id,
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

  depends_on = [azurerm_resource_group.ab_tf1_rg2,
                azurerm_virtual_network.ab-tf1-vn1,
                azurerm_subnet.ab-tf1-sn1,
                azurerm_network_interface.ab-tf1-nic1]
}


