include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.13.0"
}

inputs = {
  name = "acme-dev"
  cidr = "10.10.0.0/16"

  azs             = ["ap-southeast-3a", "ap-southeast-3b"]
  private_subnets = ["10.10.0.0/19", "10.10.32.0/19"]
  public_subnets  = ["10.10.96.0/22", "10.10.100.0/22"]

  enable_nat_gateway = true
  single_nat_gateway = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
}
