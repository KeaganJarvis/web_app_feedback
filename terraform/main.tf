# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
  backend "azurerm" {
        resource_group_name  = "tfstate"
        storage_account_name = "tfstate32554" # This is a globally unique account
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }
}
provider "azurerm" {
  features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "mvp_web_app_group" {
    name     = "myResourceGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "mvp_web_app_network" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.mvp_web_app_group.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "mvp_web_app_subnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.mvp_web_app_group.name
    virtual_network_name = azurerm_virtual_network.mvp_web_app_network.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "mvp_web_app_publicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.mvp_web_app_group.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "mvp_web_app_nsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.mvp_web_app_group.name

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

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "mvp_web_app_nic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.mvp_web_app_group.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.mvp_web_app_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.mvp_web_app_publicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg_nic_association" {
    network_interface_id      = azurerm_network_interface.mvp_web_app_nic.id
    network_security_group_id = azurerm_network_security_group.mvp_web_app_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.mvp_web_app_group.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mvp_web_app_storageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.mvp_web_app_group.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create (and display) an SSH key
resource "tls_private_key" "mvp_web_app_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { # TODO is it necessary to display this?
    value = tls_private_key.mvp_web_app_ssh.private_key_pem
    sensitive = true
}

data "template_file" "cloud-init-template" {
  template = "${file("cloud-init.tpl")}"

}
data "template_cloudinit_config" "cloud-init-config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud-init-template.rendered}"
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "mvp_web_app_vm" {
    name                  = "VMForWebAppMVP"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.mvp_web_app_group.name
    network_interface_ids = [azurerm_network_interface.mvp_web_app_nic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS" # 20.04 gave error : The platform image 'Canonical:UbuntuServer:20.04-LTS:latest' is not available.
        version   = "latest"
    }

    custom_data = "${data.template_cloudinit_config.cloud-init-config.rendered}"

    computer_name  = "VMForWebAppMVP"
    admin_username = "azureuser" # leaving this as generic user name, TODO consider changing?
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser" # leaving this as generic user name, TODO consider changing?
        public_key     = tls_private_key.mvp_web_app_ssh.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mvp_web_app_storageaccount.primary_blob_endpoint
    }
    tags = {
        environment = "MVP web App"
    }
}


# resource "azurerm_virtual_machine_extension" "chefSoloInstall" { # chose this cause quick to dev, other options: use `custom_data` to run `cloud-init` OR pre building image with packer.
#     name                 = "chefSoloDeploy"
#     virtual_machine_id   = azurerm_linux_virtual_machine.mvp_web_app_vm.id
#     publisher            = "Microsoft.Azure.Extensions"
#     type                 = "CustomScript"
#     type_handler_version = "2.0"

#     settings = <<SETTINGS
#         {
#             "commandToExecute": "wget https://packages.chef.io/files/stable/chef-workstation/21.9.613/ubuntu/18.04/chef-workstation_21.9.613-1_amd64.deb && dpkg -i chef-workstation_21.9.613-1_amd64.deb"
#         }
#     SETTINGS

#     tags = {
#         environment = "MVP web App"
#     }
# }