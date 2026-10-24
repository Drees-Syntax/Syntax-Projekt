resource "aws_key_pair" "deployer" {
  key_name   = "projekt-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
