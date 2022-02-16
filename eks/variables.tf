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