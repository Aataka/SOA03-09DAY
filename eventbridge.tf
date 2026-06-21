# 想定A の fix: BACKUP_JOB_FAILED は vault通知に無い → EventBridge の状態変化イベントで
# state が FAILED / ABORTED / EXPIRED のものだけを拾って SNS に流す。
# （成功の洪水に失敗を埋もれさせない＝運用で本当に欲しい通知）
resource "aws_cloudwatch_event_rule" "backup_failed" {
  name        = "${local.name}-backup-job-failed"
  description = "AWS Backup ジョブの失敗系状態のみを検知"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
    detail = {
      state = ["FAILED", "ABORTED", "EXPIRED"]
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "backup_failed_sns" {
  rule      = aws_cloudwatch_event_rule.backup_failed.name
  target_id = "sns"
  arn       = aws_sns_topic.backup.arn

  input_transformer {
    input_paths = {
      jobId = "$.detail.backupJobId"
      state = "$.detail.state"
      vault = "$.detail.backupVaultName"
      res   = "$.detail.resourceArn"
      msg   = "$.detail.statusMessage"
    }
    input_template = "\"[AWS Backup 失敗] job <jobId> state=<state> vault=<vault> resource=<res> msg=<msg>\""
  }
}
