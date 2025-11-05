# Auto-generated SSH config by Terraform
# Add this to your ~/.ssh/config file

# Voting App Infrastructure
Host frontend-instance
  HostName ${frontend_public_ip}
  User ubuntu
  IdentityFile ${ssh_key_path}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host backend-instance
  HostName ${backend_private_ip}
  User ubuntu
  IdentityFile ${ssh_key_path}
  ProxyJump frontend-instance
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host db-instance
  HostName ${db_private_ip}
  User ubuntu
  IdentityFile ${ssh_key_path}
  ProxyJump frontend-instance
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
