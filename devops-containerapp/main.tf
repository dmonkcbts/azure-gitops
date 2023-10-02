locals {
  environment = "dev"
  location    = "eastus"
  appname     = "doca"

  tags = {
    exp_date   = "12/31/2024"
    Owner_Name = "David Monk"
    dev_repo   = "GitHub/dmonkcbts/azure-gitops"
  }
}

resource "azurerm_resource_group" "doca" {
  name     = "rg-${local.appname}-${local.environment}"
  location = local.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "doca" {
  name                = "law-${local.appname}-${local.environment}"
  location            = azurerm_resource_group.doca.location
  resource_group_name = azurerm_resource_group.doca.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_container_app_environment" "doca" {
  name                       = "caenv-${local.appname}-${local.environment}"
  location                   = azurerm_resource_group.doca.location
  resource_group_name        = azurerm_resource_group.doca.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.doca.id
  tags                       = local.tags
}

#resource "azurerm_container_registry_task" "doca" {
#  name                  = "crtask-${local.appname}-${local.environment}"
#  container_registry_id = azurerm_container_registry.doca.id
#  platform {
#    os = "Linux"
#  }
#
#  docker_step {
#    dockerfile_path      = "Dockerfile.azure-pipelines"
#    context_path         = "https://github.com/Azure-Samples/container-apps-ci-cd-runner-tutorial/"
#    context_access_token = var.pat
#    image_names          = ["azure-pipelines-agent:1.0"]
#  }
#}
#
#resource "azurerm_container_registry_task_schedule_run_now" "load-image" { 
#  container_registry_task_id = azurerm_container_registry_task.doca.id
#}

resource "azurerm_container_registry" "doca" {
  name                = "acr${local.appname}${local.environment}"
  resource_group_name = azurerm_resource_group.doca.name
  location            = azurerm_resource_group.doca.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = local.tags
}

data "azurerm_container_registry_scope_map" "pull_repos" {
  container_registry_name = azurerm_container_registry.doca.name
  name                    = "_repositories_pull"
  resource_group_name     = azurerm_container_registry.doca.resource_group_name
}

resource "azurerm_container_registry_token" "pulltoken" {
  container_registry_name = azurerm_container_registry.doca.name
  name                    = "pulltoken"
  resource_group_name     = azurerm_container_registry.doca.resource_group_name
  scope_map_id            = data.azurerm_container_registry_scope_map.pull_repos.id
}

resource "azurerm_container_registry_token_password" "pulltokenpassword" {
  container_registry_token_id = azurerm_container_registry_token.pulltoken.id

  password1 {
    expiry = timeadd(timestamp(), "24h")
  }
  lifecycle {
    ignore_changes = [password1]
  }
}

resource "azurerm_container_app" "doca" {
  name                         = "ca-${local.appname}-${local.environment}"
  resource_group_name          = azurerm_resource_group.doca.name
  container_app_environment_id = azurerm_container_app_environment.doca.id
  revision_mode                = "Single"
  tags                         = local.tags

  template {
    container {
      name   = "runner"
      image  = "${azurerm_container_registry.doca.login_server}/azure-pipelines-agent:1.0"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  registry {
    server               = azurerm_container_registry.doca.login_server
    username             = azurerm_container_registry_token.pulltoken.name
    password_secret_name = "secname"
  }

  secret {
    name  = "secname"
    value = azurerm_container_registry_token_password.pulltokenpassword.password1[0].value
  }
}
