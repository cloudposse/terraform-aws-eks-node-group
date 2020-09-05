# terraform-aws-eks-node-group [![Latest Release](https://img.shields.io/github/release/cloudposse/terraform-aws-eks-node-group.svg)](https://github.com/cloudposse/terraform-aws-eks-node-group/releases/latest) [![Slack Community](https://slack.cloudposse.com/badge.svg)](https://slack.cloudposse.com)

[![README Header][readme_header_img]][readme_header_link]

[![Cloud Posse][logo]](https://cpco.io/homepage)

<!--




  ** DO NOT EDIT THIS FILE
  **
  ** This file was automatically generated by the `build-harness`.
  ** 1) Make all changes to `README.yaml`
  ** 2) Run `make init` (you only need to do this once)
  ** 3) Run`make readme` to rebuild this file.
  **
  ** (We maintain HUNDREDS of open source projects. This is how we maintain our sanity.)
  **





-->

Terraform module to provision an EKS Node Group for [Elastic Container Service for Kubernetes](https://aws.amazon.com/eks/).

Instantiate it multiple times to create many EKS node groups with specific settings such as GPUs, EC2 instance types, or autoscale parameters.


---

This project is part of our comprehensive ["SweetOps"](https://cpco.io/sweetops) approach towards DevOps.
[<img align="right" title="Share via Email" src="https://docs.cloudposse.com/images/ionicons/ios-email-outline-2.0.1-16x16-999999.svg"/>][share_email]
[<img align="right" title="Share on Google+" src="https://docs.cloudposse.com/images/ionicons/social-googleplus-outline-2.0.1-16x16-999999.svg" />][share_googleplus]
[<img align="right" title="Share on Facebook" src="https://docs.cloudposse.com/images/ionicons/social-facebook-outline-2.0.1-16x16-999999.svg" />][share_facebook]
[<img align="right" title="Share on Reddit" src="https://docs.cloudposse.com/images/ionicons/social-reddit-outline-2.0.1-16x16-999999.svg" />][share_reddit]
[<img align="right" title="Share on LinkedIn" src="https://docs.cloudposse.com/images/ionicons/social-linkedin-outline-2.0.1-16x16-999999.svg" />][share_linkedin]
[<img align="right" title="Share on Twitter" src="https://docs.cloudposse.com/images/ionicons/social-twitter-outline-2.0.1-16x16-999999.svg" />][share_twitter]


[![Terraform Open Source Modules](https://docs.cloudposse.com/images/terraform-open-source-modules.svg)][terraform_modules]



It's 100% Open Source and licensed under the [APACHE2](LICENSE).







We literally have [*hundreds of terraform modules*][terraform_modules] that are Open Source and well-maintained. Check them out!






## Introduction



## Usage


**IMPORTANT:** The `master` branch is used in `source` just as an example. In your code, do not pin to `master` because there may be breaking changes between releases.
Instead pin to the release tag (e.g. `?ref=tags/x.y.z`) of one of our [latest releases](https://github.com/cloudposse/terraform-aws-eks-node-group/releases).



For a complete example, see [examples/complete](examples/complete).

For automated tests of the complete example using [bats](https://github.com/bats-core/bats-core) and [Terratest](https://github.com/gruntwork-io/terratest) (which tests and deploys the example on AWS), see [test](test).

```hcl
    provider "aws" {
      region = var.region
    }

    module "label" {
      source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
      namespace  = var.namespace
      name       = var.name
      stage      = var.stage
      delimiter  = var.delimiter
      attributes = compact(concat(var.attributes, list("cluster")))
      tags       = var.tags
    }

    locals {
      tags = merge(module.label.tags, map("kubernetes.io/cluster/${module.label.id}", "shared"))
    }

    module "vpc" {
      source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.8.1"
      namespace  = var.namespace
      stage      = var.stage
      name       = var.name
      attributes = var.attributes
      cidr_block = var.vpc_cidr_block
      tags       = local.tags
    }

    module "subnets" {
      source               = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=tags/0.18.1"
      availability_zones   = var.availability_zones
      namespace            = var.namespace
      stage                = var.stage
      name                 = var.name
      attributes           = var.attributes
      vpc_id               = module.vpc.vpc_id
      igw_id               = module.vpc.igw_id
      cidr_block           = module.vpc.vpc_cidr_block
      nat_gateway_enabled  = false
      nat_instance_enabled = false
      tags                 = local.tags
    }

    module "eks_cluster" {
      source                = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=tags/0.13.0"
      namespace             = var.namespace
      stage                 = var.stage
      name                  = var.name
      attributes            = var.attributes
      tags                  = var.tags
      region                = var.region
      vpc_id                = module.vpc.vpc_id
      subnet_ids            = module.subnets.public_subnet_ids
      kubernetes_version    = var.kubernetes_version
      kubeconfig_path       = var.kubeconfig_path
      oidc_provider_enabled = var.oidc_provider_enabled

      workers_role_arns          = [module.eks_node_group.eks_node_group_role_arn]
      workers_security_group_ids = []
    }

    module "eks_node_group" {
      source                = "git::https://github.com/cloudposse/terraform-aws-eks-node-group.git?ref=master"
      namespace                 = var.namespace
      stage                     = var.stage
      name                      = var.name
      attributes                = var.attributes
      tags                      = var.tags
      subnet_ids                = module.subnets.public_subnet_ids
      instance_types            = var.instance_types
      desired_size              = var.desired_size
      min_size                  = var.min_size
      max_size                  = var.max_size
      cluster_name              = module.eks_cluster.eks_cluster_id
      kubernetes_version        = var.kubernetes_version
    }
```






<!-- markdownlint-disable -->
## Makefile Targets
```text
Available targets:

  help                                Help screen
  help/all                            Display help for all targets
  help/short                          This help short screen
  lint                                Lint terraform code

```
<!-- markdownlint-restore -->
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
| after\_cluster\_joining\_userdata | Additional commands to execute on each worker node after joining the EKS cluster (after executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production | `string` | `""` | no |
| ami\_image\_id | AMI to use. Ignored of `launch_template_id` is supplied. | `string` | `null` | no |
| ami\_release\_version | AMI version to use, e.g. "1.16.13-20200821" (no "v"). Defaults to latest version for Kubernetes version. | `string` | `null` | no |
| ami\_type | Type of Amazon Machine Image (AMI) associated with the EKS Node Group.<br>Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64`, `AL2_x86_64_GPU`, and `AL2_ARM_64`. | `string` | `"AL2_x86_64"` | no |
| attributes | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| before\_cluster\_joining\_userdata | Additional commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production | `string` | `""` | no |
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
| instance\_types | Set of instance types associated with the EKS Node Group. Defaults to ["t3.medium"]. Terraform will only perform drift detection if a configuration value is provided | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
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
| userdata\_override | Many features of this module rely on the `bootstrap.sh` provided with Amazon Linux, and this module<br>may generate "user data" that expects to find that script. If you want to use an AMI that does is not<br>compatible with the Amazon Linux `bootstrap.sh` initialization, then use `userdata_override` to provide<br>your own (Base64 encoded) user data. Use "" to prevent any user data from being set.<br><br>Setting `userdata_override` disables `kubernetes_taints`, `kubelet_additional_options`,<br>`before_cluster_joining_userdata`, `after_cluster_joining_userdata`, and `bootstrap_additional_options`. | `string` | `null` | no |

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



## Share the Love

Like this project? Please give it a ★ on [our GitHub](https://github.com/cloudposse/terraform-aws-eks-node-group)! (it helps us **a lot**)

Are you using this project or any of our other projects? Consider [leaving a testimonial][testimonial]. =)


## Related Projects

Check out these related projects.

- [terraform-aws-eks-cluster](https://github.com/cloudposse/terraform-aws-eks-cluster) - Terraform module to provision an EKS cluster on AWS
- [terraform-aws-eks-workers](https://github.com/cloudposse/terraform-aws-eks-workers) - Terraform module to provision an AWS AutoScaling Group, IAM Role, and Security Group for EKS Workers
- [terraform-aws-ec2-autoscale-group](https://github.com/cloudposse/terraform-aws-ec2-autoscale-group) - Terraform module to provision Auto Scaling Group and Launch Template on AWS
- [terraform-aws-ecs-container-definition](https://github.com/cloudposse/terraform-aws-ecs-container-definition) - Terraform module to generate well-formed JSON documents (container definitions) that are passed to the  aws_ecs_task_definition Terraform resource
- [terraform-aws-ecs-alb-service-task](https://github.com/cloudposse/terraform-aws-ecs-alb-service-task) - Terraform module which implements an ECS service which exposes a web service via ALB
- [terraform-aws-ecs-web-app](https://github.com/cloudposse/terraform-aws-ecs-web-app) - Terraform module that implements a web app on ECS and supports autoscaling, CI/CD, monitoring, ALB integration, and much more
- [terraform-aws-ecs-codepipeline](https://github.com/cloudposse/terraform-aws-ecs-codepipeline) - Terraform module for CI/CD with AWS Code Pipeline and Code Build for ECS
- [terraform-aws-ecs-cloudwatch-autoscaling](https://github.com/cloudposse/terraform-aws-ecs-cloudwatch-autoscaling) - Terraform module to autoscale ECS Service based on CloudWatch metrics
- [terraform-aws-ecs-cloudwatch-sns-alarms](https://github.com/cloudposse/terraform-aws-ecs-cloudwatch-sns-alarms) - Terraform module to create CloudWatch Alarms on ECS Service level metrics
- [terraform-aws-ec2-instance](https://github.com/cloudposse/terraform-aws-ec2-instance) - Terraform module for providing a general purpose EC2 instance
- [terraform-aws-ec2-instance-group](https://github.com/cloudposse/terraform-aws-ec2-instance-group) - Terraform module for provisioning multiple general purpose EC2 hosts for stateful applications



## Help

**Got a question?** We got answers.

File a GitHub [issue](https://github.com/cloudposse/terraform-aws-eks-node-group/issues), send us an [email][email] or join our [Slack Community][slack].

[![README Commercial Support][readme_commercial_support_img]][readme_commercial_support_link]

## DevOps Accelerator for Startups


We are a [**DevOps Accelerator**][commercial_support]. We'll help you build your cloud infrastructure from the ground up so you can own it. Then we'll show you how to operate it and stick around for as long as you need us.

[![Learn More](https://img.shields.io/badge/learn%20more-success.svg?style=for-the-badge)][commercial_support]

Work directly with our team of DevOps experts via email, slack, and video conferencing.

We deliver 10x the value for a fraction of the cost of a full-time engineer. Our track record is not even funny. If you want things done right and you need it done FAST, then we're your best bet.

- **Reference Architecture.** You'll get everything you need from the ground up built using 100% infrastructure as code.
- **Release Engineering.** You'll have end-to-end CI/CD with unlimited staging environments.
- **Site Reliability Engineering.** You'll have total visibility into your apps and microservices.
- **Security Baseline.** You'll have built-in governance with accountability and audit logs for all changes.
- **GitOps.** You'll be able to operate your infrastructure via Pull Requests.
- **Training.** You'll receive hands-on training so your team can operate what we build.
- **Questions.** You'll have a direct line of communication between our teams via a Shared Slack channel.
- **Troubleshooting.** You'll get help to triage when things aren't working.
- **Code Reviews.** You'll receive constructive feedback on Pull Requests.
- **Bug Fixes.** We'll rapidly work with you to fix any bugs in our projects.

## Slack Community

Join our [Open Source Community][slack] on Slack. It's **FREE** for everyone! Our "SweetOps" community is where you get to talk with others who share a similar vision for how to rollout and manage infrastructure. This is the best place to talk shop, ask questions, solicit feedback, and work together as a community to build totally *sweet* infrastructure.

## Discourse Forums

Participate in our [Discourse Forums][discourse]. Here you'll find answers to commonly asked questions. Most questions will be related to the enormous number of projects we support on our GitHub. Come here to collaborate on answers, find solutions, and get ideas about the products and services we value. It only takes a minute to get started! Just sign in with SSO using your GitHub account.

## Newsletter

Sign up for [our newsletter][newsletter] that covers everything on our technology radar.  Receive updates on what we're up to on GitHub as well as awesome new projects we discover.

## Office Hours

[Join us every Wednesday via Zoom][office_hours] for our weekly "Lunch & Learn" sessions. It's **FREE** for everyone!

[![zoom](https://img.cloudposse.com/fit-in/200x200/https://cloudposse.com/wp-content/uploads/2019/08/Powered-by-Zoom.png")][office_hours]

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/cloudposse/terraform-aws-eks-node-group/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing this project or [help out](https://cpco.io/help-out) with our other projects, we would love to hear from you! Shoot us an [email][email].

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull Request** so that we can review your changes

**NOTE:** Be sure to merge the latest changes from "upstream" before making a pull request!


## Copyright

Copyright © 2017-2020 [Cloud Posse, LLC](https://cpco.io/copyright)



## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

```text
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
```









## Trademarks

All other trademarks referenced herein are the property of their respective owners.

## About

This project is maintained and funded by [Cloud Posse, LLC][website]. Like it? Please let us know by [leaving a testimonial][testimonial]!

[![Cloud Posse][logo]][website]

We're a [DevOps Professional Services][hire] company based in Los Angeles, CA. We ❤️  [Open Source Software][we_love_open_source].

We offer [paid support][commercial_support] on all of our projects.

Check out [our other projects][github], [follow us on twitter][twitter], [apply for a job][jobs], or [hire us][hire] to help with your cloud strategy and implementation.



### Contributors

|  [![Erik Osterman][osterman_avatar]][osterman_homepage]<br/>[Erik Osterman][osterman_homepage] | [![Andriy Knysh][aknysh_avatar]][aknysh_homepage]<br/>[Andriy Knysh][aknysh_homepage] | [![Igor Rodionov][goruha_avatar]][goruha_homepage]<br/>[Igor Rodionov][goruha_homepage] |
|---|---|---|

  [osterman_homepage]: https://github.com/osterman
  [osterman_avatar]: https://img.cloudposse.com/150x150/https://github.com/osterman.png
  [aknysh_homepage]: https://github.com/aknysh
  [aknysh_avatar]: https://img.cloudposse.com/150x150/https://github.com/aknysh.png
  [goruha_homepage]: https://github.com/goruha
  [goruha_avatar]: https://img.cloudposse.com/150x150/https://github.com/goruha.png

[![README Footer][readme_footer_img]][readme_footer_link]
[![Beacon][beacon]][website]

  [logo]: https://cloudposse.com/logo-300x69.svg
  [docs]: https://cpco.io/docs?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=docs
  [website]: https://cpco.io/homepage?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=website
  [github]: https://cpco.io/github?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=github
  [jobs]: https://cpco.io/jobs?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=jobs
  [hire]: https://cpco.io/hire?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=hire
  [slack]: https://cpco.io/slack?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=slack
  [linkedin]: https://cpco.io/linkedin?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=linkedin
  [twitter]: https://cpco.io/twitter?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=twitter
  [testimonial]: https://cpco.io/leave-testimonial?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=testimonial
  [office_hours]: https://cloudposse.com/office-hours?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=office_hours
  [newsletter]: https://cpco.io/newsletter?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=newsletter
  [discourse]: https://ask.sweetops.com/?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=discourse
  [email]: https://cpco.io/email?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=email
  [commercial_support]: https://cpco.io/commercial-support?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=commercial_support
  [we_love_open_source]: https://cpco.io/we-love-open-source?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=we_love_open_source
  [terraform_modules]: https://cpco.io/terraform-modules?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=terraform_modules
  [readme_header_img]: https://cloudposse.com/readme/header/img
  [readme_header_link]: https://cloudposse.com/readme/header/link?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=readme_header_link
  [readme_footer_img]: https://cloudposse.com/readme/footer/img
  [readme_footer_link]: https://cloudposse.com/readme/footer/link?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=readme_footer_link
  [readme_commercial_support_img]: https://cloudposse.com/readme/commercial-support/img
  [readme_commercial_support_link]: https://cloudposse.com/readme/commercial-support/link?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/terraform-aws-eks-node-group&utm_content=readme_commercial_support_link
  [share_twitter]: https://twitter.com/intent/tweet/?text=terraform-aws-eks-node-group&url=https://github.com/cloudposse/terraform-aws-eks-node-group
  [share_linkedin]: https://www.linkedin.com/shareArticle?mini=true&title=terraform-aws-eks-node-group&url=https://github.com/cloudposse/terraform-aws-eks-node-group
  [share_reddit]: https://reddit.com/submit/?url=https://github.com/cloudposse/terraform-aws-eks-node-group
  [share_facebook]: https://facebook.com/sharer/sharer.php?u=https://github.com/cloudposse/terraform-aws-eks-node-group
  [share_googleplus]: https://plus.google.com/share?url=https://github.com/cloudposse/terraform-aws-eks-node-group
  [share_email]: mailto:?subject=terraform-aws-eks-node-group&body=https://github.com/cloudposse/terraform-aws-eks-node-group
  [beacon]: https://ga-beacon.cloudposse.com/UA-76589703-4/cloudposse/terraform-aws-eks-node-group?pixel&cs=github&cm=readme&an=terraform-aws-eks-node-group
