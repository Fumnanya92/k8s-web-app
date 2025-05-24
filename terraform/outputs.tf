# output "public_subnet_ids" {
#   value = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
# }


# output "vpc_id" {
#   value = module.vpc.vpc_id
# }

# output "instance_public_ip" {
#   value = module.ec2.instance_public_ip
# }

# output "aws_eip_id" {
#   value = module.ec2.aws_eip_id
# }


# locals {
#   public_ip = aws_eip.app.public_ip
# }

# output "gandalf_url" {
#   description = "Gandalf Web endpoint"
#   value       = "http://${local.public_ip}/gandalf"
# }

# output "colombo_url" {
#   description = "Colombo time endpoint"
#   value       = "http://${local.public_ip}/colombo"
# }

# output "metrics_url" {
#   description = "Prometheus metrics endpoint"
#   value       = "http://${local.public_ip}/metrics"
# }

# output "prometheus_url" {
#   description = "Prometheus UI"
#   value       = "http://${local.public_ip}:9090"
# }

# output "grafana_url" {
#   description = "Grafana UI"
#   value       = "http://${local.public_ip}:3000"
# }

// outputs.tf

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [ module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id ]
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "instance_public_ip" {
  description = "AWS-assigned public IP of the EC2 instance"
  value       = module.ec2.instance_public_ip
}

output "aws_eip_id" {
  description = "Allocation ID of the Elastic IP"
  value       = module.ec2.aws_eip_id
}

locals {
  public_ip = module.ec2.eip_public_ip
}

# output "gandalf_url" {
#   description = "Gandalf Web endpoint"
#   value       = "http://${local.public_ip}/gandalf"
# }

# output "colombo_url" {
#   description = "Colombo time endpoint"
#   value       = "http://${local.public_ip}/colombo"
# }

# output "metrics_url" {
#   description = "Prometheus metrics endpoint"
#   value       = "http://${local.public_ip}/metrics"
# }

# output "prometheus_url" {
#   description = "Prometheus UI"
#   value       = "http://${local.public_ip}:9090"
# }

output "grafana_url" {
  description = "Grafana UI"
  value       = "http://${local.public_ip}:3000"
}
