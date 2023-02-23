provider "aws" {
  region = var.region
}

module "label" {
  source  = "cloudposse/label/null"
  #version = "0.25.0"

  # This is the preferred way to add attributes. It will put "cluster" last
  # after any attributes set in `var.attributes` or `context.attributes`.
  # In this case, we do not care, because we are only using this instance
  # of this module to create tags.
  attributes = ["cluster"]

  context = module.this.context
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  # https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/deploy/subnet_discovery.md
  tags = { "kubernetes.io/cluster/${module.label.id}" = "shared" }

  # required tags to make ALB ingress work https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
  public_subnets_additional_tags = {
    "kubernetes.io/role/elb" : 1
  }
  private_subnets_additional_tags = {
    "kubernetes.io/role/internal-elb" : 1
  }

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
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "1.1.0"

  cidr_block = var.vpc_cidr_block
  tags       = local.tags

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.0.2"

  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  max_nats             = 1
  nat_gateway_enabled  = true
  nat_instance_enabled = false
  tags                 = local.tags

  context = module.this.context
}

module "ssh_source_access" {
  source  = "cloudposse/security-group/aws"
  version = "0.4.3"

  attributes                 = ["ssh", "source"]
  security_group_description = "Test source security group ssh access only"
  create_before_destroy      = true
  allow_all_egress           = true

  rules = [local.allow_all_ingress_rule]
  # rules_map = { ssh_source = [local.allow_all_ingress_rule] }

  vpc_id = module.vpc.vpc_id

  context = module.label.context
}

module "https_sg" {
  source  = "cloudposse/security-group/aws"
  version = "0.4.3"

  attributes                 = ["http"]
  security_group_description = "Allow http access"
  create_before_destroy      = true
  allow_all_egress           = true

  rules = [local.allow_http_ingress_rule]

  vpc_id = module.vpc.vpc_id

  context = module.label.context
}


module "eks_cluster" {
  # source  = "cloudposse/eks-cluster/aws"
  version = "2.2.0"
  source                       = "github.com/ChrisMcKee/terraform-aws-eks-cluster"
  region                       = var.region
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = module.subnets.public_subnet_ids
  kubernetes_version           = var.kubernetes_version
  local_exec_interpreter       = var.local_exec_interpreter
  oidc_provider_enabled        = var.oidc_provider_enabled
  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_log_retention_period = var.cluster_log_retention_period

  # data auth has problems destroying the auth-map
  kube_data_auth_enabled = false
  kube_exec_auth_enabled = true

  windows_support = true

  context = module.this.context
}

module "eks_nix_node_group" {
  source = "../../"

  subnet_ids         = module.this.enabled ? module.subnets.public_subnet_ids : ["filler_string_for_enabled_is_false"]
  cluster_name       = module.eks_cluster.eks_cluster_id
  instance_types     = var.instance_types
  desired_size       = var.desired_size
  min_size           = var.min_size
  max_size           = var.max_size
  kubernetes_version = [var.kubernetes_version]
  kubernetes_labels  = merge(var.kubernetes_labels, { attributes = coalesce(join(module.this.delimiter, module.this.attributes), "none") })
  kubernetes_taints  = var.kubernetes_taints

  ec2_ssh_key_name              = var.ec2_ssh_key_name
  ssh_access_security_group_ids = [module.ssh_source_access.id]
  associated_security_group_ids = [module.ssh_source_access.id, module.https_sg.id]
  node_role_policy_arns         = [local.extra_policy_arn]
  update_config                 = var.update_config

  //after_cluster_joining_userdata = var.after_cluster_joining_userdata

  ami_type            = var.ami_type
  ami_release_version = var.ami_release_version

  //before_cluster_joining_userdata = [var.before_cluster_joining_userdata]

  context = module.this.context

  # Ensure ordering of resource creation to eliminate the race conditions when applying the Kubernetes Auth ConfigMap.
  # Do not create Node Group before the EKS cluster is created and the `aws-auth` Kubernetes ConfigMap is applied.
  depends_on = [module.eks_cluster, module.eks_cluster.kubernetes_config_map_id]

  create_before_destroy = true

  node_group_terraform_timeouts = [{
    create = "40m"
    update = null
    delete = "20m"
  }]
}

module "windowslabel" {
  source = "cloudposse/label/null"

  enabled = var.include_windows_node

  context    = module.this.context
  attributes = ["nt", "workers"]
  tags = {
    nodeclass = "windows2019"
  }
}

module "eks_nt_node_group" {
  source = "../../"

  enabled = var.include_windows_node

  context = module.windowslabel.context

  subnet_ids         = module.this.enabled ? module.subnets.public_subnet_ids : ["filler_string_for_enabled_is_false"]
  cluster_name       = module.eks_cluster.eks_cluster_id
  instance_types     = var.instance_types
  desired_size       = 1
  min_size           = 1
  max_size           = 1
  kubernetes_version = [var.kubernetes_version]
  kubernetes_labels  = merge(var.kubernetes_labels, { attributes = coalesce(join(module.this.delimiter, module.this.attributes), "none") })

  ec2_ssh_key_name              = var.ec2_ssh_key_name
  ssh_access_security_group_ids = [module.ssh_source_access.id]
  associated_security_group_ids = [module.ssh_source_access.id, module.https_sg.id]
  node_role_policy_arns         = [local.extra_policy_arn]
  update_config                 = var.update_config

  ami_type = var.windows_node_ami_type

  # after_cluster_joining_userdata = [
  #   "Write-Host Hello"
  # ]

  # Ensure ordering of resource creation to eliminate the race conditions when applying the Kubernetes Auth ConfigMap.
  # Do not create Node Group before the EKS cluster is created and the `aws-auth` Kubernetes ConfigMap is applied.
  depends_on = [module.eks_cluster, module.eks_cluster.kubernetes_config_map_id]

  create_before_destroy = true

  node_group_terraform_timeouts = [{
    create = "40m"
    update = null
    delete = "20m"
  }]

  resources_to_tag = ["instance", "volume", "spot-instances-request", "network-interface"]
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_cluster.cluster_id
}

locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = module.eks_cluster.cluster_id
      cluster = {
        certificate-authority-data = module.eks_cluster.cluster_certificate_authority_data
        server                     = module.eks_cluster.cluster_endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = module.eks_cluster.cluster_id
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  })
}

locals {
  aws_auth_configmap_data = {
    mapRoles = yamlencode(concat(
      [{
        rolearn  = module.eks_nix_node_group.eks_node_group_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
        }
      ],
      [{
        rolearn  = module.eks_nt_node_group.eks_node_group_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "eks:kube-proxy-windows",
          "system:bootstrappers",
          "system:nodes",
        ]
        }
      ],
      var.aws_auth_roles
    ))
    mapUsers    = yamlencode(var.aws_auth_users)
    mapAccounts = yamlencode(var.aws_auth_accounts)
  }
}

resource "kubernetes_config_map" "aws_auth" {
  count = var.include_windows_node && var.create_aws_auth_configmap ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  lifecycle {
    # We are ignoring the data here since we will manage it with the resource below
    # This is only intended to be used in scenarios where the configmap does not exist
    ignore_changes = [data, metadata[0].labels, metadata[0].annotations]
  }
}

resource "null_resource" "apply" {
  count = var.include_windows_node ? 1 : 0
  triggers = {
    kubeconfig = base64encode(local.kubeconfig)
    cmd_patch  = <<-EOT
      kubectl create configmap aws-auth -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)
      kubectl patch configmap/aws-auth --patch "${kubernetes_config_map.aws_auth_configmap_yaml}" -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)
    EOT
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
    command = self.triggers.cmd_patch
  }
}
