# Shared transit gateway

A transit gateway shared with one other account in your AWS organization through AWS Resource Access Manager (RAM). That account can attach its own VPCs to it; each attachment waits until you accept it in this account. The two default route table settings are off, so an accepted attachment is not associated with any route table and reaches nothing until you route it. The outputs are the IDs of the transit gateway and the resource share.

With both default route table settings off, the module runs no AWS CLI command.

Sharing with an account in your organization needs sharing with AWS Organizations turned on in the organization's management account; see [Sharing the transit gateway with other accounts](https://github.com/AutomateTheCloud/terraform-aws-transit_gateway#sharing-the-transit-gateway-with-other-accounts). An account outside your organization is refused.

## Run it

```shell
terraform init
terraform apply -var 'network_account_id=111111111111'
```

Remove it with `terraform destroy` and the same `-var` option. Replace the account ID with your own; the one above is a placeholder. The other account cannot keep using the transit gateway after it is destroyed, and the destroy fails while that account still has attachments.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_network_account_id"></a> [network_account_id](#input_network_account_id)

Description: ID of the AWS account in your organization to share the transit gateway with, such as 111111111111

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_resource_share_arn"></a> [resource_share_arn](#output_resource_share_arn)

Description: ARN of the resource share

#### <a name="output_transit_gateway_id"></a> [transit_gateway_id](#output_transit_gateway_id)

Description: ID of the transit gateway, for the other account's attachments
<!-- END_TF_DOCS -->
