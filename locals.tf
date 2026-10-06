# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # The description in lowercase, words joined by underscores: "Shared network" => "shared_network".
  name = "${trim(lower(replace(replace(var.description, "/[^0-9A-Za-z]/", " "), "/\\s{1,}/", "_")), "_")}-${local.aws.region.abbr}"

  # Whether ram_share is null is known at plan time even when its principals come from
  # resources created in the same run, so it can decide count and for_each.
  ram_share_enabled = var.ram_share != null
  ram_principals    = local.ram_share_enabled ? var.ram_share.principals : {}
  ram_share_name    = local.ram_share_enabled ? coalesce(var.ram_share.name, "tgw-${local.name}") : null

  # The AWS CLI options that make the module's route table the transit gateway's default
  # association and propagation table, and the ones that turn them off again.
  default_route_table_enabled = var.enable_default_route_table_association || var.enable_default_route_table_propagation
  default_route_table_options = {
    enable = join(",", concat(
      var.enable_default_route_table_association ? ["DefaultRouteTableAssociation=enable", "AssociationDefaultRouteTableId=${aws_ec2_transit_gateway_route_table.this.id}"] : [],
      var.enable_default_route_table_propagation ? ["DefaultRouteTablePropagation=enable", "PropagationDefaultRouteTableId=${aws_ec2_transit_gateway_route_table.this.id}"] : [],
    ))
    disable = join(",", concat(
      var.enable_default_route_table_association ? ["DefaultRouteTableAssociation=disable"] : [],
      var.enable_default_route_table_propagation ? ["DefaultRouteTablePropagation=disable"] : [],
    ))
  }
}
