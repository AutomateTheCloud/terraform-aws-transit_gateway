# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A transit gateway created with only the module's required inputs, with one existing VPC
# attached to it. The VPC is associated with the transit gateway's route table and its
# routes are propagated there, so every VPC attached later can reach it.
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

variable "vpc_id" {
  description = "ID of a VPC in us-east-1 to attach, such as vpc-0123456789abcdef0"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of subnets in that VPC for the attachment, one per Availability Zone, such as [\"subnet-0123456789abcdef0\"]"
  type        = list(string)
}

module "transit_gateway" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Basic Transit Gateway"
    environment = "Development"
  }

  description = "Example network hub"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = module.transit_gateway.metadata.transit_gateway.id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids

  tags = merge(module.transit_gateway.metadata.details.tags, { Name = "example-basic" })

  # Attach only after the module has made its route table the default, so the
  # attachment is associated with it and propagates to it.
  depends_on = [module.transit_gateway]
}

output "transit_gateway_id" {
  description = "ID of the transit gateway, for attaching more VPCs"
  value       = module.transit_gateway.metadata.transit_gateway.id
}

output "route_table_id" {
  description = "ID of the transit gateway's route table, for routes and associations"
  value       = module.transit_gateway.metadata.transit_gateway_route_table.id
}
