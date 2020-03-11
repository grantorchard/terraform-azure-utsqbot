provider "azurerm" {
  features {}
}

/*
data aws_route53_zone "this" {
  name         = var.dns_zone_name
  private_zone = false
}

resource "aws_route53_record" "qbot" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${var.deployment_name}.${var.dns_zone_name}"
  type    = "A"
  ttl     = 300
}
*/


resource azurerm_resource_group "uts-qbot" {
  name     = var.deployment_name
  location = var.deployment_location
}

resource azurerm_app_service_plan "uts-qbot" {
  name                = var.deployment_name
  location            = azurerm_resource_group.uts-qbot.location
  resource_group_name = azurerm_resource_group.uts-qbot.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource azurerm_app_service "uts-qbot-api" {
  name                = "${var.deployment_name}-api"
  location            = azurerm_resource_group.uts-qbot.location
  resource_group_name = azurerm_resource_group.uts-qbot.name
  app_service_plan_id = azurerm_app_service_plan.uts-qbot.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }
}

resource azurerm_app_service "uts-qbot-dashboard" {
  name                = "${var.deployment_name}-dashboard"
  location            = azurerm_resource_group.uts-qbot.location
  resource_group_name = azurerm_resource_group.uts-qbot.name
  app_service_plan_id = azurerm_app_service_plan.uts-qbot.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }
}

resource azurerm_app_service "uts-qbot-questions" {
  name                = "${var.deployment_name}-questions"
  location            = azurerm_resource_group.uts-qbot.location
  resource_group_name = azurerm_resource_group.uts-qbot.name
  app_service_plan_id = azurerm_app_service_plan.uts-qbot.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

}

resource azurerm_sql_server "uts-qbot" {
  name                         = var.deployment_name
  resource_group_name          = azurerm_resource_group.uts-qbot.name
  location                     = var.deployment_location
  version                      = "12.0"
  administrator_login          = var.database_administrator_username
  administrator_login_password = var.database_administrator_password
}

resource azurerm_sql_database "uts-qbot" {
  name                = var.deployment_name
  resource_group_name = azurerm_resource_group.uts-qbot.name
  location            = var.deployment_location
  server_name         = azurerm_sql_server.uts-qbot.name

  tags = {
    environment = "production"
  }
}

resource azurerm_sql_firewall_rule "uts-qbot" {
  name                = var.deployment_name
  resource_group_name = azurerm_resource_group.uts-qbot.name
  server_name         = azurerm_sql_server.uts-qbot.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource azuread_application "uts-qbot-api" {
  name = "${var.deployment_name}-api"
  homepage                   = "https://${azurerm_app_service.uts-qbot-api.default_site_hostname}"
  identifier_uris            = []
  reply_urls                 = ["https://${azurerm_app_service.uts-qbot-questions.default_site_hostname}/app-silent-end","https://${azurerm_app_service.uts-qbot-dashboard.default_site_hostname}/app-silent-end"]
  available_to_other_tenants = true
  oauth2_allow_implicit_flow = true
  type                       = "webapp/api"
}

resource azuread_application "uts-qbot-graph" {
  name                       = "${var.deployment_name}-graph"
  identifier_uris            = []
  reply_urls                 = []
  available_to_other_tenants = true
  oauth2_allow_implicit_flow = true
  type                       = "webapp/api"
  public_client              = true
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # This app_id is the MS Graph API
    resource_access {
      id = "4e46008b-f24c-477d-8fff-7bb4ec7aafe0"
      type = "Scope" # Note that 'Scope' is 'Delegated', and Application is 'Role'
    }
    resource_access {
      id = "89fe6a52-be36-487e-b7d8-d061c450a026"
      type = "Scope"
    }
    resource_access {
      id = "a154be20-db9c-4678-8ab7-66f6cc099a59"
      type = "Scope"
    }
  }
}

resource random_password "uts-qbot-graph" {
  length = 32
  special = true
}


resource azuread_application_password "uts-qbot-graph" {
  application_id = azuread_application.uts-qbot-graph.object_id
  value          = random_password.uts-qbot-graph.result
  end_date       = timeadd(timestamp(), "8766h")
  lifecycle {
    ignore_changes = [end_date]
  }
}

resource azuread_application "uts-qbot-registration" {
  name = "${var.deployment_name}-api"
  identifier_uris            = []
  reply_urls                 = []
  available_to_other_tenants = true
  oauth2_allow_implicit_flow = true
  type                       = "webapp/api"
}

resource azurerm_bot_channels_registration "uts-qbot" {
  name                = var.deployment_name
  location            = "Global"
  resource_group_name = azurerm_resource_group.uts-qbot.name
  sku                 = "F0"
  microsoft_app_id    = azuread_application.uts-qbot-registration.id
  endpoint            = "https://${azurerm_app_service.uts-qbot-questions.default_site_hostname}/api/messages"
}

resource azurerm_cognitive_account "uts-qbot" {
  name                = var.deployment_name
  location            = azurerm_resource_group.uts-qbot.location
  resource_group_name = azurerm_resource_group.uts-qbot.name
  kind                = "QnAMaker"

  sku_name = "S0"

  tags = {
    Acceptance = "Test"
  }
}