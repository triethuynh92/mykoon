output "aws_lb" {
  value = aws_lb.albUSWTA.dns_name
}
output "aws_ip" {
  value = aws_instance.ec2USWTABastion.public_ip
}
output "aws_app1_ip" {
  value = aws_instance.ec2USWTAApplication1.private_ip
}
output "aws_app2_ip" {
  value = aws_instance.ec2USWTAApplication2.private_ip
}