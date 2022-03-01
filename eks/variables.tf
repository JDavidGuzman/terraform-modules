variable "name" {
  type = string
}

variable "cluster_subnets" {
  type = list(string)
}

variable "instance_type" {
  type    = list(string)
  default = ["t3.micro"]
}

variable "nodegroup_iam_policy" {
  type    = list(string)
  default = null
}

variable "ingress_controller_serviceaccount" {
  type    = string
  default = null
}