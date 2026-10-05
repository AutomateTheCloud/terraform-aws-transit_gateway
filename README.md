# Terraform module for AWS Transit Gateway

Creates an AWS transit gateway, a regional network hub that connects your VPCs, VPN connections and AWS Direct Connect gateways, with a route table for it. It can make that route table the default for new attachments, and share the transit gateway with other AWS accounts through AWS Resource Access Manager (RAM), so they can attach their own VPCs.

A transit gateway created with only the required inputs is not shared with anyone, and attachment requests from other accounts wait for your acceptance. Each new attachment is associated with the module's route table, and its routes are propagated there, so every attached VPC can reach every other. To keep attachments apart, turn those two settings off and route them yourself. Sharing is an explicit opt-in, limited to the accounts, organizational units or organization you list, and to your own AWS organization unless you allow more.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Description, also used in the `Name` tags | Required | `description` |
| Autonomous System Number (ASN) on the Amazon side | `64512` | `amazon_side_asn` |
| New attachments associated with the module's route table | Yes, through the AWS CLI | `enable_default_route_table_association` |
| New attachments' routes propagated to the module's route table | Yes, through the AWS CLI | `enable_default_route_table_propagation` |
| Attachment requests from shared accounts | Wait for acceptance | `enable_auto_accept_shared_attachments` |
| DNS resolution between attached VPCs | On | `enable_dns_support` |
| Equal-cost multi-path (ECMP) routing for VPN connections | On | `enable_vpn_ecmp_support` |
| Shared with other accounts | Not shared | `ram_share` |
| Sharing outside your AWS organization | Not allowed | `ram_share.allow_external_principals` |
| Region | The provider's | `region` |

## Usage

```hcl
module "transit_gateway" {
  source  = "AutomateTheCloud/transit_gateway/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Network Hub"
    environment = "Production"
  }

  description = "Production network hub"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app" {
  transit_gateway_id = module.transit_gateway.metadata.transit_gateway.id
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]

  # Attach after the module has made its route table the default.
  depends_on = [module.transit_gateway]
}
```

`details` and `description` are required. `details` sets the `Scope`, `Purpose` and `Environment` tags on every resource. The attached VPC is associated with the module's route table and its routes are propagated there; to send traffic to other attached VPCs, add routes to the transit gateway in the VPC's own route tables.

The transit gateway is created in the provider's Region unless you set `region`. Attachments must be in the same Region as the transit gateway:

```hcl
module "transit_gateway_west" {
  source  = "AutomateTheCloud/transit_gateway/aws"
  version = "~> 1.0"

  region      = "us-west-2"
  details     = { scope = "Automate the Cloud", purpose = "Network Hub", environment = "Production" }
  description = "Production network hub"
}
```

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the transit gateway belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Network Hub"        # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a transit gateway in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the transit gateway, the VPCs attached to it and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Network Hub"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "network_hub" {
  source  = "AutomateTheCloud/transit_gateway/aws"
  version = "~> 1.0"

  details     = local.details
  description = "Production network hub"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Network Hub` becomes `network_hub`), and `machine`, lowercase letters and numbers only (`networkhub`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.network_hub.metadata.transit_gateway.id` for the transit gateway's ID, or `module.network_hub.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`. AWS bills each transit gateway attachment for every hour it exists, and for the data it processes; see [AWS Transit Gateway pricing](https://aws.amazon.com/transit-gateway/pricing/).

- [Basic transit gateway](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway/tree/main/examples/basic): only the required inputs, with an existing VPC attached.
- [Shared transit gateway](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway/tree/main/examples/shared): shared with one other account in your AWS organization, with no default route table, so that account's attachments reach nothing until you route them.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway/tree/main/examples/complete): every input, in a Region other than the provider's, shared with an organizational unit, with attachments accepted automatically and a shared services VPC attached.

## Things to know

### The default route table settings need the AWS CLI

With `enable_default_route_table_association` or `enable_default_route_table_propagation` on, both the default, the module runs `aws ec2 modify-transit-gateway` on the machine that runs Terraform, to make its route table the transit gateway's default. The AWS provider cannot do it: AWS turns these settings on only together with the route table's ID, and the provider's resources for them do not send both.

So, wherever `terraform apply` or `terraform destroy` runs:

- The [AWS Command Line Interface](https://aws.amazon.com/cli/) (AWS CLI) must be installed and on the `PATH`.
- The AWS CLI finds its own credentials, the same way as when you run it yourself: from environment variables such as `AWS_ACCESS_KEY_ID` or `AWS_PROFILE`, or its configuration files. It does not use the credentials, `profile` or `assume_role` set in your `provider "aws"` block. Make sure it reaches the same account as the provider, for example by setting `AWS_PROFILE` or the credential environment variables instead of configuring them in the provider block. If it reaches another account, the command fails with `InvalidTransitGatewayID.NotFound`.
- The command runs when the transit gateway is created, when either setting changes, and when the transit gateway or its route table is replaced. With either setting on, a later `terraform destroy` runs it too, to turn the settings off. `terraform plan` never runs it.

With both settings `false`, the module runs no command and needs no AWS CLI.

The transit gateway is created with both settings off, so that AWS does not create a default route table of its own, which Terraform would not manage. Its `default_route_table_association` and `default_route_table_propagation` arguments are then left alone by Terraform (`ignore_changes`), and the `metadata` output leaves out the default route table IDs, which the AWS CLI changes after the transit gateway is created.

### Default association and propagation affect new attachments only

The two settings decide what happens to each attachment when it is created. Turning one off later does not change existing attachments: they keep their association and propagations. Turning one on later does not associate or propagate existing attachments either; do that with the `aws_ec2_transit_gateway_route_table_association` and `aws_ec2_transit_gateway_route_table_propagation` resources. To be sure an attachment in the same configuration is created after the module has set the default, give it `depends_on = [module.<name>]`, as in [Usage](#usage).

With both settings on, every attachment can reach every other, including the attachments of the accounts you share the transit gateway with. To keep them apart, for example production and development VPCs, turn both off and associate and propagate each attachment yourself, in route tables you create with `aws_ec2_transit_gateway_route_table`.

### Sharing the transit gateway with other accounts

With `ram_share`, the module creates a Resource Access Manager (RAM) resource share, adds the transit gateway to it, and shares it with each principal in `ram_share.principals`: an account, an organizational unit or a whole organization. The accounts that receive the transit gateway can attach their own VPCs and VPN connections to it. They cannot change or delete it. Share with the narrowest group that needs it.

By default the share accepts only principals in your own AWS organization. Sharing within an organization needs sharing with AWS Organizations turned on once, in the organization's management account (`aws ram enable-sharing-with-aws-organization`). The accounts then receive the transit gateway without an invitation. To share with an account outside your organization, set `ram_share.allow_external_principals = true`; that account then gets an invitation, which it must accept, for example with an `aws_ram_resource_share_accepter` resource.

According to the [AWS Transit Gateway documentation](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-transit-gateways.html), an attachment created by an account the transit gateway is shared with waits until you accept it in the transit gateway's account, for example with an `aws_ec2_transit_gateway_vpc_attachment_accepter` resource, unless `enable_auto_accept_shared_attachments` is `true`.

Removing a principal from `ram_share.principals` stops sharing with it, and removing `ram_share` deletes the share. The transit gateway itself is not changed.

### Changes and replacement

Changing `description`, `amazon_side_asn`, `enable_auto_accept_shared_attachments`, `enable_dns_support`, `enable_vpn_ecmp_support`, the two default route table settings or `ram_share` updates the transit gateway in place. Changing `region` replaces the transit gateway, its route table and the share, and every attachment to them.

### Destroying a transit gateway

AWS will not delete a transit gateway that still has attachments, including attachments from the accounts it is shared with. Remove them first. Attachments in the same configuration are removed first by Terraform when they refer to the module's `metadata` output.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against a mocked AWS provider, so they need no AWS account and do not run the AWS CLI:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_description"></a> [description](#input_description)

Description: A description of the transit gateway, such as `Shared network`. Up to 255 characters, with at least one letter or digit. It also names the resources: the `Name` tag of the transit gateway is the description in lowercase with words joined by underscores, followed by the Region abbreviation (`shared_network-use1`), and its route table's `Name` tag adds `-default` (`shared_network-use1-default`). It can be changed without replacing anything.

Type: `string`

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_amazon_side_asn"></a> [amazon_side_asn](#input_amazon_side_asn)

Description: The private Autonomous System Number (ASN) for the Amazon side of Border Gateway Protocol (BGP) sessions, such as those of VPN and Direct Connect attachments. 64512 to 65534, or 4200000000 to 4294967294. Defaults to `64512`. Use a different ASN for each transit gateway you peer or connect to the same network. It can be changed without replacing the transit gateway.

Type: `number`

Default: `64512`

#### <a name="input_enable_auto_accept_shared_attachments"></a> [enable_auto_accept_shared_attachments](#input_enable_auto_accept_shared_attachments)

Description: Accept attachment requests from the accounts the transit gateway is shared with automatically. Defaults to `false`: each request waits until you accept it, for example with the `aws_ec2_transit_gateway_vpc_attachment_accepter` resource. It can be changed without replacing the transit gateway.

Type: `bool`

Default: `false`

#### <a name="input_enable_default_route_table_association"></a> [enable_default_route_table_association](#input_enable_default_route_table_association)

Description: Associate each new attachment with the route table this module creates, so that the attachment uses that table's routes. Defaults to `true`. With `false`, an attachment uses no route table until you associate one.

The module turns it on with the AWS Command Line Interface (AWS CLI), because the AWS provider cannot: see [Things to know](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#things-to-know). It can be changed without replacing the transit gateway; existing attachments keep their association.

Type: `bool`

Default: `true`

#### <a name="input_enable_default_route_table_propagation"></a> [enable_default_route_table_propagation](#input_enable_default_route_table_propagation)

Description: Propagate the routes of each new attachment to the route table this module creates, so that every attachment associated with that table can reach it. Defaults to `true`. With `false`, no routes are propagated until you add a propagation.

The module turns it on with the AWS Command Line Interface (AWS CLI), because the AWS provider cannot: see [Things to know](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#things-to-know). It can be changed without replacing the transit gateway; existing propagations stay.

Type: `bool`

Default: `true`

#### <a name="input_enable_dns_support"></a> [enable_dns_support](#input_enable_dns_support)

Description: Resolve public DNS hostnames to private IP addresses for queries between VPCs attached to the transit gateway. Defaults to `true`. It can be changed without replacing the transit gateway.

Type: `bool`

Default: `true`

#### <a name="input_enable_vpn_ecmp_support"></a> [enable_vpn_ecmp_support](#input_enable_vpn_ecmp_support)

Description: Spread traffic across VPN tunnels with equal-cost multi-path (ECMP) routing, for VPN attachments that use dynamic routing. Defaults to `true`. It can be changed without replacing the transit gateway.

Type: `bool`

Default: `true`

#### <a name="input_ram_share"></a> [ram_share](#input_ram_share)

Description: Shares the transit gateway with other AWS accounts through AWS Resource Access Manager (RAM), so that they can attach their own VPCs and VPN connections to it. Defaults to `null`: the transit gateway is not shared. The accounts that receive it can create attachments, but cannot change or delete the transit gateway, and their attachments wait for your acceptance unless `enable_auto_accept_shared_attachments` is `true`.

- `principals` - (Required) Who to share the transit gateway with, as a map from a name you choose to an AWS account ID (`111111111111`), an organizational unit ARN (`arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111`) or an organization ARN (`arn:aws:organizations::111111111111:organization/o-exampleorgid`). At least one. The names are only keys for Terraform, so a principal can be added or removed without affecting the others. Share with the narrowest group that needs the transit gateway: an organization ARN shares it with every account in the organization.
- `allow_external_principals` - (Optional) Allow sharing with accounts outside your AWS organization. Defaults to `false`: RAM then accepts only principals in your organization, which must have sharing with AWS Organizations turned on. With `true`, each account outside the organization gets an invitation that it must accept.
- `name` - (Optional) The name of the resource share. Defaults to `tgw-<description>-<Region abbreviation>`, from `description` in lowercase with words joined by underscores, such as `tgw-shared_network-use1` for the description `Shared network` in us-east-1.

Type:

```hcl
object({
    principals                = map(string)
    allow_external_principals = optional(bool, false)
    name                      = optional(string)
  })
```

Default: `null`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the transit gateway, its route table and its resource share in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.

Type: `string`

Default: `null`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the Region the transit gateway is in.
- `transit_gateway` - The transit gateway: its `id` (use this to attach VPCs and VPN connections), `arn`, `description`, `amazon_side_asn`, `auto_accept_shared_attachments`, `dns_support`, `vpn_ecmp_support`, `multicast_support`, `security_group_referencing_support` (each `enable` or `disable`), `owner_id`, `region`, `tags` and `tags_all`.
- `transit_gateway_route_table` - The route table the module creates: its `id`, `arn`, `transit_gateway_id`, `region`, `tags` and `tags_all`. It is the default association table when `enable_default_route_table_association` is `true`, and the default propagation table when `enable_default_route_table_propagation` is `true`.
- `ram_resource_share` - The Resource Access Manager (RAM) resource share: its `arn`, `id`, `name`, `allow_external_principals`, `region`, `tags` and `tags_all`. `null` without `ram_share`.
- `ram_resource_association` - The association of the transit gateway with the resource share: its `id`, `resource_arn`, `resource_share_arn` and `region`. `null` without `ram_share`.
- `ram_principal_association` - The principals the transit gateway is shared with, keyed like `ram_share.principals`, each with its `id`, `principal`, `resource_share_arn` and `region`. `null` without `ram_share`.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
