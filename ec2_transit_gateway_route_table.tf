# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_ec2_transit_gateway_route_table" "this" {
  region             = var.region
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(local.tags, { "Name" = "${local.name}-default" })
}
