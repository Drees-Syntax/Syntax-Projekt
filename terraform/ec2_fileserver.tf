resource "aws_instance" "fileserver" {
  ami                    = data.aws_ami.windows.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.windows.id]
  key_name               = "your-keypair"

  tags = {
    Name = "${var.project_name}-fileserver"
  }
}
