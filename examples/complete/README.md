# Complete

Every input of the module: a transit gateway in us-west-2 while the provider is in us-east-1, with its own Autonomous System Number (ASN) and abbreviations, shared with one organizational unit in your AWS organization under a chosen share name, with attachments from that organizational unit's accounts accepted automatically. An existing shared services VPC in us-west-2 is attached. Every VPC attached later is associated with the module's route table and its routes are propagated there, so all of them, and the shared services VPC, can reach each other. The output is the module's `metadata`.

The module runs the AWS CLI to make its route table the default, so the AWS CLI must be installed where Terraform runs, with credentials for the same account; see [The default route table settings need the AWS CLI](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#the-default-route-table-settings-need-the-aws-cli). Sharing with an organizational unit needs sharing with AWS Organizations turned on in the organization's management account; see [Sharing the transit gateway with other accounts](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#sharing-the-transit-gateway-with-other-accounts).

## Run it

```shell
terraform init
terraform apply \
  -var 'organizational_unit_arn=arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111' \
  -var 'shared_services_vpc_id=vpc-0123456789abcdef0' \
  -var 'shared_services_subnet_ids=["subnet-0123456789abcdef0"]'
```

Remove it with `terraform destroy` and the same `-var` options. Replace the values with your own; the ones above are placeholders. The destroy fails while accounts in the organizational unit still have attachments.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_organizational_unit_arn"></a> [organizational_unit_arn](#input_organizational_unit_arn)

Description: ARN of the organizational unit in your organization to share the transit gateway with, such as arn:aws:organizations::111111111111:ou/o-exampleorgid/ou-examplerootid111-exampleouid111

Type: `string`

#### <a name="input_shared_services_subnet_ids"></a> [shared_services_subnet_ids](#input_shared_services_subnet_ids)

Description: IDs of subnets in that VPC for the attachment, one per Availability Zone

Type: `list(string)`

#### <a name="input_shared_services_vpc_id"></a> [shared_services_vpc_id](#input_shared_services_vpc_id)

Description: ID of a VPC in us-west-2 to attach, such as vpc-0123456789abcdef0

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created
<!-- END_TF_DOCS -->
