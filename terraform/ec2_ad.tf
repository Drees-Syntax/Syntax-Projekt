resource "aws_instance" "ad" {
  ami                    = data.aws_ami.windows.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.windows.id]
  key_name               = aws_key_pair.deployer.key_name

  user_data = <<-EOF
  <powershell>
  $ErrorActionPreference = "Stop"

  $domainName = "${var.ad_domain}"
  $safeModePassword = "${var.safe_mode_password}"

  Rename-Computer -NewName "AD01" -Force

  Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools -ErrorAction Stop

  $securePassword = ConvertTo-SecureString $safeModePassword -AsPlainText -Force

  Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName "PROJEKTDREES" `
    -SafeModeAdministratorPassword $securePassword `
    -InstallDns:$true `
    -NoRebootOnCompletion:$false `
    -Force
  </powershell>
  EOF

  tags = {
    Name = "${var.project_name}-ad"
  }
}
