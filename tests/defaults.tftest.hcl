# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
#
# An apply run with enable_default_route_table_association or _propagation on would run
# the module's AWS CLI command for real, so every apply run here turns both off. The
# commands are checked in plan runs after an apply, when the mocked IDs are known.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_ec2_transit_gateway" {
    defaults = {
      id       = "tgw-0123456789abcdef0"
      arn      = "arn:aws:ec2:us-east-1:111111111111:transit-gateway/tgw-0123456789abcdef0"
      owner_id = "111111111111"
    }
  }
  mock_resource "aws_ec2_transit_gateway_route_table" {
    defaults = {
      id  = "tgw-rtb-0123456789abcdef0"
      arn = "arn:aws:ec2:us-east-1:111111111111:transit-gateway-route-table/tgw-rtb-0123456789abcdef0"
    }
  }
  mock_resource "aws_ram_resource_share" {
    defaults = {
      id  = "arn:aws:ram:us-east-1:111111111111:resource-share/a1b2c3d4-5678-90ab-cdef-example11111"
      arn = "arn:aws:ram:us-east-1:111111111111:resource-share/a1b2c3d4-5678-90ab-cdef-example11111"
    }
  }
}

variables {
  details     = { scope = "Test", purpose = "Defaults", environment = "test" }
  description = "Shared network"
}

# Only the required inputs: not shared, attachments from other accounts wait for
# acceptance, and the module's route table becomes the default for both.
run "defaults" {
  command = plan

  assert {
    condition = alltrue([
      aws_ec2_transit_gateway.this.description == "Shared network",
      aws_ec2_transit_gateway.this.amazon_side_asn == 64512,
      aws_ec2_transit_gateway.this.auto_accept_shared_attachments == "disable",
      aws_ec2_transit_gateway.this.dns_support == "enable",
      aws_ec2_transit_gateway.this.vpn_ecmp_support == "enable",
    ])
    error_message = "Unexpected transit gateway arguments."
  }
  # AWS would otherwise create a default route table that Terraform does not manage.
  assert {
    condition     = aws_ec2_transit_gateway.this.default_route_table_association == "disable" && aws_ec2_transit_gateway.this.default_route_table_propagation == "disable"
    error_message = "The transit gateway must be created without AWS's own default route table."
  }
  assert {
    condition     = length(terraform_data.default_route_table) == 1
    error_message = "The module's route table must become the default by default."
  }
  assert {
    condition     = length(aws_ram_resource_share.this) == 0 && length(aws_ram_resource_association.this) == 0 && length(aws_ram_principal_association.this) == 0
    error_message = "The transit gateway must not be shared by default."
  }
  assert {
    condition     = aws_ec2_transit_gateway.this.tags == tomap({ Scope = "Test", Purpose = "Defaults", Environment = "test", Name = "shared_network-use1" })
    error_message = "Unexpected transit gateway tags."
  }
  assert {
    condition     = aws_ec2_transit_gateway_route_table.this.tags == tomap({ Scope = "Test", Purpose = "Defaults", Environment = "test", Name = "shared_network-use1-default" })
    error_message = "Unexpected route table tags."
  }
}

run "defaults_apply" {
  command = apply
  variables {
    enable_default_route_table_association = false
    enable_default_route_table_propagation = false
  }

  assert {
    condition     = length(terraform_data.default_route_table) == 0
    error_message = "With both settings off, the AWS CLI must not run."
  }
  assert {
    condition = alltrue([
      output.metadata.transit_gateway.id == "tgw-0123456789abcdef0",
      output.metadata.transit_gateway.description == "Shared network",
      output.metadata.transit_gateway.amazon_side_asn == 64512,
      output.metadata.transit_gateway_route_table.id == "tgw-rtb-0123456789abcdef0",
      output.metadata.transit_gateway_route_table.transit_gateway_id == "tgw-0123456789abcdef0",
    ])
    error_message = "metadata is wrong."
  }
  assert {
    condition = alltrue([
      output.metadata.ram_resource_share == null,
      output.metadata.ram_resource_association == null,
      output.metadata.ram_principal_association == null,
    ])
    error_message = "The RAM entries must be null without ram_share."
  }
  assert {
    condition     = output.metadata.aws.account.id == "111111111111" && output.metadata.aws.region.abbr == "use1"
    error_message = "metadata.aws is wrong."
  }
  assert {
    condition     = output.metadata.details.purpose.abbr == "defaults" && output.metadata.details.purpose.machine == "defaults"
    error_message = "metadata.details is wrong."
  }
}

# The transit gateway and route table exist in the state now, so their IDs are known.
run "default_route_table_commands" {
  command = plan

  assert {
    condition     = terraform_data.default_route_table[0].input.create == "aws ec2 modify-transit-gateway --region us-east-1 --transit-gateway-id tgw-0123456789abcdef0 --options DefaultRouteTableAssociation=enable,AssociationDefaultRouteTableId=tgw-rtb-0123456789abcdef0,DefaultRouteTablePropagation=enable,PropagationDefaultRouteTableId=tgw-rtb-0123456789abcdef0"
    error_message = "Unexpected create command: ${terraform_data.default_route_table[0].input.create}"
  }
  assert {
    condition     = terraform_data.default_route_table[0].input.destroy == "aws ec2 modify-transit-gateway --region us-east-1 --transit-gateway-id tgw-0123456789abcdef0 --options DefaultRouteTableAssociation=disable,DefaultRouteTablePropagation=disable"
    error_message = "Unexpected destroy command: ${terraform_data.default_route_table[0].input.destroy}"
  }
}

run "association_only" {
  command = plan
  variables {
    enable_default_route_table_propagation = false
  }
  assert {
    condition     = endswith(terraform_data.default_route_table[0].input.create, "--options DefaultRouteTableAssociation=enable,AssociationDefaultRouteTableId=tgw-rtb-0123456789abcdef0")
    error_message = "Unexpected create command: ${terraform_data.default_route_table[0].input.create}"
  }
  assert {
    condition     = endswith(terraform_data.default_route_table[0].input.destroy, "--options DefaultRouteTableAssociation=disable")
    error_message = "Unexpected destroy command: ${terraform_data.default_route_table[0].input.destroy}"
  }
}

run "propagation_only" {
  command = plan
  variables {
    enable_default_route_table_association = false
  }
  assert {
    condition     = endswith(terraform_data.default_route_table[0].input.create, "--options DefaultRouteTablePropagation=enable,PropagationDefaultRouteTableId=tgw-rtb-0123456789abcdef0")
    error_message = "Unexpected create command: ${terraform_data.default_route_table[0].input.create}"
  }
  assert {
    condition     = endswith(terraform_data.default_route_table[0].input.destroy, "--options DefaultRouteTablePropagation=disable")
    error_message = "Unexpected destroy command: ${terraform_data.default_route_table[0].input.destroy}"
  }
}

# The command follows the transit gateway's Region. (The old module ignored changes to its
# triggers, so a replaced transit gateway never got its default route table back; that
# is checked in AWS, since mocks do not run the command.)
run "command_follows_region" {
  command = plan
  variables {
    region = "eu-west-1"
  }
  assert {
    condition     = strcontains(terraform_data.default_route_table[0].input.create, "--region eu-west-1")
    error_message = "The command must follow the transit gateway to its new Region."
  }
}

run "options" {
  command = plan
  variables {
    description                           = "Partner  VPN (east)!"
    amazon_side_asn                       = 4200000000
    enable_auto_accept_shared_attachments = true
    enable_dns_support                    = false
    enable_vpn_ecmp_support               = false
    details = {
      scope           = "Test"
      purpose         = "Options"
      environment     = "test"
      additional_tags = { CostCenter = "1234" }
    }
  }
  assert {
    condition = alltrue([
      aws_ec2_transit_gateway.this.amazon_side_asn == 4200000000,
      aws_ec2_transit_gateway.this.auto_accept_shared_attachments == "enable",
      aws_ec2_transit_gateway.this.dns_support == "disable",
      aws_ec2_transit_gateway.this.vpn_ecmp_support == "disable",
    ])
    error_message = "Options did not reach the transit gateway."
  }
  # Regression: the description used to get " (<Region>)" appended, and a trailing
  # punctuation mark left a trailing underscore in the Name tag.
  assert {
    condition     = aws_ec2_transit_gateway.this.description == "Partner  VPN (east)!" && aws_ec2_transit_gateway.this.tags["Name"] == "partner_vpn_east-use1"
    error_message = "Unexpected description or Name: ${aws_ec2_transit_gateway.this.tags["Name"]}"
  }
  assert {
    condition     = aws_ec2_transit_gateway.this.tags["CostCenter"] == "1234" && aws_ec2_transit_gateway_route_table.this.tags["CostCenter"] == "1234"
    error_message = "additional_tags must reach every resource."
  }
}

# Regression: an empty abbreviation override used to produce an empty abbreviation.
run "empty_abbr_override_is_ignored" {
  command = plan
  variables {
    details = { scope = "Test", scope_abbr = "", purpose = "Web Site", purpose_abbr = "web", environment = "test" }
  }
  assert {
    condition     = output.metadata.details.scope.abbr == "test" && output.metadata.details.purpose.abbr == "web"
    error_message = "An empty override must fall back to the generated abbreviation."
  }
}
