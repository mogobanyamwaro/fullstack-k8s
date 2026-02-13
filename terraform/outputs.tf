output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.app[*].id
}

output "instance_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_instance.app[*].public_ip
}

output "instance_private_ips" {
  description = "Private IPs of EC2 instances"
  value       = aws_instance.app[*].private_ip
}

output "ssh_command" {
  description = "Example SSH command (use ubuntu user for Ubuntu AMI)"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.app[0].public_ip}"
}
