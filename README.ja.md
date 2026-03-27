# MT Push Hooks

[MT — Mosh Terminal](https://jaga-farm.com/mt/) のプッシュ通知を Claude Code で使うためのセットアップスクリプトです。

MT は Claude Code の**フック機構**を使い、タスク完了や許可リクエストをシステムレベルで検知。iPhone と Apple Watch にプッシュ通知を確実にお届けします。

## かんたんセットアップ

```sh
curl -sL https://raw.githubusercontent.com/Jaga-Studio/mt-push-hooks/main/setup-hooks.sh | sh -s YOUR-DEVICE-SECRET
```

`YOUR-DEVICE-SECRET` は MT → 設定 → プッシュ通知 で表示される値に置き換えてください。

**必要なもの:** Node.js（Claude Code がインストールされていれば自動的に入っています）

**ヒント:** MT アプリ内からそのままセットアップできます。設定画面で Device Secret をコピーし、SSH セッションに切り替えてコマンドをペーストするだけです。

## 何をするスクリプト？

`~/.claude/settings.json` に2つのフックを追加します：

| フック | イベント | タイミング |
|--------|---------|-----------|
| **Stop** | `agent-done` | Claude の応答完了時 |
| **Notification** | `agent-input` | Claude が許可を求めるとき |

- 既存の設定を安全にマージ（上書きしません）
- 変更前にバックアップを作成（`settings.json.bak`）
- MT Push が設定済みの場合はスキップ

## 手動セットアップ

スクリプトを使わない場合は、[`hooks-template.json`](hooks-template.json) をダウンロードして `~/.claude/settings.json` に手動でマージしてください。

ファイルの場所：
- macOS / Linux: `~/.claude/settings.json`
- Windows: `%APPDATA%\claude\settings.json`

## 詳しいセットアップ手順

プッシュ通知の有効化を含む完全な手順は [Getting Started ガイド](https://jaga-farm.com/mt/getting-started.html) をご覧ください。

## ライセンス

MIT
