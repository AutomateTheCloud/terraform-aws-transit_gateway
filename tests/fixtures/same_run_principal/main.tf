# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A transit gateway shared with an organizational unit created in the same run, so the
# principal's ARN is unknown at plan time.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

resource "aws_organizations_organizational_unit" "this" {
  name      = "Workloads"
  parent_id = "r-abcd"
}

module "transit_gateway" {
  source = "../../.."

  details     = { scope = "Test", purpose = "Same Run", environment = "test" }
  description = "Shared network"

  ram_share = {
    principals = { workloads = aws_organizations_organizational_unit.this.arn }
  }
}
