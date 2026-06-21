output "region" {
  value = var.region
}

output "volume_id" {
  description = "保護対象EBSボリュームID"
  value       = aws_ebs_volume.web_app.id
}

output "vault_name" {
  value = aws_backup_vault.main.name
}

output "plan_id" {
  value = aws_backup_plan.main.id
}

output "backup_role_arn" {
  description = "正常系の実行ロール"
  value       = aws_iam_role.backup.arn
}

output "broken_role_arn" {
  description = "失敗注入用（権限なし）ロール"
  value       = aws_iam_role.backup_broken.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.backup.arn
}

output "event_rule_name" {
  value = aws_cloudwatch_event_rule.backup_failed.name
}

output "alarm_names" {
  value = [
    aws_cloudwatch_metric_alarm.backup_jobs_failed.alarm_name,
    aws_cloudwatch_metric_alarm.restore_jobs_failed.alarm_name,
  ]
}
