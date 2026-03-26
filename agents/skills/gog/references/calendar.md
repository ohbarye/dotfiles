# Calendar

## カレンダー一覧

```bash
gog calendar calendars -a <account> -j
```

## 予定一覧

```bash
gog calendar events -a <account> -j
gog calendar events -a <account> --from today --to today -j    # 今日の予定
gog calendar events -a <account> --from 2026-03-15 --to 2026-03-21 -j  # 期間指定
gog calendar events <calendarId> -a <account> -j  # 特定カレンダー
```

主要フラグ:
| フラグ | 説明 |
|---|---|
| `--from <date>` | 開始日（`today`, `tomorrow`, `YYYY-MM-DD`） |
| `--to <date>` | 終了日 |
| `--max <N>` | 最大件数 |
| `--all` | 全カレンダー統合表示 |

## 予定の詳細

```bash
gog calendar event <calendarId> <eventId> -a <account> -j
```

## 予定の検索

```bash
gog calendar search "<query>" -a <account> -j
```

## 予定の作成

```bash
gog calendar create <calendarId> -a <account> \
  --summary "<title>" \
  --start "2026-03-20T10:00:00" \
  --end "2026-03-20T11:00:00" \
  --description "<description>" \
  --attendees "user@example.com"
```

## 予定の更新

```bash
gog calendar update <calendarId> <eventId> -a <account> \
  --summary "<new title>"
```

## 予定の削除

```bash
gog calendar delete <calendarId> <eventId> -a <account>
```

## 空き時間確認

```bash
gog calendar freebusy "<email1>,<email2>" -a <account> --from <start> --to <end> -j
```

## コンフリクト検出

```bash
gog calendar conflicts -a <account> --from <start> --to <end>
```

## RSVP

```bash
gog calendar respond <calendarId> <eventId> -a <account> --status accepted|declined|tentative
```

## Focus Time / Out of Office

```bash
gog calendar focus-time -a <account> --from "2026-03-20T14:00:00" --to "2026-03-20T16:00:00"
gog calendar out-of-office -a <account> --from "2026-03-25" --to "2026-03-26"
```
