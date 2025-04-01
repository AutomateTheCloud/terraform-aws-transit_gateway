resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(
    local.tags,
    tomap({
      "Name" = "${lower(replace(replace(var.description, "/[^0-9A-Za-z]/", " "), "/\\s{1,}/", "_"))}-${local.aws.region.abbr}-default"
    })
  )
  provider = aws.this
}

resource "null_resource" "modify_tgw_to_enable_default_route_association" {
  count = (var.enable_default_route_table_association ? 1 : 0)
  triggers = {
    aws_region         = local.aws.region.name
    transit_gateway_id = aws_ec2_transit_gateway.this.id
  }

  lifecycle {
    ignore_changes = [
      triggers["aws_region"],
      triggers["transit_gateway_id"]
    ]
  }

  provisioner "local-exec" {
    command = "aws ec2 modify-transit-gateway --transit-gateway-id ${aws_ec2_transit_gateway.this.id} --options DefaultRouteTableAssociation=enable,AssociationDefaultRouteTableId=${aws_ec2_transit_gateway_route_table.this.id} --region ${local.aws.region.name}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 modify-transit-gateway --transit-gateway-id ${self.triggers.transit_gateway_id} --options DefaultRouteTableAssociation=disable --region ${self.triggers.aws_region}"
  }
}

resource "null_resource" "modify_tgw_to_enable_default_route_propagation" {
  count = (var.enable_default_route_table_propagation ? 1 : 0)
  triggers = {
    aws_region         = local.aws.region.name
    transit_gateway_id = aws_ec2_transit_gateway.this.id
  }

  lifecycle {
    ignore_changes = [
      triggers["aws_region"],
      triggers["transit_gateway_id"]
    ]
  }

  provisioner "local-exec" {
    command = "aws ec2 modify-transit-gateway --transit-gateway-id ${aws_ec2_transit_gateway.this.id} --options DefaultRouteTablePropagation=enable,PropagationDefaultRouteTableId=${aws_ec2_transit_gateway_route_table.this.id} --region ${local.aws.region.name}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 modify-transit-gateway --transit-gateway-id ${self.triggers.transit_gateway_id} --options DefaultRouteTablePropagation=disable --region ${self.triggers.aws_region}"
  }
}
