variable "name" {
  type = string
  default = "sit"
}
variable "aws_region" {
  type = string
  default = "us-east-1"
}
variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}
variable "public_subnets" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "az_count" {
  type = number
  default = 2
}
variable "container_insights" {
  type = bool
  default = true
}
