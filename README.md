# SOA03-09DAY — Automating with AWS Backup（失敗通知・検証）

AWS Backup で EBS ボリュームのバックアップを自動化し、**ジョブの失敗だけを確実に検知する**監視を Terraform で構築・実測する。AWS Skill Builder ラボ「Automating With AWS Backup」を題材に、ラボが省略している運用監視レイヤ（失敗通知・SNSポリシー・CloudWatch失敗メトリクス）を足した。

## 構成

```
EBS(Backup=daily) ──tag選択──▶ Backup Plan(日次) ──▶ Vault ──▶ Recovery Point
                                                         │
                          vault通知(成功/完了系) ────────┤
                                                         ▼
   EventBridge(state=FAILED) ──▶  SNS Topic  ──▶ Email / CloudWatch Alarm
                                  (topic policy: backup + events に publish許可)
```

## 検証する想定

- **A（山場）**: `BACKUP_JOB_FAILED` は vault通知に存在しない（BACKUPは STARTED/COMPLETED のみ・COMPLETEDは成否を区別しない）。失敗だけの通知は **EventBridge `Backup Job State Change` ＋ `state=[FAILED,ABORTED,EXPIRED]`** に載せ替える。
- **B**: 自前SNSトピックは **トピックポリシーで `backup.amazonaws.com`/`events.amazonaws.com` の publish を許可**しないと通知が来ない（`put-backup-vault-notifications` は成功するのにメールが届かないサイレント失敗）。
- **C**: `AWS/Backup` の `NumberOfBackupJobsFailed`/`NumberOfRestoreJobsFailed` でアラーム。平常時メトリクスが欠落する系かを実測し `treat_missing_data` を設計。

## 使い方

```bash
terraform init
terraform apply -var="notification_email=you@example.com"
# → 確認メールの Confirm subscription をクリック（直クリックで自動解除される場合は CLI confirm）

bash _verify.sh     # 正常＋失敗バックアップを起動し、イベント/メトリクス/アラームを観測
bash _destroy.sh    # 復旧ポイントを全削除してから destroy（ボールトは空でないと消せない）
```

## ハマりどころ

- **ボールトは復旧ポイントが残ると destroy 不可**（`force_destroy` 引数なし）→ `_destroy.sh` で `delete-recovery-point` してから destroy。
- **vault通知はコンソールに出ない**（CLI/SDK専用）。設定確認は `get-backup-vault-notifications`。
- 失敗注入は **権限を付けない IAM ロール**で `start-backup-job` → ジョブ FAILED。

## 公開方針

公開リポジトリは **Terraform/IaC ＋ README のみ**。記事(`docs/`)・学習足場(`study/`)・`_*` は `.gitignore` でローカル保持。
