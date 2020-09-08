<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 3.0 |
| local | >= 1.3 |
| random | >= 2.0 |
| template | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0 |
| random | >= 2.0 |

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
| cluster\_name | The name of the EKS cluster | `string` | n/a | yes |
| context | Single object for setting entire context at once.<br>See description of individual variables for details.<br>Leave string and numeric variables as `null` to use default value.<br>Individual variable settings (non-null) override settings in context object,<br>except for attributes, tags, and additional\_tag\_map, which are merged. | <pre>object({<br>    enabled             = bool<br>    namespace           = string<br>    environment         = string<br>    stage               = string<br>    name                = string<br>    delimiter           = string<br>    attributes          = list(string)<br>    tags                = map(string)<br>    additional_tag_map  = map(string)<br>    regex_replace_chars = string<br>    label_order         = list(string)<br>    id_length_limit     = number<br>  })</pre> | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": null,<br>  "enabled": true,<br>  "environment": null,<br>  "id_length_limit": null,<br>  "label_order": [],<br>  "name": null,<br>  "namespace": null,<br>  "regex_replace_chars": null,<br>  "stage": null,<br>  "tags": {}<br>}</pre> | no |
| create\_before\_destroy | Set true in order to create the new node group before destroying the old one.<br>If false, the old node group will be destroyed first, causing downtime.<br>Changing this setting will always cause node group to be replaced. | `bool` | `false` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes`.<br>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| desired\_size | Initial desired number of worker nodes (external changes ignored) | `number` | n/a | yes |
| disk\_size | Disk size in GiB for worker nodes. Defaults to 20. Ignored it `launch_template_id` is supplied.<br>Terraform will only perform drift detection if a configuration value is provided. | `number` | `20` | no |
| ec2\_ssh\_key | SSH key name that should be used to access the worker nodes | `string` | `null` | no |
| enable\_cluster\_autoscaler | Set true to allow Kubernetes Cluster Auto Scaler to scale the node group | `bool` | `false` | no |
| enabled | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| environment | Environment, e.g. 'uw2', 'us-west-2', OR 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| existing\_workers\_role\_policy\_arns | List of existing policy ARNs that will be attached to the workers default role on creation | `list(string)` | `[]` | no |
| existing\_workers\_role\_policy\_arns\_count | Obsolete and ignored. Allowed for backward compatibility. | `number` | `0` | no |
| id\_length\_limit | Limit `id` to this many characters.<br>Set to `0` for unlimited length.<br>Set to `null` for default, which is `0`.<br>Does not affect `id_full`. | `number` | `null` | no |
| instance\_types | Single instance type to use for this node group, passed as a list. Defaults to ["t3.medium"].<br>It is a list because Launch Templates take a list, and it is a single type because EKS only supports a single type per node group. | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
| kubelet\_additional\_options | Additional flags to pass to kubelet.<br>DO NOT include `--node-labels` or `--node-taints`,<br>use `kubernetes_labels` and `kubernetes_taints` to specify those." | `string` | `""` | no |
| kubernetes\_labels | Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument.<br>Other Kubernetes labels applied to the EKS Node Group will not be managed. | `map(string)` | `{}` | no |
| kubernetes\_taints | Key-value mapping of Kubernetes taints. | `map(string)` | `{}` | no |
| kubernetes\_version | Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided | `string` | `null` | no |
| label\_order | The naming order of the id output and Name tag.<br>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br>You can omit any of the 5 elements, but at least one must be present. | `list(string)` | `null` | no |
| launch\_template\_name | The name (not ID) of a custom launch template to use for the EKS node group. If provided, it must specify the AMI image id. | `string` | `null` | no |
| launch\_template\_version | The version of the specified launch template to use. Defaults to latest version. | `string` | `null` | no |
| max\_size | Maximum number of worker nodes | `number` | n/a | yes |
| min\_size | Minimum number of worker nodes | `number` | n/a | yes |
| module\_depends\_on | Can be any value desired. Module will wait for this value to be computed before creating node group. | `any` | `null` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | `string` | `null` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `null` | no |
| regex\_replace\_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`.<br>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| resources\_to\_tag | List of auto-launched resource types to tag. Valid types are "instance", "volume", "elastic-gpu", "spot-instances-request". | `list(string)` | `[]` | no |
| source\_security\_group\_ids | Set of EC2 Security Group IDs to allow SSH access (port 22) from on the worker nodes. If you specify `ec2_ssh_key`, but do not specify this configuration when you create an EKS Node Group, port 22 on the worker nodes is opened to the Internet (0.0.0.0/0) | `list(string)` | `[]` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| subnet\_ids | A list of subnet IDs to launch resources in | `list(string)` | n/a | yes |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |
| userdata\_override | Many features of this module rely on the `bootstrap.sh` provided with Amazon Linux, and this module<br>may generate "user data" that expects to find that script. If you want to use an AMI that is not<br>compatible with the Amazon Linux `bootstrap.sh` initialization, then use `userdata_override` to provide<br>your own (Base64 encoded) user data. Use "" to prevent any user data from being set.<br><br>Setting `userdata_override` disables `kubernetes_taints`, `kubelet_additional_options`,<br>`before_cluster_joining_userdata`, `after_cluster_joining_userdata`, and `bootstrap_additional_options`. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| eks\_node\_group\_arn | Amazon Resource Name (ARN) of the EKS Node Group |
| eks\_node\_group\_id | EKS Cluster name and EKS Node Group name separated by a colon |
| eks\_node\_group\_resources | List of objects containing information about underlying resources of the EKS Node Group |
| eks\_node\_group\_role\_arn | ARN of the worker nodes IAM role |
| eks\_node\_group\_role\_name | Name of the worker nodes IAM role |
| eks\_node\_group\_status | Status of the EKS Node Group |

<!-- markdownlint-restore -->
