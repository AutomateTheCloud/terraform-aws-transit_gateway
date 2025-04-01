resource "aws_ec2_transit_gateway" "this" {
  description                     = "${var.description} (${local.aws.region.name})"
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = (var.enable_auto_accept_shared_attachments ? "enable" : "disable")
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = (var.enable_dns_support ? "enable" : "disable")
  vpn_ecmp_support                = (var.enable_vpn_ecmp_support ? "enable" : "disable")

  # This is to prevent AWS from creating a default Route Table for which we wouldnt have a TF Resource for
  # If we want the Default Routes set, that is taken care of in a null_resource with the Route Table
  lifecycle {
    ignore_changes = [
      default_route_table_association,
      default_route_table_propagation
    ]
  }

  tags = merge(
    local.tags,
    tomap({
      "Name" = "${lower(replace(replace(var.description, "/[^0-9A-Za-z]/", " "), "/\\s{1,}/", "_"))}-${local.aws.region.abbr}"
    })
  )
  provider = aws.this
}
