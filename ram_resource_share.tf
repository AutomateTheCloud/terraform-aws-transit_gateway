resource "aws_ram_resource_share" "this" {
  count                     = (var.enable_share_with_organization || var.enable_share_with_accounts ? 1 : 0)
  name                      = "tgw-${lower(replace(replace(var.description, "/[^0-9A-Za-z]/", " "), "/\\s{1,}/", "_"))}-${local.aws.region.abbr}"
  allow_external_principals = (var.enable_share_with_accounts ? true : false)
  tags                      = local.tags
  provider                  = aws.this
}

resource "aws_ram_resource_association" "this" {
  count              = (var.enable_share_with_organization || var.enable_share_with_accounts ? 1 : 0)
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = try(aws_ram_resource_share.this[0].id, "")
  provider           = aws.this
}
