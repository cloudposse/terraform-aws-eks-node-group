# Migration to v0.25.0

## New Features

With v0.25.0 we have fixed a lot of issues and added several requested features. 

- Full control over block device mappings via `block_device_mappings`
- Ability to associate additional security groups with a node group via `associated_security_group_ids`
- Ability to specify additional IAM Policies to attach to the node role
- Ability to set whether or not the `AmazonEKS_CNI_Policy` is attached to the node role
- Ability to provide your own IAM Role for the node group so you have complete control over its settings
- Ability to specify node group placement details via `placement`
- Ability to enable Nitro Enclaves on Nitro instances
- Ability to configure Terrafrom create, update, and delete timeouts

We also take advantage of improved AWS support for managed node upgrades. Now things like changing security groups or disk size no longer require a full replacement of the node group but instead are handled by EKS as rolling upgrades. This release includes support for the new `update_config` configuration that sets limits on how many nodes can be out of service during an upgrade.



See the [README](https://github.com/cloudposse/terraform-aws-eks-node-group) for more details.

## Breaking changes in v0.25.0

Releases v0.11.0 through v0.20.0 of this module attempted to maintain compatiblity, so that no code changes were needed to upgrade and node groups would not likely be
recreated on upgrade. Releases between v0.20.0 and v0.25.0 were never
recommended for use because of compatibility issues. With the release
of v0.25.0 we are making significant, breaking changes in order to bring
this module up to current Cloud Posse standards. Code changes will likely
be needed and node groups will likely need to be recreated. We strongly recommend
enabling `create_before_destroy` if you have not already, as in general
it provides a better upgrade path whenever an upgrade or change in confguration requires an node group to be replaced.

### Behavoir changes

- Previously, EBS volumes were left with the default value of `delete_on_termination`, which is `false`. Now the default EBS volume has it set to `true`. 
- Previously, the Instance Metadata Service v1 (IMDSv1) was enabled by default, which is considered a security risk. Now it is disabled by default. Set `metadata_http_tokens_required` to `false` to leave IMDSv1 enabled.
- Previously, a launch template was only generated and used if the settings required a launch template to set them. Now a launch template is alway generated (unless a launch template ID is provided) and used, and anything that can be set in the launch template is set there rather than in the node group configuration.
- When a launch template is generated, a special security group to allow `ssh` access is also created if an `ssh` access key is specified. The name of this security group has changed from previous versions, to be consistent with Cloud Posse naming conventions. This will cause any previously created security group to be deleted, which will require the node group to be updated. 
- Previously, if a launch template ID was specified, the `instance_types` input was ignored. Now it is up to the user to make sure that the instance type is specified in the launch tempate or in `instance_types` but not both.



### Input Variable Changes

- `enable_cluster_autoscaler` removed. Use `cluster_autoscaler_enabled` instead.

- `worker_role_autoscale_iam_enabled` removed. Use an [EKS IAM role for service account](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) for the cluster autoscaler service account instead.

- `source_security_group_ids` renamed `ssh_access_security_group_ids` to reflect that the specified security groups will be given `ssh` access (TCP port 22) to the nodes. 

- `existing_workers_role_policy_arns` renamed `node_role_policy_arns`.

- `existing_workers_role_policy_arns_count` removed (was ignored anyway).

- `node_role_arn` added. If supplied, this module will not create an IAM role and instead will assign the given role to the node group.

- `permissions_boundary` renamed to `node_role_permissions_boundary`.

- `disk_size` removed. Set custom disk size via `block_device_mappings`. Defaults mapping has value 20 GB.

- `disk_type` removed. Set custom disk type via `block_device_mappings`. Defaults mapping has value `gp2`.

- `launch_template_name` replaced with `launch_template_id`. Use `data "aws_launch_template"` to get the `id` from the `name` if you need to.

- `launch_template_disk_encryption_enabled` removed. Set  via `block_device_mappings`. Default mapping has value `true`. 

- `launch_template_disk_encryption_kms_key_id` removed. Set  via `block_device_mappings`. Default mapping has value `null`. 

- `kubernetes_taints` changed from key-value map of `<key> = "<value>:<effect>"` to list of objects to match the resource configuration format.

- `metadata_http_endpoint` removed. Use `metadata_http_endpoint_enabled` instead.

- `metadata_http_tokens` removed. Use `metadata_http_tokens_required` instead.

- The following optional values used to be `string` type and are now `list(string)` type. An empty list is allowed. If the list has a value in it, that value will be used, even if empty, which may not be allowed by Terraform. The list may not have more than one value.

  - `ami_image_id`
  - `ami_release_version`
  - `kubernetes_version`
  - `launch_template_id`
  - `launch_template_version`
  - `ec2_ssh_key` renamed `ec2_ssh_key_name`
  - `before_cluster_joining_userdata`
  - `after_cluster_joining_userdata`
  - `bootstrap_additional_options`
  - `userdata_override_base64`

- `kubelet_additional_options` was changed from `string` to `list(string)` but can contain multiple values, allowing you to specify options individually rather than requiring that you join them into one string (which you may still do if you prefer to).

  

