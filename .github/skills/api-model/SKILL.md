---
name: api-model
description: APIのJSONレスポンスから Swift の Codable モデルを生成する - モデル作成、JSON変換、APIレスポンスの型定義に使う
---

# API モデル生成

JSON レスポンスから Swift のモデル struct を生成するときは以下のルールに従ってください。

## ルール

1. `Codable` と `Sendable` に準拠する
2. プロパティは `let` で定義する（イミュータブル）
3. JSON の snake_case は Swift の camelCase に変換し、`CodingKeys` を生成する
4. すべてのキーが camelCase の場合は `CodingKeys` を省略する
5. null になり得るフィールドは `Optional` にする
6. 日付文字列（ISO 8601）は `Date` 型にする
7. ネストしたオブジェクトは別の struct として定義する
8. 配列は `[ElementType]` で表現する
9. ドキュメントコメント（`///`）をモデルに付与する

## 変換例

### 入力 JSON

```json
{
  "id": 1,
  "user_name": "taro",
  "email": "taro@example.com",
  "profile": {
    "bio": "Hello",
    "avatar_url": "https://example.com/avatar.png"
  },
  "created_at": "2026-03-23T10:00:00Z",
  "deleted_at": null
}
```

### 出力 Swift モデル

```swift
/// ユーザー情報
struct User: Codable, Sendable {
    /// ユーザーID
    let id: Int
    /// ユーザー名
    let userName: String
    /// メールアドレス
    let email: String
    /// プロフィール情報
    let profile: Profile
    /// 作成日時
    let createdAt: Date
    /// 削除日時（未削除の場合は nil）
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userName = "user_name"
        case email
        case profile
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
}

/// プロフィール情報
struct Profile: Codable, Sendable {
    /// 自己紹介文
    let bio: String
    /// アバター画像URL
    let avatarUrl: String

    enum CodingKeys: String, CodingKey {
        case bio
        case avatarUrl = "avatar_url"
    }
}
```
