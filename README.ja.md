# MT Push Hooks

[MT — Mosh Terminal](https://jaga-farm.com/mt/) のプッシュ通知を Claude Code で使うためのセットアップスクリプトです。

MT は Claude Code の**フック機構**を使い、タスク完了や許可リクエストを検知。**Claude が実際にやっていた内容**を iPhone と Apple Watch にプッシュ通知でお届けします。

## かんたんセットアップ

```sh
curl -sL https://raw.githubusercontent.com/Jaga-Studio/mt-push-hooks/main/setup-hooks.sh | sh -s YOUR-DEVICE-SECRET
```

`YOUR-DEVICE-SECRET` は MT → 設定 → プッシュ通知 で表示される値に置き換えてください。

**必要なもの:** Node.js（Claude Code がインストールされていれば自動的に入っています）

**ヒント:** MT アプリ内からそのままセットアップできます。設定画面で Device Secret をコピーし、SSH セッションに切り替えてコマンドをペーストするだけです。

## 何をするスクリプト？

`~/.claude/hooks/mt-push-notify.sh` をインストールし、`~/.claude/settings.json` に 2 つのフックを追加します：

| フック | イベント | 通知内容 |
|--------|---------|---------|
| **Stop** | `agent-done` | Claude の最後の応答（先頭200文字） |
| **Notification** | `agent-input` | 実際のパーミッション要求内容 |

- 既存の設定を安全にマージ（上書きしません）
- 変更前にバックアップを作成（`settings.json.bak`）
- 旧バージョン（インライン curl）からの自動アップグレード対応
- 再実行するとスクリプトが最新版に更新されます（フックの重複なし）

## アップグレード

以前のバージョンをお使いの場合、同じセットアップコマンドを再実行するだけで自動的にアップグレードされます。

## 手動セットアップ

1. [`mt-push-notify.sh`](mt-push-notify.sh) を `~/.claude/hooks/` にダウンロード
2. `__MT_DEVICE_SECRET__` をデバイスシークレットに置換
3. 実行権限を付与: `chmod +x ~/.claude/hooks/mt-push-notify.sh`
4. [`hooks-template.json`](hooks-template.json) を `~/.claude/settings.json` にマージ

## 詳しいセットアップ手順

プッシュ通知の有効化を含む完全な手順は [Getting Started ガイド](https://jaga-farm.com/mt/getting-started.html) をご覧ください。

## ライセンス

MIT
