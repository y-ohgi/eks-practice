
terraform {}

provider "aws" {
  region = "ap-northeast-1"
}

variable "name" {
  default = "search"
}

module "vpc" {
  source = "git::https://github.com/y-ohgi/tf-vpc.git?ref=v1.0.0"

  name               = "${var.name}"
  single_nat_gateway = true

  tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
  }
}

output "eks" {
  description = "Please use this command to build an EKS cluster."
  value       = "eksctl create cluster --name ${var.name} --vpc-public-subnets ${join(",", module.vpc.public_subnets)} --vpc-private-subnets ${join(",", module.vpc.private_subnets)} -f config.yaml"
}
