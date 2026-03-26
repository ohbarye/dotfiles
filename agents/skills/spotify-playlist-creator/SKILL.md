---
name: spotify-playlist-creator
description: >
  Use when the user asks to "create a Spotify playlist", "make a playlist",
  "add songs to Spotify", "build a playlist from artists", "create playlist from article/URL",
  or wants to automate Spotify playlist management using agent-browser.
  Handles: extracting artists from URLs/text, searching songs, creating and naming playlists.
---

# Spotify Playlist Creator

Create Spotify playlists by controlling the Spotify desktop app via `agent-browser` (CDP).

## Prerequisites

Before starting, verify the environment:

```bash
# 1. Check agent-browser availability
npx agent-browser --version

# 2. Check Spotify is installed
ls /Applications/Spotify.app

# 3. Kill existing Spotify and relaunch with debug port
osascript -e 'quit app "Spotify"'
sleep 2
open -a "Spotify" --args --remote-debugging-port=9222
sleep 3

# 4. Connect agent-browser
npx agent-browser connect 9222
```

## Input Handling

Determine the input type and extract artist names:

### Pattern A: Artist names provided directly
Use the list as-is.

### Pattern B: URL provided
Use `WebFetch` to retrieve the article content and extract artist/band names from the text. If WebFetch fails (JS-rendered page), note that agent-browser cannot navigate away from Spotify — ask the user to paste the text instead.

### Pattern C: Raw text provided
Parse the text and extract artist/band names using your judgment.

## Workflow

### Step 1: Create a new playlist

```bash
# Take initial snapshot to find the Create button
npx agent-browser snapshot

# Click the "Create" button (usually a "+" icon in the sidebar)
npx agent-browser click <create-button-ref>
sleep 2

# A menu appears — click "Playlist"
npx agent-browser snapshot
npx agent-browser click <playlist-menu-item-ref>
sleep 3
```

### Step 2: Search and add songs for each artist

For each artist, repeat:

```bash
# Take snapshot to find the current search box ref
npx agent-browser snapshot | grep -E "searchbox|Clear search"

# Use `fill` to enter the artist name (more reliable than click+type)
npx agent-browser fill <searchbox-ref> "Artist Name"
sleep 3

# Take snapshot and find "Add to Playlist" buttons
npx agent-browser snapshot | grep -E "Play.*by|Add to Playlist.*ref="

# Click 2-4 "Add to Playlist" buttons for top songs
npx agent-browser click <add-button-ref>
sleep 1
```

**Target: 2-4 songs per artist** (adjust based on user preference).

### Step 3: Rename the playlist

The "Edit details" button has no accessible ref. Use JavaScript eval:

```bash
# Open the Edit Details dialog via JS
npx agent-browser eval "document.querySelector('button[aria-label*=\"Edit details\"]').dispatchEvent(new MouseEvent('click', {bubbles: true}))"
sleep 2

# Take snapshot to find the name/description input refs
npx agent-browser snapshot | grep -E "textbox|input|Name|Description"

# Fill in the name and description
npx agent-browser fill <name-input-ref> "Playlist Name"
npx agent-browser fill <description-input-ref> "Description text"

# Click Save
npx agent-browser snapshot | grep -E "Save"
npx agent-browser click <save-button-ref>
```

### Step 4: Show result summary

Display a table of all added tracks:

```
| # | Song | Artist |
|---|------|--------|
| 1 | Song Name | Artist Name |
...
```

## Critical UI Notes

See [references/spotify-ui-patterns.md](references/spotify-ui-patterns.md) for detailed patterns.

Key gotchas:

1. **Refs change on every snapshot** — ALWAYS take a fresh `snapshot` before interacting with any element. Never reuse refs from a previous snapshot.

2. **Search box ref changes** — The `searchbox "Search for songs or episodes"` gets a new ref after each snapshot. Always `grep` for it.

3. **Use `fill` instead of `click` + `type` for search** — `fill` replaces the field content directly. Using `click` + `type` appends text and causes issues. If "Clear search field" button times out, `fill` is the workaround.

4. **Edit Details requires JS eval** — The button exists but has no accessible ref in the snapshot. Use `dispatchEvent(new MouseEvent('click', {bubbles: true}))` to trigger it.

5. **Search result validation** — Spotify may return results for a different artist. Check `Play <song> by <artist>` text to confirm the correct artist before adding. Skip artists not found on Spotify.

6. **Removing duplicate tracks** — If a duplicate is added, find its row in the snapshot, click the "More options" button for that row, then click "Remove from this playlist" in the context menu.

7. **Cannot navigate away** — agent-browser is connected to the Spotify Electron app. You cannot use it to browse external URLs. Use `WebFetch` or other tools for web content.

8. **Rate limiting** — Add `sleep 1` between clicks and `sleep 3` after search queries to let the UI settle.
