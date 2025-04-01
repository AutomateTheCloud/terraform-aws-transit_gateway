# AWS - Transit Gateway - Terraform Module
Terraform module to create Transit Gateways (AutomateTheCloud model)

***

## Usage
```hcl
module "transit_gateway" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope        = "Infrastructure"
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
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `amazon_side_asn` | Private Autonomous System Number (ASN) for the Amazon side of a BGP session | `number` | `64512` |
| `description` | Description | `string` | |
| `enable_auto_accept_shared_attachments` | Whether resource attachment requests are automatically accepted | `bool` | `false` |
| `enable_default_route_table_association` | Whether resource attachments are automatically associated with the default association route table | `bool` | `true` |
| `enable_default_route_table_propagation` | Whether resource attachments automatically propagate routes to the default propagation route table | `bool` | `true` |
| `enable_dns_support` | Whether DNS support is enabled | `bool` | `true` |
| `enable_share_with_accounts` | Share the Transit Gateway with External AWS Accounts | `bool` | `false` |
| `enable_share_with_organization` | Share the Transit Gateway with the AWS Organization | `bool` | `false` |
| `enable_vpn_ecmp_support` | Whether VPN Equal Cost Multipath Protocol support is enabled | `bool` | `true` |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object server? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `aws.account.id` | AWS Account ID |
| `aws.region.name` | AWS Region name, example: `us-east-1` |
| `aws.region.abbr` | AWS Region four letter abbreviation, example: `use1` |
| `aws.region.description` | AWS Region description, example: `US East (N. Virginia)` |
| `transit_gateway` | Transit Gateway Details |
| `transit_gateway_route_table` | Transit Gateway Route Table Details |
| `ram_resource_share` | RAM Resource Share Details |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
