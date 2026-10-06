# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the Region the transit gateway is in.
    - `transit_gateway` - The transit gateway: its `id` (use this to attach VPCs and VPN connections), `arn`, `description`, `amazon_side_asn`, `auto_accept_shared_attachments`, `dns_support`, `vpn_ecmp_support`, `multicast_support`, `security_group_referencing_support` (each `enable` or `disable`), `owner_id`, `region`, `tags` and `tags_all`.
    - `transit_gateway_route_table` - The route table the module creates: its `id`, `arn`, `transit_gateway_id`, `region`, `tags` and `tags_all`. It is the default association table when `enable_default_route_table_association` is `true`, and the default propagation table when `enable_default_route_table_propagation` is `true`.
    - `ram_resource_share` - The Resource Access Manager (RAM) resource share: its `arn`, `id`, `name`, `allow_external_principals`, `region`, `tags` and `tags_all`. `null` without `ram_share`.
    - `ram_resource_association` - The association of the transit gateway with the resource share: its `id`, `resource_arn`, `resource_share_arn` and `region`. `null` without `ram_share`.
    - `ram_principal_association` - The principals the transit gateway is shared with, keyed like `ram_share.principals`, each with its `id`, `principal`, `resource_share_arn` and `region`. `null` without `ram_share`.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    transit_gateway             = local.output_resources.transit_gateway
    transit_gateway_route_table = local.output_resources.transit_gateway_route_table
    ram_resource_share          = local.output_resources.ram_resource_share
    ram_resource_association    = local.output_resources.ram_resource_association
    ram_principal_association   = local.output_resources.ram_principal_association
  }
}

# Each resource's attributes, listed one by one: referencing a whole resource would
# also reference its deprecated and sensitive attributes, and every caller's plan
# would then print warnings or the output would become sensitive.
locals {
  output_resources = {
    # Left out: encryption_support, which is newer than the provider floor; the default
    # route table settings and IDs (association_default_route_table_id,
    # default_route_table_association, and the propagation ones), which the AWS CLI
    # changes after the transit gateway is created (default_route_table.tf); and
    # transit_gateway_cidr_blocks, which the module does not set and the provider saves
    # as null and reads back as [] (seen in AWS on provider 6.67.0). Each would show the
    # output changing on the caller's next plan.
    transit_gateway = {
      amazon_side_asn                    = aws_ec2_transit_gateway.this.amazon_side_asn
      arn                                = aws_ec2_transit_gateway.this.arn
      auto_accept_shared_attachments     = aws_ec2_transit_gateway.this.auto_accept_shared_attachments
      description                        = aws_ec2_transit_gateway.this.description
      dns_support                        = aws_ec2_transit_gateway.this.dns_support
      id                                 = aws_ec2_transit_gateway.this.id
      multicast_support                  = aws_ec2_transit_gateway.this.multicast_support
      owner_id                           = aws_ec2_transit_gateway.this.owner_id
      region                             = aws_ec2_transit_gateway.this.region
      security_group_referencing_support = aws_ec2_transit_gateway.this.security_group_referencing_support
      tags                               = aws_ec2_transit_gateway.this.tags
      tags_all                           = aws_ec2_transit_gateway.this.tags_all
      vpn_ecmp_support                   = aws_ec2_transit_gateway.this.vpn_ecmp_support
    }

    # Left out for the same reason: default_association_route_table and
    # default_propagation_route_table.
    transit_gateway_route_table = {
      arn                = aws_ec2_transit_gateway_route_table.this.arn
      id                 = aws_ec2_transit_gateway_route_table.this.id
      region             = aws_ec2_transit_gateway_route_table.this.region
      tags               = aws_ec2_transit_gateway_route_table.this.tags
      tags_all           = aws_ec2_transit_gateway_route_table.this.tags_all
      transit_gateway_id = aws_ec2_transit_gateway_route_table.this.transit_gateway_id
    }

    # Left out: resource_share_configuration, which is newer than the provider floor, and
    # permission_arns, which AWS fills in when the transit gateway is added to the share,
    # after the share is saved, so the next plan would show the output changing (seen in
    # AWS on provider 6.67.0).
    ram_resource_share = length(aws_ram_resource_share.this) == 0 ? null : {
      allow_external_principals = aws_ram_resource_share.this[0].allow_external_principals
      arn                       = aws_ram_resource_share.this[0].arn
      id                        = aws_ram_resource_share.this[0].id
      name                      = aws_ram_resource_share.this[0].name
      region                    = aws_ram_resource_share.this[0].region
      tags                      = aws_ram_resource_share.this[0].tags
      tags_all                  = aws_ram_resource_share.this[0].tags_all
    }

    ram_resource_association = length(aws_ram_resource_association.this) == 0 ? null : {
      id                 = aws_ram_resource_association.this[0].id
      region             = aws_ram_resource_association.this[0].region
      resource_arn       = aws_ram_resource_association.this[0].resource_arn
      resource_share_arn = aws_ram_resource_association.this[0].resource_share_arn
    }

    # Keyed like var.ram_share.principals.
    ram_principal_association = local.ram_share_enabled ? {
      for k in keys(local.ram_principals) : k => {
        id                 = aws_ram_principal_association.this[k].id
        principal          = aws_ram_principal_association.this[k].principal
        region             = aws_ram_principal_association.this[k].region
        resource_share_arn = aws_ram_principal_association.this[k].resource_share_arn
      }
    } : null
  }
}
