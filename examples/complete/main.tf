# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Every input of the module: a transit gateway in a Region other than the provider's,
# with its own Autonomous System Number, attachments from shared accounts accepted
# automatically, and sharing with one organizational unit under a chosen share name. A
# shared services VPC is attached, and every VPC the accounts in the organizational unit
# attach later can reach it, and each other, through the module's route table.
#
# Needs the AWS CLI where Terraform runs: see "Things to know" in the module's README.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "organizational_unit_arn" {
  description = "ARN of the organizational unit in your organization to share the transit gateway with, such as arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111"
  type        = string
}

variable "shared_services_vpc_id" {
  description = "ID of a VPC in us-west-2 to attach, such as vpc-0123456789abcdef0"
  type        = string
}

variable "shared_services_subnet_ids" {
  description = "IDs of subnets in that VPC for the attachment, one per Availability Zone"
  type        = list(string)
}

module "transit_gateway" {
  source = "../../"

  region = "us-west-2"

  details = {
    scope            = "Example"
    purpose          = "Complete Transit Gateway"
    purpose_abbr     = "complete"
    environment      = "Development"
    environment_abbr = "dev"
    additional_tags  = { CostCenter = "1234" }
  }

  description                            = "Example network hub for the workloads OU"
  amazon_side_asn                        = 64600
  enable_auto_accept_shared_attachments  = true
  enable_default_route_table_association = true
  enable_default_route_table_propagation = true
  enable_dns_support                     = true
  enable_vpn_ecmp_support                = true

  ram_share = {
    name                      = "example-network-hub"
    allow_external_principals = false
    principals                = { workloads = var.organizational_unit_arn }
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shared_services" {
  region             = "us-west-2"
  transit_gateway_id = module.transit_gateway.metadata.transit_gateway.id
  vpc_id             = var.shared_services_vpc_id
  subnet_ids         = var.shared_services_subnet_ids

  tags = merge(module.transit_gateway.metadata.details.tags, { Name = "example-shared-services" })

  depends_on = [module.transit_gateway]
}

output "metadata" {
  description = "Everything the module created"
  value       = module.transit_gateway.metadata
}
