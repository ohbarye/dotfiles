# Spotify Desktop App UI Patterns (via agent-browser)

Reference for Spotify's Electron app UI elements as observed through CDP snapshots.

## Sidebar — Library & Playlist Creation

- **Create button**: Usually a `+` icon button in the sidebar library section. Look for `button` near "Your Library".
- **Create menu items**: After clicking Create, a menu appears with:
  - `menuitem "Playlist"` — creates a new empty playlist
  - `menuitem "Folder"` — creates a playlist folder
- A new playlist is created with a default name like `"My Playlist #N"` and appears `[selected]` in the sidebar.

## Search Box

- Located at the top of the playlist view when editing a playlist.
- Identified by: `searchbox "Search for songs or episodes"`
- **Ref changes on every snapshot** — always re-query.
- **Clear search field** button: appears next to the search box when text is present. May timeout when clicked — use `fill` as fallback.
- Best practice: use `npx agent-browser fill <ref> "query"` to replace search text.

## Search Results Structure

After searching, results appear in sections:

```
Songs section:
  - row: "Play <song_title> by <artist_name>"
    - button "Add to Playlist" ref=eXXX  ← click this to add

Artist section:
  - "Artist" label
  - link to artist page

Album section:
  - Album cards
```

- Each song row has an "Add to Playlist" button with a unique ref.
- Verify the artist name in the row text before clicking Add to avoid wrong matches.
- Typically 4-5 song results are shown; click "See more" for additional results.

## Playlist Track List

Once songs are added, the playlist view shows:

```
row "N Play <song_title> <artist_name> <album_name> ... <duration>"
```

- Each row has a "More options for <song_title>" button.
- Clicking "More options" opens a context menu with:
  - `menuitem "Remove from this playlist"` — removes the track
  - Other options: Add to queue, Go to artist, etc.

## Edit Details Dialog

- **Cannot be opened via snapshot ref** — the button is not exposed in the accessibility tree.
- **Solution**: Use JavaScript eval to trigger the click:

```bash
npx agent-browser eval "document.querySelector('button[aria-label*=\"Edit details\"]').dispatchEvent(new MouseEvent('click', {bubbles: true}))"
```

- Dialog contains:
  - `textbox` for playlist name (first textbox ref in snapshot)
  - `textbox` for description (second textbox ref)
  - `button "Save"` — click to save changes
  - Image upload area (optional)

## Common Commands Reference

```bash
# Connect to Spotify
npx agent-browser connect 9222

# Take a snapshot (get current UI state with refs)
npx agent-browser snapshot

# Click an element
npx agent-browser click <ref>

# Fill a text field (replaces content)
npx agent-browser fill <ref> "text"

# Type text (appends to field — prefer fill)
npx agent-browser type <ref> "text"

# Execute JavaScript in the app context
npx agent-browser eval "JS expression"

# Useful snapshot filters
npx agent-browser snapshot | grep -E "searchbox|Clear search"
npx agent-browser snapshot | grep -E "Play.*by|Add to Playlist.*ref="
npx agent-browser snapshot | grep -E "More options for"
npx agent-browser snapshot | grep -E "dialog|textbox|Save"
```

## Timing Guidelines

| Action | Wait time |
|--------|-----------|
| After click (button/menu) | `sleep 1-2` |
| After search query (`fill`) | `sleep 3` |
| After navigation/page load | `sleep 3-5` |
| After dialog open | `sleep 2` |
