

resource "azurerm_virtual_machine_extension" "install_ad" {
    name                 = "install_ad"
  #  resource_group_name  = azurerm_resource_group.main.name
    virtual_machine_id   = azurerm_windows_virtual_machine.dc01.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.9"
  
    protected_settings = <<SETTINGS
    {    
      "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.ADDS.rendered)}')) | Out-File -filepath ADDS.ps1\" && powershell -ExecutionPolicy Unrestricted -File ADDS.ps1 -Domain_DNSName ${data.template_file.ADDS.vars.Domain_DNSName} -Domain_NETBIOSName ${data.template_file.ADDS.vars.Domain_NETBIOSName} -SafeModeAdministratorPassword ${data.template_file.ADDS.vars.SafeModeAdministratorPassword}"
    }
    SETTINGS
  }
  
  #Variable input for the ADDS.ps1 script
  data "template_file" "ADDS" {
      template = "${file("ADDS.ps1")}"
      vars = {
          Domain_DNSName          = "${var.Domain_DNSName}"
          Domain_NETBIOSName      = "${var.netbios_name}"
          SafeModeAdministratorPassword = "${var.SafeModeAdministratorPassword}"
    }
  }

  # to join an azure vm to the domain
  resource "azurerm_virtual_machine_extension" "join_domain" {
    name                 = "join_domain"
    virtual_machine_id   = azurerm_windows_virtual_machine.dc02.id
    publisher            = "Microsoft.Compute"
    type                 = "JsonADDomainExtension"
    type_handler_version = "1.3"
  
    settings = <<SETTINGS
    {
      "Name": "${local.domain_name}",
      "OUPath": "OU=MyBusiness,DC=contoso,DC=com",
      "User": "${var.domain_admin_username}",
      "Restart": "true",
      "Options": "3"
    }
    SETTINGS
  }
```

# to get an existing virtual network and subnets in azure



# to install and config citrix storefront server on azure vm
resource "azurerm_virtual_machine_extension" "install_citrix_storefront" {
  name                 = "install_citrix_storefront"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc02.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.CitrixStorefront.rendered)}')) | Out-File -filepath CitrixStorefront.ps1\" && powershell -ExecutionPolicy Unrestricted -File CitrixStorefront.ps1 -StorefrontURL ${var.storefront_url} -StorefrontPort ${var.storefront_port} -StorefrontSiteName ${var.storefront_site_name}"
  }
  SETTINGS
}

data "template_file" "CitrixStorefront" {
  template = "${file("CitrixStorefront.ps1")}"
  vars = {
    storefront_url       = "${var.storefront_url}"
    storefront_port      = "${var.storefront_port}"
    storefront_site_name = "${var.storefront_site_name}"
  }
}
