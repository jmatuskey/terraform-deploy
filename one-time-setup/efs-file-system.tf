resource "aws_efs_file_system" "home_dirs" {
  tags = {
    Name = "${var.cluster_name}-home-dirs"
    "stsci-backup" = "dmd-2w-sat"
  }
  encrypted = true
}
