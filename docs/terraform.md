## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| ami_release_version | AMI version of the EKS Node Group. Defaults to latest version for Kubernetes version | string | `null` | no |
| ami_type | Type of Amazon Machine Image (AMI) associated with the EKS Node Group. Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64`, `AL2_x86_64_GPU`. Terraform will only perform drift detection if a configuration value is provided | string | `AL2_x86_64` | no |
| attributes | Additional attributes (e.g. `1`) | list(string) | `<list>` | no |
| cluster_name | The name of the EKS cluster | string | - | yes |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name` and `attributes` | string | `-` | no |
| desired_size | Desired number of worker nodes | number | - | yes |
| disk_size | Disk size in GiB for worker nodes. Defaults to 20. Terraform will only perform drift detection if a configuration value is provided | number | `20` | no |
| ec2_ssh_key | SSH key name that should be used to access the worker nodes | string | `null` | no |
| enabled | Whether to create the resources. Set to `false` to prevent the module from creating any resources | bool | `true` | no |
| existing_workers_role_policy_arns | List of existing policy ARNs that will be attached to the workers default role on creation | list(string) | `<list>` | no |
| existing_workers_role_policy_arns_count | Count of existing policy ARNs that will be attached to the workers default role on creation. Needed to prevent Terraform error `count can't be computed` | number | `0` | no |
| instance_types | Set of instance types associated with the EKS Node Group. Defaults to ["t3.medium"]. Terraform will only perform drift detection if a configuration value is provided | list(string) | - | yes |
| kubernetes_labels | Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed | map(string) | `<map>` | no |
| kubernetes_version | Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided | string | `null` | no |
| max_size | Maximum number of worker nodes | number | - | yes |
| min_size | Minimum number of worker nodes | number | - | yes |
| name | Solution name, e.g. 'app' or 'cluster' | string | - | yes |
| namespace | Namespace, which could be your organization name, e.g. 'eg' or 'cp' | string | `` | no |
| source_security_group_ids | Set of EC2 Security Group IDs to allow SSH access (port 22) from on the worker nodes. If you specify `ec2_ssh_key`, but do not specify this configuration when you create an EKS Node Group, port 22 on the worker nodes is opened to the Internet (0.0.0.0/0) | list(string) | `<list>` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', or 'test' | string | `` | no |
| subnet_ids | A list of subnet IDs to launch resources in | list(string) | - | yes |
| tags | Additional tags (e.g. `{ BusinessUnit = "XYZ" }` | map(string) | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| eks_node_group_arn | Amazon Resource Name (ARN) of the EKS Node Group |
| eks_node_group_id | EKS Cluster name and EKS Node Group name separated by a colon |
| eks_node_group_resources | List of objects containing information about underlying resources of the EKS Node Group |
| eks_node_group_role_arn | ARN of the worker nodes IAM role |
| eks_node_group_role_name | Name of the worker nodes IAM role |
| eks_node_group_status | Status of the EKS Node Group |

