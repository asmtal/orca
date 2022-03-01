locals {
  region = "eu-central-1"
}

# Create VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create EKS cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = "my-cluster"
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cluster_addons = {
    coredns = {}
    kube-proxy = {}
    vpc-cni = {}
  }

  vpc_id     = "vpc-028f1b3bd83e11f42"
  subnet_ids = ["subnet-0c934be6f825a47db", "subnet-00ecb50e9edd3b21c", "subnet-03d86d12dcda887c8"]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type                     = "AL2_x86_64"
    disk_size                    = 50
    instance_types               = ["m5a.large"]
    iam_role_additional_policies = ["arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"]
  }

  eks_managed_node_groups = {
    default-pool = {
      min_size     = 1
      max_size     = 5
      desired_size = 3
    }
  }

  cluster_security_group_additional_rules = {
    ingress_api_control_plane = {
      description                = "Allow 443 ingress to control plane"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_node_security_group = false
      cidr_blocks                = ["10.0.0.0/16"]
    }
  }

  node_security_group_additional_rules = {
    egress_http = {
      description      = "Node http egress"
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
    }
    egress_pgsql = {
      description      = "Node pgsql egress"
      protocol         = "tcp"
      from_port        = 5432
      to_port          = 5432
      type             = "egress"
      cidr_blocks      = ["10.0.0.0/16"]
    }
    ingress_nginx_admission_controller = {
      description      = "Ingress to Nginx admission controller"
      protocol         = "tcp"
      from_port        = 8443
      to_port          = 8443
      type             = "ingress"
      cidr_blocks      = ["10.0.0.0/16"]
    }
    ingress_app = {
      description      = "Allow traffic to app pods"
      protocol         = "tcp"
      from_port        = 5000
      to_port          = 5000
      type             = "ingress"
      cidr_blocks      = ["10.0.0.0/16"]
    }
    egress_app = {
      description      = "Allow traffic to app pods"
      protocol         = "tcp"
      from_port        = 5000
      to_port          = 5000
      type             = "egress"
      cidr_blocks      = ["10.0.0.0/16"]
    }
    ingress_jenkins_svc = {
      description      = "Jenkins internode communications"
      protocol         = "tcp"
      from_port        = 8080
      to_port          = 8080
      type             = "ingress"
      cidr_blocks      = ["10.0.0.0/16"]
    }
    egress_jenkins_svc = {
      description      = "Jenkins internode communications"
      protocol         = "tcp"
      from_port        = 8080
      to_port          = 8080
      type             = "egress"
      cidr_blocks      = ["10.0.0.0/16"]
    }
    ingress_jenkins_agent = {
      description      = "Jenkins internode communications"
      protocol         = "tcp"
      from_port        = 50000
      to_port          = 50000
      type             = "ingress"
      cidr_blocks      = ["10.0.0.0/16"]
    }
    egress_jenkins_agent = {
      description      = "Jenkins internode communications"
      protocol         = "tcp"
      from_port        = 50000
      to_port          = 50000
      type             = "egress"
      cidr_blocks      = ["10.0.0.0/16"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Add RDS (Postgres)
module "db_default" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "myrds"

  create_db_option_group    = false
  create_db_parameter_group = false

  engine               = "postgres"
  engine_version       = "14.1"
  family               = "postgres14"
  major_engine_version = "14"
  instance_class       = "db.m5.large"

  allocated_storage = 10

  db_name  = "mydb"
  username = "candidate"
  port     = 5432

  vpc_security_group_ids = [module.rds_sg.security_group_id]
  create_db_subnet_group = true
  subnet_ids             = ["subnet-0c934be6f825a47db", "subnet-00ecb50e9edd3b21c", "subnet-03d86d12dcda887c8"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Security group for RDS access
module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "allow-rds"
  description = "Complete PostgreSQL security group"
  vpc_id      = "vpc-028f1b3bd83e11f42"

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
