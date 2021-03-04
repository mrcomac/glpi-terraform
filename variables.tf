variable "key_par" {
  type=string
  default= "marcos-programatic"
}

variable "ami_owner" {
  type =string
  default = "111517649812"
}

variable "db_user" {
  type = string
  default = "glpi_user"
}

variable "db_password" {
  type = string
  default = "glpi_passworD_user"
}

variable "db_name" {
  type = string
  default = "glpi_db"
}

#variables needed as Input from gitlab

variable "ami_packer_name" {
  type =string
  default = "ami-ifpr-glpi-packer"
}

variable "zone_id" {
  type = string
  default ="Z09076131IOPDDZ9W4PL7"
}

variable "domain_name" {
  type = string
  default = "ifpr-devops.ga"
}

variable "subdomain" {
  type = string
  default = "glpi"
}

variable "project_owner" {
  type = string
}
variable "app" {
  type = string
}

variable "git_revision" {
  type = string
  sensitive=false
}
variable "app_version" {
  type = string
}

locals {
  n_instances = terraform.workspace == "prod" ? 5 : 1
  instance_size = terraform.workspace == "prod" ? "t3.large" : "t3.micro"

  db_instance_size = terraform.workspace == "prod" ? "db.t2.micro": "db.t2.micro"
  db_snapshot_final = terraform.workspace == "prod" ? "glpi-rds-snapshot-prod-final" : "glpi-rds-snapshot-test-final"

  name_prefix = "tf-ifpr-glpi"
  default_tags = {
    ProjectOwner = var.project_owner
    GeneratedBy= "terraform"
    Environment = terraform.workspace
    App = var.app
    AppVersion = var.app_version
    GitRevision = var.git_revision
  }
}
