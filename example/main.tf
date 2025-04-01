terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: Transit Gateway
module "transit_gateway" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope        = "Demo"
    purpose      = "Transit Gateway"
    purpose_abbr = "tgw"
    environment  = "prd"
    additional_tags = {
      "Project"   = "Project Name"
      "ProjectID" = "123456789"
      "Contact"   = "David Singer - david.singer@example.com"
    }
  }
  description                            = "Example TG"
  amazon_side_asn                        = 64512
  enable_auto_accept_shared_attachments  = true
  enable_default_route_table_association = true
  enable_default_route_table_propagation = true
  enable_dns_support                     = true
  enable_vpn_ecmp_support                = true
  enable_share_with_organization         = false
  enable_share_with_accounts             = true
}

# resource "aws_ram_principal_association" "share-012345678901" {
  # principal          = "012345678901"
  # resource_share_arn = module.transit_gateway.metadata.ram_resource_share.arn
  # provider           = aws.example
# }

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value       = module.transit_gateway.metadata
}
# output "share" {
  # description = "Share"
  # value = {
    # "012345678901" = aws_ram_principal_association.share-012345678901
  # }
# }
