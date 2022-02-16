variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "subnetting" {
  type = number
}

variable "eks" {
  type    = bool
  default = false
}

variable "eks_cluster_name" {
  type    = string
  default = null
}
