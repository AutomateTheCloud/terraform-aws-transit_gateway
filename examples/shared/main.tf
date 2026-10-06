# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A transit gateway shared with one other account in your AWS organization through AWS
# Resource Access Manager (RAM). That account can then attach its own VPCs; each
# attachment waits until it is accepted here.
#
# Attachments are not associated with a route table, and no routes are propagated,
# until you decide: an account that shares the transit gateway cannot reach the others
# by default.

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

variable "network_account_id" {
  description = "ID of the AWS account in your organization to share the transit gateway with, such as 111111111111"
  type        = string
}

module "transit_gateway" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Shared Transit Gateway"
    environment = "Development"
  }

  description = "Example shared network hub"

  # Attachments from the other account use no route table until you associate one.
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false

  ram_share = {
    principals = { network = var.network_account_id }
  }
}

output "transit_gateway_id" {
  description = "ID of the transit gateway, for the other account's attachments"
  value       = module.transit_gateway.metadata.transit_gateway.id
}

output "resource_share_arn" {
  description = "ARN of the resource share"
  value       = module.transit_gateway.metadata.ram_resource_share.arn
}
