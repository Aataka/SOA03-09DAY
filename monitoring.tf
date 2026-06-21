# 想定C: AWS/Backup の失敗メトリクスでアラーム。
# 検証ポイント: NumberOfBackupJobsFailed は「失敗が起きたときだけ」出る系か(=平常時は欠落)を実測し、
#   treat_missing_data の設計に反映する。欠落系なら notBreaching で平常OK、イベント時にALARM。
resource "aws_cloudwatch_metric_alarm" "backup_jobs_failed" {
  alarm_name          = "${local.name}-backup-jobs-failed"
  namespace           = "AWS/Backup"
  metric_name         = "NumberOfBackupJobsFailed"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    BackupVaultName = aws_backup_vault.main.name
  }

  alarm_actions = [aws_sns_topic.backup.arn]
  ok_actions    = [aws_sns_topic.backup.arn]
  tags          = local.tags
}

resource "aws_cloudwatch_metric_alarm" "restore_jobs_failed" {
  alarm_name          = "${local.name}-restore-jobs-failed"
  namespace           = "AWS/Backup"
  metric_name         = "NumberOfRestoreJobsFailed"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    BackupVaultName = aws_backup_vault.main.name
  }

  alarm_actions = [aws_sns_topic.backup.arn]
  tags          = local.tags
}
