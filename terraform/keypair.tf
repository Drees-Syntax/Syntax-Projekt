# Bestehenden AWS Key verwenden (nicht von Terraform erstellen)
variable "existing_key_name" {
  description = "Name eines bereits existierenden AWS EC2 Key Pairs"
  type        = string
  default     = "projektdrees-key-40159589066"
}

# resource "aws_key_pair" "deployer" {
#   key_name   = "${var.project_name}-key-${var.key_name_suffix}"
#   public_key = var.ssh_public_key
# }
