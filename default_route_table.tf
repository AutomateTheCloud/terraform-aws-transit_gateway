# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Makes the module's route table the transit gateway's default association and
# propagation table. The AWS API turns these on only together with the route table's ID,
# and the AWS provider has no resource that does that for a transit gateway created with
# them off, so the module runs the AWS CLI.
#
# The commands are stored in input, so the destroy-time command acts on the transit
# gateway and Region the create-time one did. A new transit gateway, route table or
# Region, or a change to either setting, replaces this resource: the old settings are
# turned off, then the new ones on.
resource "terraform_data" "default_route_table" {
  count = local.default_route_table_enabled ? 1 : 0

  triggers_replace = [
    local.aws.region.name,
    aws_ec2_transit_gateway.this.id,
    aws_ec2_transit_gateway_route_table.this.id,
    local.default_route_table_options,
  ]

  input = {
    create  = "aws ec2 modify-transit-gateway --region ${local.aws.region.name} --transit-gateway-id ${aws_ec2_transit_gateway.this.id} --options ${local.default_route_table_options.enable}"
    destroy = "aws ec2 modify-transit-gateway --region ${local.aws.region.name} --transit-gateway-id ${aws_ec2_transit_gateway.this.id} --options ${local.default_route_table_options.disable}"
  }

  provisioner "local-exec" {
    command = self.input.create
  }

  provisioner "local-exec" {
    when    = destroy
    command = self.input.destroy
  }
}
