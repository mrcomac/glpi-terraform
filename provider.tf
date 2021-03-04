terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "terraform-state-ifpr-devops"
    key    = "aplicacoes/devops/glpi/terraform.tfstate"
    profile = "default"
  }
}
