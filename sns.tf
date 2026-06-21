resource "aws_sns_topic" "backup" {
  name = "${local.name}-BackupNotificationTopic"
  tags = local.tags
}

# 想定B: 自前トピックは「リソースポリシーで publish を明示許可」しないと、
# put-backup-vault-notifications は成功するのに通知が来ない（サイレント失敗）。
# AWS Backup(vault通知) と EventBridge(失敗ルールのターゲット) の両方を許可する。
data "aws_iam_policy_document" "sns_backup" {
  statement {
    sid       = "AllowBackupPublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.backup.arn]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }

  statement {
    sid       = "AllowEventBridgePublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.backup.arn]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }

  # CloudWatch アラームの alarm_actions/ok_actions も SNS:Publish する。
  # これを入れ忘れると、アラームは ALARM に遷移するのに通知だけ権限不足で死ぬ
  # （アラーム履歴に "CloudWatch Alarms is not authorized to perform: SNS:Publish" が残る）。
  # 本番では condition で aws:SourceArn を当該アラームARNに絞るとより安全。
  statement {
    sid       = "AllowCloudWatchAlarmPublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.backup.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "backup" {
  arn    = aws_sns_topic.backup.arn
  policy = data.aws_iam_policy_document.sns_backup.json
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.backup.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ---- vault通知（レガシーSNS・CLI/SDKのみ設定可、コンソール不可） ----
# 山場(想定A): backup_vault_events に BACKUP_JOB_FAILED は指定できない（イベント自体が存在しない）。
#   BACKUP ジョブは STARTED / COMPLETED のみで、COMPLETED は成功・失敗・中断を区別しない。
#   COPY / RESTORE には _SUCCESSFUL / _FAILED があるのに BACKUP だけ非対称。
#   → 失敗だけの検知は EventBridge(eventbridge.tf) に載せ替える。
resource "aws_backup_vault_notifications" "main" {
  backup_vault_name = aws_backup_vault.main.name
  sns_topic_arn     = aws_sns_topic.backup.arn
  backup_vault_events = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "RESTORE_JOB_STARTED",
    "RESTORE_JOB_COMPLETED",
  ]

  depends_on = [aws_sns_topic_policy.backup]
}
