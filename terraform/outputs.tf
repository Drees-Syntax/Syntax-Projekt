output "ad_public_ip" {
  value = aws_instance.ad.public_ip
}

output "fileserver_public_ip" {
  value = aws_instance.fileserver.public_ip
}
