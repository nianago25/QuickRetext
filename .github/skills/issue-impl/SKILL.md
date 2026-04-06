---
name: issue-impl
description: GitHub issue番号を指定してブランチ作成・実装・レビュー・PR作成までの一連の開発フローを実行する
---

# Issue 実装スキル

GitHub issue を指定し、ブランチ作成から PR 作成までの一連の開発フローを実行します。

## 前提条件

- `main` ブランチが最新であること（自動で `git pull` する）
- `gh` CLI が認証済みであること

## 実行手順

ユーザーから issue 番号（例: `#3`）を受け取ったら、以下の手順を**順番に**実行する。

### Step 1: issue 内容の確認

```bash
gh issue view {番号}
```

- issue のタイトル・本文をユーザーに要約して共有する

### Step 2: ブランチ作成 & チェックアウト

```bash
git checkout main
git pull origin main
git checkout -b feature-issue-{番号}
```

- ブランチ名は `feature-issue-{番号}` で固定

### Step 3: プランの作成

- issue の内容とコードベースを調査し、実装プランを作成する
- プランをユーザーに提示して確認を求める
- ユーザーの承認を得てから次のステップへ進む

### Step 4: 実装

- プランに基づいてコード変更を行う
- 既存テストが壊れていないことを確認する
- 必要に応じて新規テストを追加する

### Step 5: レビュー

- コードレビューエージェント（`code-review`）を起動して変更を分析する
- 指摘事項があれば修正する

### Step 6: ユーザー確認

- 変更内容の差分サマリーをユーザーに提示する
- ユーザーに最終確認を求める
- **NG の場合**: フィードバックを受けて Step 3（プラン）からやり直す
- **OK の場合**: 次のステップへ進む

### Step 7: コミット & プッシュ

```bash
git add -A
git commit -m "<commit-message>"
git push origin feature-issue-{番号}
```

- コミットメッセージは `commit-message` スキルの規約に従う
- issue 番号を含める（例: `fix: ○○を修正する (#3)`）
- Co-authored-by トレーラーを付ける

### Step 8: PR 作成

```bash
gh pr create --base main --head feature-issue-{番号} \
  --title "<PRタイトル>" \
  --body "<PR本文>"
```

- PR タイトルはコミットメッセージと同様の形式にする
- PR 本文には変更概要・対応内容・テスト結果を含める
- PR 本文に `Closes #{番号}` を含め、マージ時に issue が自動クローズされるようにする

## 注意事項

- 各ステップで失敗した場合は、ユーザーに報告して指示を仰ぐ
- マージ・ブランチ削除はこのスキルのスコープ外（ユーザーが手動で行う）
- 実装中に issue の範囲を超える問題を発見した場合は、別 issue として報告を提案する
