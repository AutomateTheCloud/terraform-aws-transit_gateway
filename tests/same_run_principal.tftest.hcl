# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

# The RAM principal is created in the same run as the transit gateway, so its ARN is
# unknown at plan time. The module must still plan.
run "same_run_principal" {
  command = plan
  module {
    source = "./tests/fixtures/same_run_principal"
  }
}
