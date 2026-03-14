# Docs & Sheets

## Google Docs

### 閲覧

```bash
gog docs cat <docId> -a <account>           # プレーンテキスト出力
gog docs info <docId> -a <account> -j       # メタデータ
gog docs list-tabs <docId> -a <account>     # タブ一覧
```

### 作成

```bash
gog docs create "<title>" -a <account>
gog docs copy <docId> "<new title>" -a <account>
```

### 編集

```bash
gog docs write <docId> -a <account> "<content>"       # 上書き
gog docs insert <docId> -a <account> "<content>"       # 挿入
gog docs find-replace <docId> "<find>" "<replace>" -a <account>
gog docs delete <docId> -a <account> --start <N> --end <N>
```

### エクスポート

```bash
gog docs export <docId> -a <account>                    # デフォルト形式
gog docs export <docId> -a <account> --format pdf|docx|txt
```

## Google Sheets

### 値の読み取り

```bash
gog sheets get <spreadsheetId> "<range>" -a <account> -j
# range例: "Sheet1!A1:D10", "Sheet1!A:A"
```

### 値の書き込み

```bash
gog sheets update <spreadsheetId> "<range>" -a <account> '<value1>' '<value2>'
gog sheets append <spreadsheetId> "<range>" -a <account> '<value1>' '<value2>'
```

### セルのクリア

```bash
gog sheets clear <spreadsheetId> "<range>" -a <account>
```

### セルの書式設定

```bash
gog sheets format <spreadsheetId> "<range>" -a <account> --bold --bg-color red
```

### メタデータ

```bash
gog sheets metadata <spreadsheetId> -a <account> -j
```

### 作成・コピー

```bash
gog sheets create "<title>" -a <account>
gog sheets copy <spreadsheetId> "<new title>" -a <account>
```

### エクスポート

```bash
gog sheets export <spreadsheetId> -a <account> --format pdf|xlsx|csv
```
