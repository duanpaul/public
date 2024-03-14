# q: what does resource "azurerm_virtual_machine_extension" "custom_script" do?
# a: It creates a custom script extension for a virtual machine.
# q: how to list all available extensions for an azure virtual machine?
# a: az vm extension image list --location <location> --publisher Microsoft.Compute --name CustomScript
# q: what is BGInfo extension for?
# a: It displays useful information on the desktop background.
# q: pls provide an example of how to use the BGInfo extension.
# a: resource "azurerm_virtual_machine_extension" "bginfo" {
#    name                 = "bginfo"
#    virtual_machine_id   = azurerm_virtual_machine.example.id
#    publisher            = "Microsoft.Compute"
#    type                 = "BGInfo"
#    type_handler_version = "1.0"
#    settings = <<SETTINGS
#        {
#            "image": "https://mystorageaccount.blob.core.windows.net/mycontainer/bginfo.bgi",
#            "update": "30",
#            "customField1": "customValue1",
#            "customField2": "customValue2"
#        }





terraform {
    backend "local" {}
}

provider "azurerm" {
    features {}
}

resource "azurerm_virtual_machine_extension" "custom_script" {
    name                 = "custom-script-extension"
    virtual_machine_id   = azurerm_virtual_machine.example.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"

    settings = <<SETTINGS
        {
                "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File C:\\path\\to\\script.ps1"
        }
    SETTINGS

    protected_settings = <<PROTECTED_SETTINGS
        {
                "storageAccountName": "your_storage_account_name",
                "storageAccountKey": "your_storage_account_key"
        }
    PROTECTED_SETTINGS
}

resource "azurerm_virtual_machine" "example" {
    name                  = "example-machine"
    location              = azurerm_resource_group.example.location
    resource_group_name   = azurerm_resource_group.example.name
    network_interface_ids = [azurerm_network_interface.example.id]
    vm_size               = "Standard_DS1_v2"

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }

    storage_os_disk {
        name              = "myosdisk1"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "hostname"
        admin_username = "testadmin"
        admin_password = "Password1234!"
    }

    os_profile_windows_config {
        provision_vm_agent = true
    }
}

resource "azurerm_network_interface" "example" {
    name                = "example-nic"
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.example.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_subnet" "example" {
    name                 = "internal"
    resource_group_name  = azurerm_resource_group.example.name
    virtual_network_name = azurerm_virtual_network.example.name
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_virtual_network" "example" {
    name                = "example-network"
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    address_space       = ["10.0.0.0/16"]
}

resource "azurerm_resource_group" "example" {
    name     = "example-resources"
    location = "East US"
}

