# IaC for GLPI - an example
**Packer**, **Terraform**, and **GLPI**

## Resources on AWS
**Application Load Balance**,
**EC2 Instances**,
**RDS**,
**CloudWatch**,
**ASG**

## Variables needed on CI/CD settings
* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY
* AWS_REGION
* TF_VAR_app (terraform variable)
* TF_VAR_app_version (terraform variable)
* TF_VAR_project_owner (terraform variable)
* TF_WORKSPACE (terraform workspace)
* TF_VAR_domain_name
* TF_VAR_subdomain

## provider.tf
you need to change S3 address in provider.tf

## note
Every time you run terraform plan a new instance will be planned (there is a power off command in glpi_deploy.tmpl). This instance is for configuring the GLPI database. If you run terraform many times, this instance will be recreated.

To update GLPI you need to decide what kind of approach you will use. If the instances are ephemeral you will need to check if it's a new installation or an update (configure glpi_deploy.tmpl to reflect it).

If your instances are persistent, you will need work with ansible, puppet, salt or other configuration tools.
