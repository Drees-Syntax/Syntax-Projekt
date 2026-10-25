resource "aws_instance" "fileserver" {
  ami                         = data.aws_ami.windows.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.windows.id]
  key_name                    = var.existing_key_name

  user_data = <<-EOF
  <powershell>
  $ErrorActionPreference = "Stop"

  $domainName = "${var.ad_domain}"
  $domainUser = "Administrator"
  $domainPassword = "${var.domain_admin_password}"

  while (-not (Test-Connection -ComputerName "AD01.$domainName" -Count 1 -Quiet)) {
      Start-Sleep -Seconds 30
  }

  Install-WindowsFeature FS-FileServer,Remote-Desktop-Services -IncludeManagementTools -ErrorAction Stop
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
  Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

  $securePassword = ConvertTo-SecureString $domainPassword -AsPlainText -Force
  $credential = New-Object System.Management.Automation.PSCredential ("$domainName\$domainUser", $securePassword)

  Add-Computer -DomainName $domainName -Credential $credential -Restart -Force
  </powershell>
  EOF

  tags = {
    Name = "${var.project_name}-fileserver"
  }
}
