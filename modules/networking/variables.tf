##############################################################
# modules/networking/variables.tf
##############################################################

variable "project_name" { type = string }
variable "vpc_cidr"     { type = string }
variable "azs"          { type = list(string) }
variable "public_cidrs" { type = list(string) }
