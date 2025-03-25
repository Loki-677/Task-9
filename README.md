<<<<<<< HEAD

=======
# Task-9
>>>>>>> master
Overview
This tool automates the creation of user accounts and configuration of authentication methods (password or SSH key) across multiple remote servers.

Features
Create user accounts on multiple servers simultaneously

Configure either password-based or SSH key-based authentication

Works with existing EC2 instances (tested with Amazon Linux)

Idempotent operations (won't recreate existing users)

Prerequisites
Bash environment

SSH access to target servers as ec2-user with sudo privileges

Private key for admin access (/root/.ssh/ohio.pem by default)

Public key file if using key-based authentication