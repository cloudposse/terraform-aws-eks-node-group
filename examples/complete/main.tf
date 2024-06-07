provider "aws" {
  region = var.region
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  # This is the preferred way to add attributes. It will put "cluster" last
  # after any attributes set in `var.attributes` or `context.attributes`.
  # In this case, we do not care, because we are only using this instance
  # of this module to create tags.
  attributes = ["cluster"]

  context = module.this.context
}

data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  # https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/deploy/subnet_discovery.md
  tags = { "kubernetes.io/cluster/${module.label.id}" = "shared" }

  allow_all_ingress_rule = {
    key              = "allow_all_ingress"
    type             = "ingress"
    from_port        = 0
    to_port          = 0 # [sic] from and to port ignored when protocol is "-1", warning if not zero
    protocol         = "-1"
    description      = "Allow all ingress"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  allow_http_ingress_rule = {
    key              = "http"
    type             = "ingress"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    description      = "Allow HTTP ingress"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  extra_policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"

  # Enable the IAM user creating the cluster to administer it,
  # without using the bootstrap_cluster_creator_admin_permissions option,
  # as a way to test the access_entry_map feature.
  # In general, this is not recommended. Instead, you should
  # create the access_entry_map statically, with the ARNs you want to
  # have access to the cluster. We do it dynamically here just for testing purposes.
  # See the original PR for more information:
  # https://github.com/cloudposse/terraform-aws-eks-cluster/pull/206
  access_entry_map = {
    (data.aws_iam_session_context.current.issuer_arn) = {
      access_policy_associations = {
        ClusterAdmin = {}
      }
    }
  }
}

module "vpc" {
  source                  = "cloudposse/vpc/aws"
  version                 = "2.2.0"
  ipv4_primary_cidr_block = var.vpc_cidr_block
  context                 = module.this.context
}

module "subnets" {
  source               = "cloudposse/dynamic-subnets/aws"
  version              = "2.4.2"
  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  nat_gateway_enabled  = false
  nat_instance_enabled = false
  context              = module.this.context
}

module "ssh_source_access" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  attributes                 = ["ssh", "source"]
  security_group_description = "Test source security group ssh access only"
  allow_all_egress           = true

  rules = [local.allow_all_ingress_rule]
  # rules_map = { ssh_source = [local.allow_all_ingress_rule] }

  vpc_id = module.vpc.vpc_id

  context = module.label.context
}

module "https_sg" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  attributes                 = ["http"]
  security_group_description = "Allow http access"
  allow_all_egress           = true

  rules = [local.allow_http_ingress_rule]

  vpc_id = module.vpc.vpc_id

  context = module.label.context
}

module "eks_cluster" {
  source                       = "cloudposse/eks-cluster/aws"
  version                      = "4.1.0"
  region                       = var.region
  subnet_ids                   = module.subnets.public_subnet_ids
  kubernetes_version           = var.kubernetes_version
  oidc_provider_enabled        = var.oidc_provider_enabled
  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_log_retention_period = var.cluster_log_retention_period

  access_config = {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  access_entry_map = local.access_entry_map
  context          = module.this.context
}

module "eks_node_group" {
  source = "../../"

  subnet_ids         = module.this.enabled ? module.subnets.public_subnet_ids : ["filler_string_for_enabled_is_false"]
  cluster_name       = module.this.enabled ? module.eks_cluster.eks_cluster_id : "disabled"
  instance_types     = var.instance_types
  desired_size       = var.desired_size
  min_size           = var.min_size
  max_size           = var.max_size
  kubernetes_version = [var.kubernetes_version]
  kubernetes_labels  = merge(var.kubernetes_labels, { attributes = coalesce(join(module.this.delimiter, module.this.attributes), "none") })
  kubernetes_taints  = var.kubernetes_taints

  cluster_autoscaler_enabled = true

  block_device_mappings = [{
    device_name           = "/dev/xvda"
    volume_size           = 20
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }]

  ec2_ssh_key_name              = var.ec2_ssh_key_name
  ssh_access_security_group_ids = [module.ssh_source_access.id]
  associated_security_group_ids = [module.ssh_source_access.id, module.https_sg.id]
  node_role_policy_arns         = [local.extra_policy_arn]
  update_config                 = var.update_config

  after_cluster_joining_userdata = var.after_cluster_joining_userdata

  ami_type            = var.ami_type
  ami_release_version = var.ami_release_version

  before_cluster_joining_userdata = [var.before_cluster_joining_userdata]

  # Ensure ordering of resource creation to eliminate the race conditions when applying the Kubernetes Auth ConfigMap.
  # Do not create Node Group before the EKS cluster is created and the `aws-auth` Kubernetes ConfigMap is applied.
  depends_on = [module.eks_cluster, module.eks_cluster.kubernetes_config_map_id]

  create_before_destroy = true

  force_update_version                 = var.force_update_version
  replace_node_group_on_version_update = var.replace_node_group_on_version_update

  node_group_terraform_timeouts = [{
    create = "40m"
    update = null
    delete = "20m"
  }]

  cluster_cidr = var.vpc_cidr_block

  context = module.this.context
}
