# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.0] - 2026-10-05

Initial release.

### Added

- A transit gateway with a route table, tagged from `details`, with the Amazon side Autonomous System Number, DNS support, VPN equal-cost multi-path routing and automatic acceptance of shared attachments as inputs.
- The module's route table as the default association and propagation table for new attachments, each setting on by default and changeable in place. It is set with the AWS CLI, which must be installed where Terraform runs.
- Sharing through AWS Resource Access Manager with the accounts, organizational units or organization you list, limited to your own AWS organization unless you allow more.
- Validation of the inputs at plan time, including the values AWS rejects at apply.
- `region`, to create the transit gateway in another Region without configuring another provider.
- A `metadata` output with everything the module created, including the transit gateway's ID for attachments.
- Offline tests, and examples for a basic transit gateway, a transit gateway shared with one account, and a complete configuration.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-transit_gateway/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-transit_gateway/releases/tag/v1.0.0
