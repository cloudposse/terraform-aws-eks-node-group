<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.3 |
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
| <a name="module_label"></a> [label](#module\_label) | cloudposse/label/null | 0.25.0 |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | cloudposse/security-group/aws | 0.3.2 |
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
| [random_pet.cbd](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [aws_ami.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_policy_document.amazon_eks_worker_node_autoscale_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/launch_template) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional tags for appending to tags\_as\_list\_of\_maps. Not added to `tags`. | `map(string)` | `{}` | no |
| <a name="input_after_cluster_joining_userdata"></a> [after\_cluster\_joining\_userdata](#input\_after\_cluster\_joining\_userdata) | Additional `bash` commands to execute on each worker node after joining the EKS cluster (after executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production | `string` | `""` | no |
| <a name="input_ami_image_id"></a> [ami\_image\_id](#input\_ami\_image\_id) | AMI to use. Ignored of `launch_template_id` is supplied. | `string` | `null` | no |
| <a name="input_ami_release_version"></a> [ami\_release\_version](#input\_ami\_release\_version) | EKS AMI version to use, e.g. "1.16.13-20200821" (no "v"). Defaults to latest version for Kubernetes version. | `string` | `null` | no |
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | Type of Amazon Machine Image (AMI) associated with the EKS Node Group.<br>Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64`, `AL2_x86_64_GPU`, and `AL2_ARM_64`. | `string` | `"AL2_x86_64"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| <a name="input_before_cluster_joining_userdata"></a> [before\_cluster\_joining\_userdata](#input\_before\_cluster\_joining\_userdata) | Additional `bash` commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production | `string` | `""` | no |
| <a name="input_bootstrap_additional_options"></a> [bootstrap\_additional\_options](#input\_bootstrap\_additional\_options) | Additional options to bootstrap.sh. DO NOT include `--kubelet-additional-args`, use `kubelet_additional_args` var instead. | `string` | `""` | no |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | Type of capacity associated with the EKS Node Group. Valid values: "ON\_DEMAND", "SPOT", or `null`.<br>Terraform will only perform drift detection if a configuration value is provided. | `string` | `null` | no |
| <a name="input_cluster_autoscaler_enabled"></a> [cluster\_autoscaler\_enabled](#input\_cluster\_autoscaler\_enabled) | Set true to label the node group so that the [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup) will discover and autoscale it | `bool` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the EKS cluster | `string` | n/a | yes |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br>See description of individual variables for details.<br>Leave string and numeric variables as `null` to use default value.<br>Individual variable settings (non-null) override settings in context object,<br>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": null,<br>  "enabled": true,<br>  "environment": null,<br>  "id_length_limit": null,<br>  "label_key_case": null,<br>  "label_order": [],<br>  "label_value_case": null,<br>  "name": null,<br>  "namespace": null,<br>  "regex_replace_chars": null,<br>  "stage": null,<br>  "tags": {}<br>}</pre> | no |
| <a name="input_create_before_destroy"></a> [create\_before\_destroy](#input\_create\_before\_destroy) | Set true in order to create the new node group before destroying the old one.<br>If false, the old node group will be destroyed first, causing downtime.<br>Changing this setting will always cause node group to be replaced. | `bool` | `false` | no |
| <a name="input_create_timeout"></a> [create\_timeout](#input\_create\_timeout) | If provided, it will increase or decrease the timeout for creating the node group https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group#timeouts"<br>  It would be necessary on node groups with a lot of nodes. Because the changing this node groups would take a lot of time | `string` | `"60m"` | no |
| <a name="input_delete_timeout"></a> [delete\_timeout](#input\_delete\_timeout) | If provided, it will increase or decrease the timeout for deleting the node group https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group#timeouts"<br>  It would be necessary on node groups with a lot of nodes. Because the changing this node groups would take a lot of time | `string` | `"60m"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes`.<br>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Initial desired number of worker nodes (external changes ignored) | `number` | n/a | yes |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Disk size in GiB for worker nodes. Defaults to 20. Ignored when `launch_template_id` is supplied.<br>Terraform will only perform drift detection if a configuration value is provided. | `number` | `20` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | If provided, will be used as volume type of created ebs disk on EC2 instances | `string` | `null` | no |
| <a name="input_ec2_ssh_key"></a> [ec2\_ssh\_key](#input\_ec2\_ssh\_key) | SSH key pair name to use to access the worker nodes | `string` | `null` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable\_cluster\_autoscaler](#input\_enable\_cluster\_autoscaler) | (Deprecated, use `cluster_autoscaler_enabled`) Set true to allow Kubernetes Cluster Auto Scaler to scale the node group | `bool` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment, e.g. 'uw2', 'us-west-2', OR 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_existing_workers_role_policy_arns"></a> [existing\_workers\_role\_policy\_arns](#input\_existing\_workers\_role\_policy\_arns) | List of existing policy ARNs that will be attached to the workers default role on creation | `list(string)` | `[]` | no |
| <a name="input_existing_workers_role_policy_arns_count"></a> [existing\_workers\_role\_policy\_arns\_count](#input\_existing\_workers\_role\_policy\_arns\_count) | Obsolete and ignored. Allowed for backward compatibility. | `number` | `0` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br>Set to `0` for unlimited length.<br>Set to `null` for default, which is `0`.<br>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | Instance types to use for this node group (up to 20). Defaults to ["t3.medium"].<br>Ignored when `launch_template_id` is supplied. | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
| <a name="input_kubelet_additional_options"></a> [kubelet\_additional\_options](#input\_kubelet\_additional\_options) | Additional flags to pass to kubelet.<br>DO NOT include `--node-labels` or `--node-taints`,<br>use `kubernetes_labels` and `kubernetes_taints` to specify those." | `string` | `""` | no |
| <a name="input_kubernetes_labels"></a> [kubernetes\_labels](#input\_kubernetes\_labels) | Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument.<br>Other Kubernetes labels applied to the EKS Node Group will not be managed. | `map(string)` | `{}` | no |
| <a name="input_kubernetes_taints"></a> [kubernetes\_taints](#input\_kubernetes\_taints) | Key-value mapping of Kubernetes taints. | `map(string)` | `{}` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided | `string` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | The letter case of label keys (`tag` names) (i.e. `name`, `namespace`, `environment`, `stage`, `attributes`) to use in `tags`.<br>Possible values: `lower`, `title`, `upper`.<br>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The naming order of the id output and Name tag.<br>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br>You can omit any of the 5 elements, but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | The letter case of output label values (also used in `tags` and `id`).<br>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br>Default value: `lower`. | `string` | `null` | no |
| <a name="input_launch_template_disk_encryption_enabled"></a> [launch\_template\_disk\_encryption\_enabled](#input\_launch\_template\_disk\_encryption\_enabled) | Enable disk encryption for the created launch template (if we aren't provided with an existing launch template) | `bool` | `false` | no |
| <a name="input_launch_template_disk_encryption_kms_key_id"></a> [launch\_template\_disk\_encryption\_kms\_key\_id](#input\_launch\_template\_disk\_encryption\_kms\_key\_id) | Custom KMS Key ID to encrypt EBS volumes on EC2 instances, applicable only if `launch_template_disk_encryption_enabled` is set to true | `string` | `""` | no |
| <a name="input_launch_template_name"></a> [launch\_template\_name](#input\_launch\_template\_name) | The name (not ID) of a custom launch template to use for the EKS node group. If provided, it must specify the AMI image id. | `string` | `null` | no |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | The version of the specified launch template to use. Defaults to latest version. | `string` | `null` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of worker nodes | `number` | n/a | yes |
| <a name="input_metadata_http_endpoint"></a> [metadata\_http\_endpoint](#input\_metadata\_http\_endpoint) | Whether the metadata service is available. Can be enabled or disabled | `string` | `"enabled"` | no |
| <a name="input_metadata_http_put_response_hop_limit"></a> [metadata\_http\_put\_response\_hop\_limit](#input\_metadata\_http\_put\_response\_hop\_limit) | The desired HTTP PUT response hop limit for instance metadata requests. The larger the number, the further instance metadata requests can travel. Can be an integer from 1 to 64 | `number` | `2` | no |
| <a name="input_metadata_http_tokens"></a> [metadata\_http\_tokens](#input\_metadata\_http\_tokens) | Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2 (IMDSv2). Can be optional or required | `string` | `"optional"` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of worker nodes | `number` | n/a | yes |
| <a name="input_module_depends_on"></a> [module\_depends\_on](#input\_module\_depends\_on) | Can be any value desired. Module will wait for this value to be computed before creating node group. | `any` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Solution name, e.g. 'app' or 'jenkins' | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `null` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | If provided, all IAM roles will be created with this permissions boundary attached. | `string` | `null` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`.<br>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_remote_access_enabled"></a> [remote\_access\_enabled](#input\_remote\_access\_enabled) | Whether to enable remote access to EKS node group, requires `ec2_ssh_key` to be defined. | `bool` | `false` | no |
| <a name="input_resources_to_tag"></a> [resources\_to\_tag](#input\_resources\_to\_tag) | List of auto-launched resource types to tag. Valid types are "instance", "volume", "elastic-gpu", "spot-instances-request". | `list(string)` | `[]` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | The Security Group description. | `string` | `"Allow SSH access to all nodes in the nodeGroup"` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | A list of maps of Security Group rules. <br>The values of map is fully complated with `aws_security_group_rule` resource. <br>To get more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule . | `list(any)` | <pre>[<br>  {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": "Allow all outbound traffic",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "to_port": 65535,<br>    "type": "egress"<br>  },<br>  {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": "Allow SSH access to nodes from anywhere",<br>    "from_port": 22,<br>    "protocol": "tcp",<br>    "to_port": 22,<br>    "type": "ingress"<br>  }<br>]</pre> | no |
| <a name="input_security_group_use_name_prefix"></a> [security\_group\_use\_name\_prefix](#input\_security\_group\_use\_name\_prefix) | Whether to create a default Security Group with unique name beginning with the normalized prefix. | `bool` | `false` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | A list of Security Group IDs to associate with EKS node group. | `list(string)` | `[]` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of subnet IDs to launch resources in | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |
| <a name="input_update_timeout"></a> [update\_timeout](#input\_update\_timeout) | If provided, it will increase or decrease the timeout for updating the node group https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group#timeouts"<br>  It would be necessary on node groups with a lot of nodes. Because the changing this node groups would take a lot of time | `string` | `"60m"` | no |
| <a name="input_userdata_override_base64"></a> [userdata\_override\_base64](#input\_userdata\_override\_base64) | Many features of this module rely on the `bootstrap.sh` provided with Amazon Linux, and this module<br>may generate "user data" that expects to find that script. If you want to use an AMI that is not<br>compatible with the Amazon Linux `bootstrap.sh` initialization, then use `userdata_override_base64` to provide<br>your own (Base64 encoded) user data. Use "" to prevent any user data from being set.<br><br>Setting `userdata_override_base64` disables `kubernetes_taints`, `kubelet_additional_options`,<br>`before_cluster_joining_userdata`, `after_cluster_joining_userdata`, and `bootstrap_additional_options`. | `string` | `null` | no |
| <a name="input_worker_role_autoscale_iam_enabled"></a> [worker\_role\_autoscale\_iam\_enabled](#input\_worker\_role\_autoscale\_iam\_enabled) | If true, the worker IAM role will be authorized to perform autoscaling operations. Not recommended.<br>Use [EKS IAM role for cluster autoscaler service account](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) instead. | `bool` | `false` | no |
| <a name="input_worker_role_cni_iam_enabled"></a> [worker\_role\_cni\_iam\_enabled](#input\_worker\_role\_cni\_iam\_enabled) | If true, the worker IAM role will be authorized to perform CNI operations. Defaults to true for ease of use.<br>Recommended to use [EKS IAM role for aws-node service account](https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html) instead. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_node_group_arn"></a> [eks\_node\_group\_arn](#output\_eks\_node\_group\_arn) | Amazon Resource Name (ARN) of the EKS Node Group |
| <a name="output_eks_node_group_id"></a> [eks\_node\_group\_id](#output\_eks\_node\_group\_id) | EKS Cluster name and EKS Node Group name separated by a colon |
| <a name="output_eks_node_group_remote_access_security_group_arn"></a> [eks\_node\_group\_remote\_access\_security\_group\_arn](#output\_eks\_node\_group\_remote\_access\_security\_group\_arn) | ARN of the EKS cluster Security Group for remote access to EKS Node Group |
| <a name="output_eks_node_group_remote_access_security_group_id"></a> [eks\_node\_group\_remote\_access\_security\_group\_id](#output\_eks\_node\_group\_remote\_access\_security\_group\_id) | ID of the EKS cluster Security Group for remote access to EKS Node Group |
| <a name="output_eks_node_group_remote_access_security_group_name"></a> [eks\_node\_group\_remote\_access\_security\_group\_name](#output\_eks\_node\_group\_remote\_access\_security\_group\_name) | Name of the EKS cluster Security Group for remote access to EKS Node Group |
| <a name="output_eks_node_group_resources"></a> [eks\_node\_group\_resources](#output\_eks\_node\_group\_resources) | List of objects containing information about underlying resources of the EKS Node Group |
| <a name="output_eks_node_group_role_arn"></a> [eks\_node\_group\_role\_arn](#output\_eks\_node\_group\_role\_arn) | ARN of the worker nodes IAM role |
| <a name="output_eks_node_group_role_name"></a> [eks\_node\_group\_role\_name](#output\_eks\_node\_group\_role\_name) | Name of the worker nodes IAM role |
| <a name="output_eks_node_group_status"></a> [eks\_node\_group\_status](#output\_eks\_node\_group\_status) | Status of the EKS Node Group |
<!-- markdownlint-restore -->
