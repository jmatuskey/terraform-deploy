resource "aws_kms_key" "sops_key" {
  description = "Encryption key for secrets in CodeCommit repo ${var.cluster_name}-secrets"
  tags        = {
    Terraform = "True",
    Project = var.cluster_name
  }
}

resource "local_file" "sops-config" {
  filename = ".sops.yaml"
  content = <<EOF
creation_rules:
  - path_regex: .*
    kms: "${aws_kms_key.sops_key.arn}"
EOF
}


