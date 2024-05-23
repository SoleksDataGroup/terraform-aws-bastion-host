// Module: aws/bastion-host
// Descriprion: module input variables
//

variable "vpc_id" {
  description = "Bastion host VPC ID"
  type = string
  default = ""
}

variable "name_prefix" {
  description = "Bastion host name prefix"
  type = string
  default = "bastion-host"
}

variable "ami_name" {
  description = "Bastion host AMI name"
  type = string
  default = ""
}

variable "instance_type" {
  description = "Bastion host instance type"
  type = string
  default = ""
}

variable "subnet_ids" {
  description = "Bastion host subnet IDs"
  type = list(string)
  default = []
}

variable "dns_zone_id" {
  description = "Bastion host DNS zone id"
  type = string
  default = ""
}

variable "tags" {
  description = "Nomad agent resources tags"
  type = map
  default = {}
}

variable "security_group_ingress" {
  description = "Ingress traffic security rules"
  type = list(object({
    protocol = string
    from_port = number
    to_port = number
    cidr_blocks = optional(list(string))
    description = optional(string)
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids = optional(list(string))
    security_groups = optional(list(string))
    self = optional(string)
  }))
  default = []
}

variable "security_group_egress" {
  description = "Engress traffic security rules"
  type = list(object({
    protocol = string
    from_port = number
    to_port = number
    cidr_blocks = optional(list(string))
    description = optional(string)
    ipv6_cidr_blocks = optional(list(string))
    prefix_list_ids = optional(list(string))
    security_groups = optional(list(string))
    self = optional(string)
  }))
  default = []
}
