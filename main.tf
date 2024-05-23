// Module: aws/bastion-host
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

resource "aws_iam_policy" "bastion-host-iam-policy" {
  name        = "bastion-host-iam-policy"
  description = "Provides permissions to get an access to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::talkscriber-infra",
          "arn:aws:s3:::talkscriber-infra/*" ]
      },
    ]
  })
}

resource "aws_iam_role" "bastion-host-iam-role" {
  name = "bastion-host-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "bastion-host-iam-attachment" {
  name       = "bastion-host-iam-attachment"
  roles      = [aws_iam_role.bastion-host-iam-role.name]
  policy_arn = aws_iam_policy.bastion-host-iam-policy.arn
}

resource "aws_iam_instance_profile" "bastion-host-profile" {
  name = "bastion-host-profile"
  role = aws_iam_role.bastion-host-iam-role.name
}

data "aws_ami" "bastion-host-ami" {
  name_regex = var.ami_name
  owners = ["self"]
}

data "cloudinit_config" "bastion-host-cloudinit" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/bastion-host-cloudinit.yaml.tpl", {})
  }
}

resource "aws_instance" "bastion-host" {
  count = length(var.subnet_ids)

  ami = data.aws_ami.bastion-host-ami.id
  instance_type = var.instance_type

  iam_instance_profile = aws_iam_instance_profile.bastion-host-profile.name

  subnet_id = var.subnet_ids[count.index]

  vpc_security_group_ids = [aws_security_group.bastion-host-sg.id]

  user_data_base64 = "${data.cloudinit_config.bastion-host-cloudinit.rendered}"

  tags = {
    Name = format("%s%02g", var.name_prefix, count.index)
    Role = "bastion"
  }
}

resource "aws_eip" "bastion-host-eip" {
  count = length(var.subnet_ids)

  vpc = true

  instance = aws_instance.bastion-host[count.index].id
}

resource "aws_route53_record" "bastion-host-resource-record" {
  count = length(var.subnet_ids)

  zone_id = var.dns_zone_id

  name = format("%s%02g", var.name_prefix, count.index)
  type = "A"
  ttl = 60
  records = [aws_eip.bastion-host-eip[count.index].public_ip]
}
