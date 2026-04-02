---
name: commit-message
description: Conventional Commits形式のコミットメッセージを生成する - コミット作成時やコミットメッセージの作成を依頼されたときに使う
---

# コミットメッセージ スキル

Conventional Commits 仕様に従ったコミットメッセージを生成します。

## 形式

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

## Type 一覧

| Type | 使う場面 |
|------|---------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみの変更 |
| `style` | フォーマット変更（コード自体の変更なし） |
| `refactor` | バグ修正でも機能追加でもないコード変更 |
| `perf` | パフォーマンス改善 |
| `test` | テストの追加・更新 |
| `chore` | メンテナンスタスク |

## ルール

1. 件名は最大72文字
2. 命令形を使う（「added」ではなく「add」）
3. 件名の末尾にピリオドを付けない
4. 件名と本文の間は空行で区切る
5. 本文には「何を」「なぜ」を書く（「どうやって」は不要）
6. 指示がない限りは例に記載しているシンプルにフォーマットを優先する

## 例

シンプル：
```
fix(auth): prevent redirect loop on expired sessions
```

本文付き：
```
feat(api): add rate limiting to public endpoints

- Limits requests to 100/minute per IP
- Returns 429 status with retry-after header
- Configurable via RATE_LIMIT_MAX env variable

Closes #234
```
