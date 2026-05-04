output "instance_id" {
  value = aws_instance.sonarqube.id
}

output "public_ip" {
  value = aws_instance.sonarqube.public_ip
}

output "sonarqube_url" {
  value = "http://${aws_instance.sonarqube.public_ip}:9000"
}

output "security_group_id" {
  value = aws_security_group.sonarqube.id
}
