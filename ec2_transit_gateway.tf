# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_ec2_transit_gateway" "this" {
  region                          = var.region
  description                     = var.description
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.enable_auto_accept_shared_attachments ? "enable" : "disable"
  dns_support                     = var.enable_dns_support ? "enable" : "disable"
  vpn_ecmp_support                = var.enable_vpn_ecmp_support ? "enable" : "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  # Created with both off, so AWS does not create a default route table of its own. The
  # module's route table is made the default afterward (default_route_table.tf), which
  # changes these two settings outside Terraform.
  lifecycle {
    ignore_changes = [
      default_route_table_association,
      default_route_table_propagation,
    ]
  }

  tags = merge(local.tags, { "Name" = local.name })
}
