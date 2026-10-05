# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "amazon_side_asn" {
  description = <<-EOT
    The private Autonomous System Number (ASN) for the Amazon side of Border Gateway Protocol (BGP) sessions, such as those of VPN and Direct Connect attachments. 64512 to 65534, or 4200000000 to 4294967294. Defaults to `64512`. Use a different ASN for each transit gateway you peer or connect to the same network. It can be changed without replacing the transit gateway.
  EOT
  type        = number
  default     = 64512
  nullable    = false

  validation {
    condition     = var.amazon_side_asn == floor(var.amazon_side_asn) && ((var.amazon_side_asn >= 64512 && var.amazon_side_asn <= 65534) || (var.amazon_side_asn >= 4200000000 && var.amazon_side_asn <= 4294967294))
    error_message = "amazon_side_asn must be a whole number from 64512 to 65534, or from 4200000000 to 4294967294."
  }
}

variable "description" {
  description = <<-EOT
    A description of the transit gateway, such as `Shared network`. Up to 255 characters, with at least one letter or digit. It also names the resources: the `Name` tag of the transit gateway is the description in lowercase with words joined by underscores, followed by the Region abbreviation (`shared_network-use1`), and its route table's `Name` tag adds `-default` (`shared_network-use1-default`). It can be changed without replacing anything.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = length(var.description) <= 255 && can(regex("[0-9A-Za-z]", var.description))
    error_message = "description must be 1 to 255 characters, with at least one letter or digit."
  }
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "enable_auto_accept_shared_attachments" {
  description = <<-EOT
    Accept attachment requests from the accounts the transit gateway is shared with automatically. Defaults to `false`: each request waits until you accept it, for example with the `aws_ec2_transit_gateway_vpc_attachment_accepter` resource. It can be changed without replacing the transit gateway.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "enable_default_route_table_association" {
  description = <<-EOT
    Associate each new attachment with the route table this module creates, so that the attachment uses that table's routes. Defaults to `true`. With `false`, an attachment uses no route table until you associate one.

    The module turns it on with the AWS Command Line Interface (AWS CLI), because the AWS provider cannot: see [Things to know](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#things-to-know). It can be changed without replacing the transit gateway; existing attachments keep their association.
  EOT
  type        = bool
  default     = true
  nullable    = false
}

variable "enable_default_route_table_propagation" {
  description = <<-EOT
    Propagate the routes of each new attachment to the route table this module creates, so that every attachment associated with that table can reach it. Defaults to `true`. With `false`, no routes are propagated until you add a propagation.

    The module turns it on with the AWS Command Line Interface (AWS CLI), because the AWS provider cannot: see [Things to know](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#things-to-know). It can be changed without replacing the transit gateway; existing propagations stay.
  EOT
  type        = bool
  default     = true
  nullable    = false
}

variable "enable_dns_support" {
  description = <<-EOT
    Resolve public DNS hostnames to private IP addresses for queries between VPCs attached to the transit gateway. Defaults to `true`. It can be changed without replacing the transit gateway.
  EOT
  type        = bool
  default     = true
  nullable    = false
}

variable "enable_vpn_ecmp_support" {
  description = <<-EOT
    Spread traffic across VPN tunnels with equal-cost multi-path (ECMP) routing, for VPN attachments that use dynamic routing. Defaults to `true`. It can be changed without replacing the transit gateway.
  EOT
  type        = bool
  default     = true
  nullable    = false
}

variable "ram_share" {
  description = <<-EOT
    Shares the transit gateway with other AWS accounts through AWS Resource Access Manager (RAM), so that they can attach their own VPCs and VPN connections to it. Defaults to `null`: the transit gateway is not shared. The accounts that receive it can create attachments, but cannot change or delete the transit gateway, and their attachments wait for your acceptance unless `enable_auto_accept_shared_attachments` is `true`.

    - `principals` - (Required) Who to share the transit gateway with, as a map from a name you choose to an AWS account ID (`111111111111`), an organizational unit ARN (`arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111`) or an organization ARN (`arn:aws:organizations::111111111111:organization/o-exampleorgid`). At least one. The names are only keys for Terraform, so a principal can be added or removed without affecting the others. Share with the narrowest group that needs the transit gateway: an organization ARN shares it with every account in the organization.
    - `allow_external_principals` - (Optional) Allow sharing with accounts outside your AWS organization. Defaults to `false`: RAM then accepts only principals in your organization, which must have sharing with AWS Organizations turned on. With `true`, each account outside the organization gets an invitation that it must accept.
    - `name` - (Optional) The name of the resource share. Defaults to `tgw-<description>-<Region abbreviation>`, from `description` in lowercase with words joined by underscores, such as `tgw-shared_network-use1` for the description `Shared network` in us-east-1.
  EOT
  type = object({
    principals                = map(string)
    allow_external_principals = optional(bool, false)
    name                      = optional(string)
  })
  default = null

  validation {
    condition     = var.ram_share == null || try(length(var.ram_share.principals) > 0, false)
    error_message = "ram_share.principals must list at least one principal."
  }

  validation {
    condition = var.ram_share == null || alltrue([
      for p in values(try(var.ram_share.principals, {})) :
      can(regex("^([0-9]{12}|arn:aws[a-z-]*:organizations::[0-9]{12}:(organization/o-[a-z0-9]{10,32}|ou/o-[a-z0-9]{10,32}/ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}))$", p))
    ])
    error_message = "Each ram_share.principals value must be a 12-digit AWS account ID, an organizational unit ARN or an organization ARN."
  }

  validation {
    condition     = var.ram_share == null || try(trimspace(var.ram_share.name), "unset") != ""
    error_message = "ram_share.name must not be empty; leave it out for the default name."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the transit gateway, its route table and its resource share in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.
  EOT
  type        = string
  default     = null
}
