// Module: terraform-aws-bastion-host
// Description: main code
//


resource "aws_security_group" "bastion-host-sg" {
  name = "${var.name_prefix}-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each  = var.security_group_ingress
    content {
      self = lookup(ingress.value, "self", null)
      description = lookup(ingress.value, "description", null)
      protocol = lookup(ingress.value, "protocol", "-1")
      from_port = lookup(ingress.value, "from_port", -1)
      to_port = lookup(ingress.value, "to_port", -1)
      cidr_blocks = lookup(ingress.value, "cidr_blocks", [])
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", [])
      prefix_list_ids =  lookup(ingress.value, "ip_list_ids", [])
      security_groups = lookup(ingress.value, "security_groups", [])
    }
  }

  dynamic "egress" {
    for_each  = var.security_group_egress
    content {
      self = lookup(egress.value, "self", null)
      description = lookup(egress.value, "description", null)
      protocol = lookup(egress.value, "protocol", "-1")
      from_port = lookup(egress.value, "from_port", -1)
      to_port = lookup(egress.value, "to_port", -1)
      cidr_blocks = lookup(egress.value, "cidr_blocks")
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", [])
      prefix_list_ids =  lookup(egress.value, "ip_list_ids", [])
      security_groups = lookup(egress.value, "security_groups", [])
    }
  }
}

data "aws_ami" "bastion-host-ami" {
  name_regex = var.ami_name
  owners = ["self"]
}

resource "aws_instance" "bastion-host" {
  count = length(var.subnet_ids)

  ami = data.aws_ami.bastion-host-ami.id
  instance_type = var.instance_type

  iam_instance_profile = var.instance_iam_profile_name

  subnet_id = var.subnet_ids[count.index]

  vpc_security_group_ids = [aws_security_group.bastion-host-sg.id]

  user_data_base64 = var.user_data_base64

  tags = {
    Name = format("%s%02g", var.name_prefix, count.index)
    Role = "bastion-host"
  }
}

resource "aws_eip" "bastion-host-eip" {
  count = length(var.subnet_ids)

  domain = "vpc"

  instance = aws_instance.bastion-host[count.index].id
}

resource "aws_route53_record" "bastion-host-pub-resource-record" {
  count = var.public_dns_zone_id == null ? 0 : length(var.subnet_ids)

  zone_id = var.public_dns_zone_id

  name = format("%s%02g", var.name_prefix, count.index)
  type = "A"
  ttl = 60
  records = [aws_eip.bastion-host-eip[count.index].public_ip]
}

resource "aws_route53_record" "bastion-host-private-resource-record" {
  count = var.private_dns_zone_id == null ? 0 : length(var.subnet_ids)

  zone_id = var.private_dns_zone_id

  name = format("%s%02g", var.name_prefix, count.index)
  type = "A"
  ttl = 60
  records = [aws_instance.bastion-host[count.index].private_ip]
}
