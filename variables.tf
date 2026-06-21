variable "region" {
  description = "リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "name_prefix" {
  description = "リソース名プレフィックス"
  type        = string
  default     = "soa03-09"
}

variable "notification_email" {
  description = "SNS通知先メール（空ならサブスクリプションを作成しない）"
  type        = string
  default     = ""
}

variable "volume_size" {
  description = "保護対象EBSボリュームのサイズ(GiB)。検証用なので最小。"
  type        = number
  default     = 1
}

variable "backup_tag_key" {
  description = "タグベース割り当てのキー"
  type        = string
  default     = "Backup"
}

variable "backup_tag_value" {
  description = "タグベース割り当ての値"
  type        = string
  default     = "daily"
}
