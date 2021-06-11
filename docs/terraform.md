<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | < 0.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.0 |
| <a name="requirement_template"></a> [template](#requirement\_template) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_label"></a> [label](#module\_label) | cloudposse/label/null | 0.24.1 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.24.1 |

## Resources

| Name | Type |
|------|------|
| [aws_eks_node_group.cbd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_eks_node_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_policy.amazon_eks_worker_node_autoscale_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.amazon_eks_cni_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.amazon_eks_worker_node_autoscale_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.amazon_eks_worker_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.existing_policies_for_eks_workers_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.remote_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.remote_access_public_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.remote_access_source_sgs_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [random_pet.cbd](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [aws_ami.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_policy_document.amazon_eks_worker_node_autoscale_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/launch_template) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_subnet.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_tag\_map | Additional tags for appending to tags\_as\_list\_of\_maps. Not added to `tags`. | `map(string)` | `{}` | no |
| after\_cluster\_joining\_userdata | Additional `bash` commands to execute on each worker node after joining the EKS cluster (after executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production | `string` | `""` | no |
| ami\_image\_id | AMI to use. Ignored of `launch_template_id` is supplied. | `string` | `null` | no |
| ami\_release\_version | EKS AMI version to use, e.g. "1.16.13-20200821" (no "v"). Defaults to latest version for Kubernetes version. | `string` | `null` | no |
| ami\_type | Type of Amazon Machine Image (AMI) associated with the EKS Node Group.<br>Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64`, `AL2_x86_64_GPU`, and `AL2_ARM_64`. | `string` | `"AL2_x86_64"` | no |
| attributes | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| before\_cluster\_joining\_userdata | Additional `bash` commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production | `string` | `""` | no |
| bootstrap\_additional\_options | Additional options to bootstrap.sh. DO NOT include `--kubelet-additional-args`, use `kubelet_additional_args` var instead. | `string` | `""` | no |
| capacity\_type | Type of capacity associated with the EKS Node Group. Valid values: "ON\_DEMAND", "SPOT", or `null`.<br>Terraform will only perform drift detection if a configuration value is provided. | `string` | `null` | no |
| cluster\_autoscaler\_enabled | Set true to label the node group so that the [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup) will discover and autoscale it | `bool` | `null` | no |
| cluster\_name | The name of the EKS cluster | `string` | n/a | yes |
| context | Single object for setting entire context at once.<br>See description of individual variables for details.<br>Leave string and numeric variables as `null` to use default value.<br>Individual variable settings (non-null) override settings in context object,<br>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": null,<br>  "enabled": true,<br>  "environment": null,<br>  "id_length_limit": null,<br>  "label_key_case": null,<br>  "label_order": [],<br>  "label_value_case": null,<br>  "name": null,<br>  "namespace": null,<br>  "regex_replace_chars": null,<br>  "stage": null,<br>  "tags": {}<br>}</pre> | no |
| create\_before\_destroy | Set true in order to create the new node group before destroying the old one.<br>If false, the old node group will be destroyed first, causing downtime.<br>Changing this setting will always cause node group to be replaced. | `bool` | `false` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes`.<br>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| desired\_size | Initial desired number of worker nodes (external changes ignored) | `number` | n/a | yes |
| disk\_size | Disk size in GiB for worker nodes. Defaults to 20. Ignored when `launch_template_id` is supplied.<br>Terraform will only perform drift detection if a configuration value is provided. | `number` | `20` | no |
| disk\_type | If provided, will be used as volume type of created ebs disk on EC2 instances | `string` | `null` | no |
| ec2\_ssh\_key | SSH key pair name to use to access the worker nodes | `string` | `null` | no |
| enable\_cluster\_autoscaler | (Deprecated, use `cluster_autoscaler_enabled`) Set true to allow Kubernetes Cluster Auto Scaler to scale the node group | `bool` | `null` | no |
| enabled | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| environment | Environment, e.g. 'uw2', 'us-west-2', OR 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| existing\_workers\_role\_policy\_arns | List of existing policy ARNs that will be attached to the workers default role on creation | `list(string)` | `[]` | no |
| existing\_workers\_role\_policy\_arns\_count | Obsolete and ignored. Allowed for backward compatibility. | `number` | `0` | no |
| id\_length\_limit | Limit `id` to this many characters (minimum 6).<br>Set to `0` for unlimited length.<br>Set to `null` for default, which is `0`.<br>Does not affect `id_full`. | `number` | `null` | no |
| instance\_types | Instance types to use for this node group (up to 20). Defaults to ["t3.medium"].<br>Ignored when `launch_template_id` is supplied. | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
| kubelet\_additional\_options | Additional flags to pass to kubelet.<br>DO NOT include `--node-labels` or `--node-taints`,<br>use `kubernetes_labels` and `kubernetes_taints` to specify those." | `string` | `""` | no |
| kubernetes\_labels | Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument.<br>Other Kubernetes labels applied to the EKS Node Group will not be managed. | `map(string)` | `{}` | no |
| kubernetes\_taints | Key-value mapping of Kubernetes taints. | `map(string)` | `{}` | no |
| kubernetes\_version | Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided | `string` | `null` | no |
| label\_key\_case | The letter case of label keys (`tag` names) (i.e. `name`, `namespace`, `environment`, `stage`, `attributes`) to use in `tags`.<br>Possible values: `lower`, `title`, `upper`.<br>Default value: `title`. | `string` | `null` | no |
| label\_order | The naming order of the id output and Name tag.<br>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br>You can omit any of the 5 elements, but at least one must be present. | `list(string)` | `null` | no |
| label\_value\_case | The letter case of output label values (also used in `tags` and `id`).<br>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br>Default value: `lower`. | `string` | `null` | no |
| launch\_template\_disk\_encryption\_enabled | Enable disk encryption for the created launch template (if we aren't provided with an existing launch template) | `bool` | `false` | no |
| launch\_template\_disk\_encryption\_kms\_key\_id | Custom KMS Key ID to encrypt EBS volumes on EC2 instances, applicable only if `launch_template_disk_encryption_enabled` is set to true | `string` | `""` | no |
| launch\_template\_name | The name (not ID) of a custom launch template to use for the EKS node group. If provided, it must specify the AMI image id. | `string` | `null` | no |
| launch\_template\_version | The version of the specified launch template to use. Defaults to latest version. | `string` | `null` | no |
| max\_size | Maximum number of worker nodes | `number` | n/a | yes |
| metadata\_http\_endpoint | Whether the metadata service is available. Can be enabled or disabled | `string` | `"enabled"` | no |
| metadata\_http\_put\_response\_hop\_limit | The desired HTTP PUT response hop limit for instance metadata requests. The larger the number, the further instance metadata requests can travel. Can be an integer from 1 to 64 | `number` | `2` | no |
| metadata\_http\_tokens | Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2 (IMDSv2). Can be optional or required | `string` | `"optional"` | no |
| min\_size | Minimum number of worker nodes | `number` | n/a | yes |
| module\_depends\_on | Can be any value desired. Module will wait for this value to be computed before creating node group. | `any` | `null` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | `string` | `null` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `null` | no |
| permissions\_boundary | If provided, all IAM roles will be created with this permissions boundary attached. | `string` | `null` | no |
| regex\_replace\_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`.<br>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| resources\_to\_tag | List of auto-launched resource types to tag. Valid types are "instance", "volume", "elastic-gpu", "spot-instances-request". | `list(string)` | `[]` | no |
| source\_security\_group\_ids | Set of EC2 Security Group IDs to allow SSH access (port 22) to the worker nodes. If you specify `ec2_ssh_key`, but do not specify this configuration when you create an EKS Node Group, port 22 on the worker nodes is opened to the Internet (0.0.0.0/0) | `list(string)` | `[]` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| subnet\_ids | A list of subnet IDs to launch resources in | `list(string)` | n/a | yes |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |
| userdata\_override\_base64 | Many features of this module rely on the `bootstrap.sh` provided with Amazon Linux, and this module<br>may generate "user data" that expects to find that script. If you want to use an AMI that is not<br>compatible with the Amazon Linux `bootstrap.sh` initialization, then use `userdata_override_base64` to provide<br>your own (Base64 encoded) user data. Use "" to prevent any user data from being set.<br><br>Setting `userdata_override_base64` disables `kubernetes_taints`, `kubelet_additional_options`,<br>`before_cluster_joining_userdata`, `after_cluster_joining_userdata`, and `bootstrap_additional_options`. | `string` | `null` | no |
| worker\_role\_autoscale\_iam\_enabled | If true, the worker IAM role will be authorized to perform autoscaling operations. Not recommended.<br>Use [EKS IAM role for cluster autoscaler service account](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) instead. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_node_group_arn"></a> [eks\_node\_group\_arn](#output\_eks\_node\_group\_arn) | Amazon Resource Name (ARN) of the EKS Node Group |
| <a name="output_eks_node_group_id"></a> [eks\_node\_group\_id](#output\_eks\_node\_group\_id) | EKS Cluster name and EKS Node Group name separated by a colon |
| <a name="output_eks_node_group_remote_access_security_group_id"></a> [eks\_node\_group\_remote\_access\_security\_group\_id](#output\_eks\_node\_group\_remote\_access\_security\_group\_id) | The ID of the security group generated to allow SSH access to the nodes, if this module generated one |
| <a name="output_eks_node_group_resources"></a> [eks\_node\_group\_resources](#output\_eks\_node\_group\_resources) | List of objects containing information about underlying resources of the EKS Node Group |
| <a name="output_eks_node_group_role_arn"></a> [eks\_node\_group\_role\_arn](#output\_eks\_node\_group\_role\_arn) | ARN of the worker nodes IAM role |
| <a name="output_eks_node_group_role_name"></a> [eks\_node\_group\_role\_name](#output\_eks\_node\_group\_role\_name) | Name of the worker nodes IAM role |
| <a name="output_eks_node_group_status"></a> [eks\_node\_group\_status](#output\_eks\_node\_group\_status) | Status of the EKS Node Group |
<!-- markdownlint-restore -->
