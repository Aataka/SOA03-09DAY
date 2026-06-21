# ---- AWS Backup 実行ロール ----
data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "${local.name}-BackupRole"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# 失敗注入用の壊れたロール（バックアップ権限を一切付けない）。
# このロールで on-demand backup を起動するとジョブが FAILED になり、
# 想定A(EventBridge state=FAILED→SNS) と 想定C(NumberOfBackupJobsFailed) を実証する。
resource "aws_iam_role" "backup_broken" {
  name               = "${local.name}-BrokenBackupRole"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
  tags               = local.tags
}

# ---- バックアップボールト ----
# kms_key_arn 未指定で AWS マネージドキー(aws/backup)を使用。
# 注意: ボールトは復旧ポイントが残っていると destroy できない（force_destroy 引数は無い）。
#       destroy 前に delete-recovery-point で空にする（_destroy.sh 参照）。
resource "aws_backup_vault" "main" {
  name = "${local.name}-vault"
  tags = local.tags
}

# ---- バックアッププラン（日次・ラボ既定の UTC 5時ウィンドウ） ----
resource "aws_backup_plan" "main" {
  name = "${local.name}-plan"

  rule {
    rule_name         = "myDailyBackupRule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * * *)"
    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 7
    }

    recovery_point_tags = merge(local.tags, {
      Name = "${local.name}-recovery"
    })
  }

  tags = local.tags
}

# ---- リソース割り当て（タグベース） ----
resource "aws_backup_selection" "main" {
  name         = "myEBSVolumes"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_tag_key
    value = var.backup_tag_value
  }
}
