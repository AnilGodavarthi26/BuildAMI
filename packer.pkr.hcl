#Plugin installation
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    ansible = {
      source = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

#Variables
variable "region" {
  default = "eu-west-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "device_name" {
  default = "/dev/sda1"
}

variable "volume_size" {
  default = 40
}

variable "volume_type" {
  default = "gp2"
}

# Source AMI
data "amazon-ami" "sourceAMI" {
  filters = {
    virtualization-type = "hvm"
    name = "ubuntu/images/*ubuntu-noble-24.04-amd64-server*"
    root-device-type = "ebs"
  }
  owners      = ["099720109477"]
  most_recent = true
}

# Build the new AMI
source "amazon-ebs" "tagging" {
  region         = var.region
  source_ami     = data.amazon-ami.sourceAMI.id
  instance_type  = var.instance_type
  ssh_username   = "ubuntu"
  ssh_timeout       = "20m"
  ssh_agent_auth    = true
  ami_name       = "Tagging-AMI-{{timestamp}}"
  encrypt_boot   = true

  launch_block_device_mappings {
    device_name           = var.device_name
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = true
  }
}

# Build Section
build {
  name    = "nginx-build"
  sources = ["source.amazon-ebs.tagging"]

  provisioner "ansible" {
    playbook_file = "ansible/playbook.yml"
    extra_arguments = [
    "--scp-extra-args", "'-O'"
  ]
  }
}
