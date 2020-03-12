provider "azurerm" {
  features {}
}

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
  reply_urls                 = [
                                  "https://${azurerm_app_service.uts-qbot-questions.default_site_hostname}/app-silent-end",
                                  "https://${azurerm_app_service.uts-qbot-dashboard.default_site_hostname}/app-silent-end"
                                ]
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
  application_object_id = azuread_application.uts-qbot-graph.id
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

/* Commenting this out for now, there is a PR (https://github.com/terraform-providers/terraform-provider-azurerm/pull/5778#pullrequestreview-371544928)
   that will add the required block to the schema to support api_properties as needed by QnAMaker.
resource azurerm_cognitive_account "uts-qbot" {
  name                = var.deployment_name
  location            = "westus" # https://github.com/microsoft/botframework-solutions/issues/1454
  resource_group_name = azurerm_resource_group.uts-qbot.name
  kind                = "QnAMaker"
  api_properties = {
    endpoint            = "https://${var.deployment_name}-cognitiveservices.azure.com/qnamaker/v4.0"
  }
  sku_name = "S0"
}
*/

resource random_string "uts-qbot" {
  length = 8
  special = false
  upper = false
}

resource azurerm_storage_account "uts-qbot" {
  name                     = replace("${var.deployment_name}${random_string.uts-qbot.result}", "-", "")
  /*
  'Error: name ("uts-qbot") can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long'
  This replace function needs to be rewritten to capture the above rule in its entirety. This is a hack to get past the default
  name used in variables.tf
  */
  resource_group_name      = azurerm_resource_group.uts-qbot.name
  location                 = azurerm_resource_group.uts-qbot.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource azurerm_function_app "uts-qbot" {
  name                      = "${var.deployment_name}-function"
  location                  = azurerm_resource_group.uts-qbot.location
  resource_group_name       = azurerm_resource_group.uts-qbot.name
  app_service_plan_id       = azurerm_app_service_plan.uts-qbot.id
  storage_connection_string = azurerm_storage_account.uts-qbot.primary_connection_string
}