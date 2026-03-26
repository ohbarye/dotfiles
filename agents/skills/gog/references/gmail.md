# Gmail

## 検索（スレッド一覧）

```bash
gog gmail ls "<query>" -a <account> --max <N> -j
```

Gmail検索構文が使える: `in:inbox`, `is:unread`, `from:user@example.com`, `subject:keyword`, `after:2026/03/01`, `has:attachment` など。

主要フラグ:
| フラグ | 説明 |
|---|---|
| `--max <N>` | 最大件数（デフォルト10） |
| `--all` | 全ページ取得 |
| `--oldest` | 最初のメッセージ日時を表示 |

## スレッド閲覧

```bash
gog gmail read <threadId> -a <account> -p
```

`-p` でプレーンテキスト出力。`-j` でJSON（本文はbase64エンコード）。

JSON から本文を抽出する場合:

```bash
gog gmail read <threadId> -a <account> -j | python3 -c "
import json, sys, base64
data = json.load(sys.stdin)
def find_parts(payload, mime='text/plain'):
    results = []
    if payload.get('mimeType') == mime:
        d = payload.get('body', {}).get('data', '')
        if d: results.append(base64.urlsafe_b64decode(d).decode('utf-8', errors='replace'))
    for part in payload.get('parts', []):
        results.extend(find_parts(part, mime))
    return results
for m in data.get('thread', {}).get('messages', []):
    for t in find_parts(m['payload']):
        print(t)
"
```

## メッセージ取得

```bash
gog gmail get <messageId> -a <account> -j
```

## メール送信

```bash
gog gmail send -a <account> --to "<to>" --subject "<subject>" --body "<body>"
```

主要フラグ:
| フラグ | 説明 |
|---|---|
| `--cc "<cc>"` | CC |
| `--bcc "<bcc>"` | BCC |
| `--attach "<path>"` | 添付ファイル |
| `--reply-to "<messageId>"` | 返信 |
| `--html` | HTML形式 |

## ラベル管理

```bash
gog gmail labels list -a <account>
gog gmail labels create "<name>" -a <account>
gog gmail thread modify <threadId> --add-labels "<label>" -a <account>
gog gmail thread modify <threadId> --remove-labels "<label>" -a <account>
```

## 下書き

```bash
gog gmail drafts list -a <account>
gog gmail drafts create -a <account> --to "<to>" --subject "<subject>" --body "<body>"
```
