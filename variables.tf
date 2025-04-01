variable "amazon_side_asn" {
  description = "Private Autonomous System Number (ASN) for the Amazon side of a BGP session"
  type        = number
  default     = 64512
}

variable "description" {
  description = "Description"
  type        = string
}

variable "enable_auto_accept_shared_attachments" {
  description = "Whether resource attachment requests are automatically accepted (true/false)"
  type        = bool
  default     = false
}

variable "enable_default_route_table_association" {
  description = "Whether resource attachments are automatically associated with the default association route table (true/false)"
  type        = bool
  default     = true
}

variable "enable_default_route_table_propagation" {
  description = "Whether resource attachments automatically propagate routes to the default propagation route table (true/false)"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether DNS support is enabled (true/false)"
  type        = bool
  default     = true
}

variable "enable_share_with_accounts" {
  description = "Share the Transit Gateway with External AWS Accounts (true/false)"
  type        = bool
  default     = false
}

variable "enable_share_with_organization" {
  description = "Share the Transit Gateway with the AWS Organization (true/false)"
  type        = bool
  default     = false
}

variable "enable_vpn_ecmp_support" {
  description = "Whether VPN Equal Cost Multipath Protocol support is enabled (true/false)"
  type        = bool
  default     = true
}
