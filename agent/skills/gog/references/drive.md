# Drive

## ファイル一覧

```bash
gog drive ls -a <account> -j                    # ルートフォルダ
gog drive ls -a <account> --parent <folderId> -j  # 特定フォルダ
```

## ファイル検索

```bash
gog drive search "<query>" -a <account> -j
```

Drive検索構文: `name contains 'keyword'`, `mimeType = 'application/pdf'`, `modifiedTime > '2026-01-01'` など。

## ファイルメタデータ

```bash
gog drive get <fileId> -a <account> -j
```

## ダウンロード

```bash
gog drive download <fileId> -a <account>
gog drive download <fileId> -a <account> --output /path/to/file
```

Google Docs形式はエクスポート形式を指定可能。

## アップロード

```bash
gog drive upload /path/to/file -a <account>
gog drive upload /path/to/file -a <account> --parent <folderId>
```

## フォルダ作成

```bash
gog drive mkdir "<name>" -a <account>
gog drive mkdir "<name>" -a <account> --parent <folderId>
```

## ファイル操作

```bash
gog drive copy <fileId> "<new name>" -a <account>
gog drive move <fileId> -a <account> --parent <newFolderId>
gog drive rename <fileId> "<new name>" -a <account>
gog drive delete <fileId> -a <account>  # ゴミ箱へ移動
```

## 共有

```bash
gog drive share <fileId> -a <account> --email "<email>" --role reader|writer|commenter
gog drive permissions <fileId> -a <account> -j
gog drive unshare <fileId> <permissionId> -a <account>
```

## Web URL取得

```bash
gog drive url <fileId> -a <account>
```
