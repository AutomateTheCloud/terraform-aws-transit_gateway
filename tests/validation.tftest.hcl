# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
}

variables {
  details     = { scope = "Test", purpose = "Validation", environment = "test" }
  description = "Shared network"
}

run "scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}
run "purpose_required" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}
run "environment_required" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}

# Regression: an empty description planned, and gave the Name tag "-use1".
run "description_empty" {
  command = plan
  variables { description = "" }
  expect_failures = [var.description]
}

run "description_only_punctuation" {
  command = plan
  variables { description = " - " }
  expect_failures = [var.description]
}

# Found in AWS: 256 characters is rejected at create.
run "description_too_long" {
  command = plan
  variables { description = "a234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456" }
  expect_failures = [var.description]
}

run "description_longest" {
  command = plan
  variables { description = "a23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345" }
}

# Regression: any number was accepted, and AWS rejected it at create.
run "asn_below_private_range" {
  command = plan
  variables { amazon_side_asn = 64511 }
  expect_failures = [var.amazon_side_asn]
}

run "asn_above_16_bit_range" {
  command = plan
  variables { amazon_side_asn = 65535 }
  expect_failures = [var.amazon_side_asn]
}

run "asn_below_32_bit_range" {
  command = plan
  variables { amazon_side_asn = 4199999999 }
  expect_failures = [var.amazon_side_asn]
}

run "asn_above_32_bit_range" {
  command = plan
  variables { amazon_side_asn = 4294967295 }
  expect_failures = [var.amazon_side_asn]
}

run "asn_fraction" {
  command = plan
  variables { amazon_side_asn = 64512.5 }
  expect_failures = [var.amazon_side_asn]
}

run "asn_range_ends" {
  command = plan
  variables { amazon_side_asn = 65534 }
}

run "ram_share_no_principals" {
  command = plan
  variables { ram_share = { principals = {} } }
  expect_failures = [var.ram_share]
}

# Regression: account IDs given as numbers lost leading zeros, or failed for_each.
run "ram_share_account_lost_leading_zero" {
  command = plan
  variables { ram_share = { principals = { network = 012345678901 } } }
  expect_failures = [var.ram_share]
}

run "ram_share_bad_principal" {
  command = plan
  variables { ram_share = { principals = { role = "arn:aws:iam::222222222222:role/network" } } }
  expect_failures = [var.ram_share]
}

run "ram_share_empty_name" {
  command = plan
  variables {
    ram_share = { name = " ", principals = { network = "222222222222" } }
  }
  expect_failures = [var.ram_share]
}
