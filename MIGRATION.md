# Migration to v0.25.0

## New Features

With v0.25.0 we have fixed a lot of issues and added several requested features.

- Full control over block device mappings via `block_device_mappings`
- Ability to associate additional security groups with a node group via `associated_security_group_ids`
- Ability to specify additional IAM Policies to attach to the node role
- Ability to set whether the `AmazonEKS_CNI_Policy` is attached to the node role
- Ability to provide your own IAM Role for the node group, so you have complete control over its settings
- Ability to specify node group placement details via `placement`
- Ability to enable Nitro Enclaves on Nitro instances
- Ability to configure Terraform create, update, and delete timeouts

We also take advantage of improved AWS support for managed node upgrades. Now things like changing security groups or disk size no longer require a full replacement of the node group but
instead are handled by EKS as rolling upgrades. This release includes support for the new `update_config` configuration that sets limits on how many nodes can be out of service during an
upgrade.

See the [README](https://github.com/cloudposse/terraform-aws-eks-node-group) for more details.

## Breaking changes in v0.25.0

Releases v0.11.0 through v0.20.0 of this module attempted to maintain compatibility, so that no code changes were needed to upgrade and node groups would not likely be recreated on upgrade.
Releases between v0.20.0 and v0.25.0 were never recommended for use because of compatibility issues. With the release of v0.25.0 we are making significant, breaking changes in order to bring
this module up to current Cloud Posse standards. Code changes will likely be needed and node groups will likely need to be recreated. We strongly recommend enabling `create_before_destroy`
if you have not already, as in general it provides a better upgrade path whenever an upgrade or change in configuration requires a node group to be replaced.

### Terraform Version

Terraform version 1.0 is out. Before that, there was Terraform version 0.15, 0.14, 0.13 and so on. The v0.25.0 release of this module drops support for Terraform 0.13. That version is old
and has lots of known issues. There are hardly any breaking changes between Terraform 0.13 and 1.0, so please upgrade to the latest Terraform version before raising any issues about this
module.

### Behavior changes

- Previously, EBS volumes were left with the default value of `delete_on_termination`, which is `true` for EKS AMI root volumes. Now the default EBS volume has it set to `true` explicitly.
- Previously, the Instance Metadata Service v1 (IMDSv1) was enabled by default, which is considered a security risk. Now it is disabled by default. Set `metadata_http_tokens_required`
  to `false` to leave IMDSv1 enabled.
- Previously, a launch template was only generated and used if the specified configuration could only be accomplished by using a launch template. Now a launch template is always generated (
  unless a launch template ID is provided) and used, and anything that can be set in the launch template is set there rather than in the node group configuration.
- When a launch template is generated, a special security group to allow `ssh` access is also created if an `ssh` access key is specified. The name of this security group has changed from
  previous versions, to be consistent with Cloud Posse naming conventions. This will cause any previously created security group to be deleted, which will require the node group to be
  updated.
- Previously, if a launch template ID was specified, the `instance_types` input was ignored. Now it is up to the user to make sure that the instance type is specified in the launch template
  or in `instance_types` but not both.
- Did you want to exercise more control over where instances are placed? You can now specify placement groups and more via `placement`.
- Are you using Nitro instances? You can now enable Nitro enclaves with `enclave_enabled`.

### Input Variable Changes

- `enable_cluster_autoscaler` removed. Use `cluster_autoscaler_enabled` instead.

- `worker_role_autoscale_iam_enabled` removed. Use an [EKS IAM role for service account](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) for the cluster
  autoscaler service account instead, or add the policy back in via `node_role_policy_arns`.

- `source_security_group_ids` renamed `ssh_access_security_group_ids` to reflect that the specified security groups will be given `ssh` access (TCP port 22) to the nodes.

- `existing_workers_role_policy_arns` renamed `node_role_policy_arns`.

- `existing_workers_role_policy_arns_count` removed (was ignored anyway).

- `node_role_arn` added. If supplied, this module will not create an IAM role and instead will assign the given role to the node group.

- `permissions_boundary` renamed to `node_role_permissions_boundary`.

- `disk_size` removed. Set custom disk size via `block_device_mappings`. Defaults mapping has value 20 GB.

- `disk_type` removed. Set custom disk type via `block_device_mappings`. Defaults mapping has value `gp2`.

- `launch_template_name` replaced with `launch_template_id`. Use `data "aws_launch_template"` to get the `id` from the `name` if you need to.

- `launch_template_disk_encryption_enabled` removed. Set via `block_device_mappings`. Default mapping has value `true`.

- `launch_template_disk_encryption_kms_key_id` removed. Set via `block_device_mappings`. Default mapping has value `null`.

- `kubernetes_taints` changed from key-value map of `<key> = "<value>:<effect>"` to list of objects to match the resource configuration format.

- `metadata_http_endpoint` removed. Use `metadata_http_endpoint_enabled` instead.

- `metadata_http_tokens` removed. Use `metadata_http_tokens_required` instead.

- The following optional values used to be `string` type and are now `list(string)` type. An empty list is allowed. If the list has a value in it, that value will be used, even if empty,
  which may not be allowed by Terraform. The list may not have more than one value.

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

- `kubelet_additional_options` was changed from `string` to `list(string)` but can contain multiple values, allowing you to specify options individually rather than requiring that you join
  them into one string (which you may still do if you prefer to).

## Migration Tasks

In most cases, the changes you need to make are pretty easy.

#### Review behavior changes and new features

- Do you want node group instance EBS volumes deleted on termination? You can disable that now.
- Do you want Instance Metadata Service v1 available? This module now disables it by default, and EKS and Kubernetes all handle that fine, but you might have scripts that `curl` the instance
  metadata endpoint that need it.
- Did you have the "create before destroy" behavior disabled? The migration to v0.25.0 of this module is going to cause your node group to be destroyed and recreated anyway, so take the
  opportunity to enable it. It will save you and outage some day.
- Were you supplying your own launch template, and stuck having to put an instance type in it because the earlier versions of this module would not let you do otherwise? Well, now you can
  leave the instance type out of your launch template and supply a set of types via the node group to enable a spot fleet.
- Were you unhappy with the way the IAM Role for the nodes was configured? Now you can configure a role exactly the way you like and pass it in.
- Were you frustrated that you had to copy a bunch of rules from one security group to the node group's security group? Now you can just associate the other security groups directly with the
  node group.
- Were you experiencing timeouts creating or updating large node groups? Now you can set Terraform timeouts explicitly, and also control the pace of upgrades with `update_config`.

#### Rename variables

Review the "Input variable changes" section above and rename any of the variables you are using that were simply renamed.

#### Convert optional variables to lists

The biggest number of changes is in the optional variables. We used to determine whether or note a variable was set by looking at its value: `null` or the empty string was "not set" and any
other value was "set". Unfortunately, Terraform does not work that way. So we now take optional variables as a list with zero or one item. If the list is empty (zero items), the variable is
not set; if the list has an item, the variable is set.

For compatibility, you may want to keep your root module variables as strings and then adapt them when calling the node group module. Take care that you do not just take your existing
variable and put it in a list, for example:

```hcl
# WRONG, Do not do this:
kubernetes_version = [var.kubernetes_version]
```

If you do that and `kubernetes_version` is `null`, you will get an error. You know how you were setting the value and whether you were using `null`, `""`, or maybe both to indicate "use the
default", and you have to test for that if you are not going to convert your `kubernetes_version` to `list(string)`.

```hcl
# RIGHT: Do this:
kubernetes_version = length(compact([var.kubernetes_version])) == 0 ? [] : [var.kubernetes_version]
```

Note that this only works when you are sure `var.kubernetes_version` is supplied a value known at "plan" time. If you are writing a module where the input might be derived, you should switch
your input to list format.

#### Convert simple variables

A couple of variables were converted just for consistency with other Cloud Posse modules. They are easy to convert.

```hcl
metadata_http_tokens_required  = var.metadata_http_tokens != "optional"
metadata_http_endpoint_enabled = var.metadata_http_endpoint != "disabled"
```

#### Convert complex variables

##### `launch_template_name`

The `launch_template_name` input was replaced with `launch_template_id`. This is intended to reduce confusion as launch templates can be deleted and recreated with the same name but will
have different IDs. If you have the ID available, then this is an easy switch. If you do not have it available, you can use the `aws_launch_template` Data Source to get the `id` from
the `name`.

##### `kubernetes_taints`

The structure of `kubernetes_taints` changed. It used to be a map of `<key> = <value>:<effect>`. Now it is an object. You can do the conversion like this

```hcl
new_taints = [
  for k, v in var.old_taints : {
    key    = k
    value  = split(":", v)[0]
    effect = split(":", v)[1]
  }
]
```

##### `block_device_mappings`

Any variable that configured something inside a block device mapping was removed. Now you specify the full block device mapping the way you want it, and can specify multiple devices if you
want to. In general, you will probably want to do something like this:

```hcl
locals {
  block_device = {
    device_name           = "/dev/xvda"
    volume_size           = var.disk_size
    volume_type           = "gp2"
    encrypted             = var.disk_encryption_enabled
    delete_on_termination = true
  }
}

module "node_group" {
  ...
  block_device_mappings = [local.block_device]
  ...
}
```
