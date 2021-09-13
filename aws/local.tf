
locals {
       public_subnet_ids = tolist((data.aws_subnet_ids.public[*].ids)[0])
       public_subnet_ids_str = join(" ", local.public_subnet_ids)
       public_subnet_cidrs = [for s in data.aws_subnet.public : s.cidr_block]
       public_subnet_names = [for s in data.aws_subnet.public : s.tags["Name"]]

       private_subnet_ids = tolist((data.aws_subnet_ids.private[*].ids)[0])
       private_subnet_ids_str = join(" ", local.private_subnet_ids)
       private_subnet_cidrs = [for s in data.aws_subnet.private : s.cidr_block]
       private_subnet_names = [for s in data.aws_subnet.private : s.tags["Name"]]

       ci_subnet_cidrs = tolist([data.aws_ssm_parameter.ci_1a_cidr.value, data.aws_ssm_parameter.ci_1b_cidr.value, data.aws_ssm_parameter.ci_1c_cidr.value])

       vpc_id = data.aws_vpc.unmanaged[0].id

       rolearn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.username}"
}


data aws_caller_identity current { }


