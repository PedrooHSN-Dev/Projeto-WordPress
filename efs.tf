resource "aws_efs_file_system" "wordpress" {
  creation_token = "${var.project_name}-efs"

  tags = {
    Name = "${var.project_name}-efs"
  }
}

resource "aws_efs_mount_target" "wordpress" {
  count           = 2
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}