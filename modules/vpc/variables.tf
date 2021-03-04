variable "vpc_cdi_block" {
  type = string
  default = "10.0.0.0/16"
}


variable "private_subnet_prefix" {
  type = string
  default = "10.0."
}

variable "public_subnet_prefix" {
  type = string
  default = "10.0"
}

variable "n_public_subnet" {
  type=number
  default = 2
}

variable "n_private_subnet" {
  type = number
  default = 2
}

variable "name_prefix" {
  type = string
}

variable "default_tags" {
  type = map
}
