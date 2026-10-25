resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key-${var.key_name_suffix}"
  public_key = var.ssh_public_key
}
