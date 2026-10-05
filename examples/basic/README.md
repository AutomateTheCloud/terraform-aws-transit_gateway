# Basic transit gateway

A transit gateway created with only the module's required inputs, with one existing VPC attached to it. The VPC is associated with the transit gateway's route table and its routes are propagated there, so every VPC attached later can reach it. The outputs are the IDs of the transit gateway and its route table.

The module runs the AWS CLI to make its route table the default, so the AWS CLI must be installed where Terraform runs, with credentials for the same account; see [The default route table settings need the AWS CLI](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#the-default-route-table-settings-need-the-aws-cli). The VPC's own route tables still need routes to the transit gateway before traffic flows.

## Run it

```shell
terraform init
terraform apply \
  -var 'vpc_id=vpc-0123456789abcdef0' \
  -var 'subnet_ids=["subnet-0123456789abcdef0"]'
```

Remove it with `terraform destroy` and the same `-var` options. Replace the values with your own; the ones above are placeholders. The attachment is billed for every hour it exists.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: IDs of subnets in that VPC for the attachment, one per Availability Zone, such as ["subnet-0123456789abcdef0"]

Type: `list(string)`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of a VPC in us-east-1 to attach, such as vpc-0123456789abcdef0

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_route_table_id"></a> [route_table_id](#output_route_table_id)

Description: ID of the transit gateway's route table, for routes and associations

#### <a name="output_transit_gateway_id"></a> [transit_gateway_id](#output_transit_gateway_id)

Description: ID of the transit gateway, for attaching more VPCs
<!-- END_TF_DOCS -->
