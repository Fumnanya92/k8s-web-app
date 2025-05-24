output "aws_eip_id" {
  value = aws_eip.app.id
}


output "eip_public_ip" {
  description = "The Elastic IP address assigned to the Gandalf instance"
  value       = aws_eip.app.public_ip
}

output "instance_public_ip" {
  description = "AWS-assigned public IP of the EC2 instance"
  value       = aws_instance.gandalf.public_ip
}
