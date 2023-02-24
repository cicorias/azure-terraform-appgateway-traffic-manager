terraform {
  backend "local" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.31.0"
    }
    whatsmyip = {
      source  = "dewhurstwill/whatsmyip"
      version = "1.0.3"
    }
  }
}

provider "azurerm" {
  features {}
}
