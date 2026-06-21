# 保護対象のEBSボリューム（ラボの webAppVolume 相当）。
# Backup=daily タグでバックアッププランにタグベース割り当てされる。
# タグが無いリソースは「静かに未保護」になる（カバレッジギャップ）。
resource "aws_ebs_volume" "web_app" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(local.tags, {
    Name                 = "${local.name}-webAppVolume"
    (var.backup_tag_key) = var.backup_tag_value
  })
}
