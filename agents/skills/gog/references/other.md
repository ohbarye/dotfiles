# Chat / Tasks / Contacts

## Google Chat

### スペース一覧

```bash
gog chat spaces list -a <account> -j
```

### メッセージ

```bash
gog chat messages list <spaceId> -a <account> -j
gog chat messages send <spaceId> -a <account> --text "<message>"
```

### スレッド

```bash
gog chat threads list <spaceId> -a <account> -j
```

### DM

```bash
gog chat dm list -a <account> -j
gog chat dm send <userId> -a <account> --text "<message>"
```

## Google Tasks

### タスクリスト一覧

```bash
gog tasks lists list -a <account> -j
```

### タスク一覧

```bash
gog tasks list <tasklistId> -a <account> -j
```

### タスク追加

```bash
gog tasks add <tasklistId> -a <account> --title "<title>" --notes "<notes>" --due "2026-03-20"
```

### タスク更新

```bash
gog tasks update <tasklistId> <taskId> -a <account> --title "<new title>"
```

### タスク完了 / 未完了

```bash
gog tasks done <tasklistId> <taskId> -a <account>
gog tasks undo <tasklistId> <taskId> -a <account>
```

### タスク削除

```bash
gog tasks delete <tasklistId> <taskId> -a <account>
```

### 完了タスクのクリア

```bash
gog tasks clear <tasklistId> -a <account>
```

## Google Contacts

### 連絡先検索

```bash
gog contacts search "<query>" -a <account> -j
```

### 連絡先一覧

```bash
gog contacts list -a <account> -j
```

### 連絡先取得

```bash
gog contacts get <resourceName> -a <account> -j
```

### 連絡先作成

```bash
gog contacts create -a <account> --given-name "<name>" --email "<email>" --phone "<phone>"
```

### 連絡先更新

```bash
gog contacts update <resourceName> -a <account> --given-name "<name>"
```

### 連絡先削除

```bash
gog contacts delete <resourceName> -a <account>
```

### ディレクトリ（Workspace）

```bash
gog contacts directory list -a <account> -j
gog contacts directory search "<query>" -a <account> -j
```
