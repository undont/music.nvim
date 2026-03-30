<div align="center">

# music.nvim

**Now playing for Neovim — album art, track info, and playback controls without leaving your editor.**

[![CI](https://img.shields.io/github/actions/workflow/status/seanhalberthal/music.nvim/ci.yml?branch=main&style=flat&logo=githubactions&logoColor=white&label=CI)](https://github.com/seanhalberthal/music.nvim/actions)
[![Neovim](https://img.shields.io/badge/Neovim-0.8%2B-57A143?style=flat&logo=neovim&logoColor=white)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-2C2D72?style=flat&logo=lua&logoColor=white)](https://www.lua.org)
[![macOS](https://img.shields.io/badge/macOS-supported-6e7681?style=flat&logo=apple&logoColor=white)](https://github.com/seanhalberthal/music.nvim)
[![Spotify](https://img.shields.io/badge/Spotify-Web%20API-1DB954?style=flat&logo=spotify&logoColor=white)](https://developer.spotify.com)

[Quick Start](#quick-start) · [Configuration](#configuration) · [Supported Backends](#supported-backends) · [How It Works](#how-it-works)

</div>

---

A floating window pops up in your chosen corner with album art and the current track. After a short delay it shrinks to a compact bar showing song, artist, and timestamp — then expands again automatically on every song change.

![expanded-ui](assets/full-ss.png)

![mini-ui](assets/mini-ss.png)

---

## Quick Start

### Requirements

| Dependency | Purpose | Required |
|---|---|---|
| [chafa](https://hpjansson.org/chafa/) | Album art rendering (Unicode block characters) | Yes |
| `osascript` | Apple Music / Spotify control on macOS | macOS only |
| `curl` | Spotify Web API calls | Non-macOS only |

<details>
<summary>Installing chafa</summary>

```bash
# macOS
brew install chafa

# Ubuntu / Debian
sudo apt install chafa

# Windows
scoop install chafa
```

</details>

### Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'seanhalberthal/music.nvim',
  config = function()
    require('music').setup()
  end
}
```

### Spotify Setup (non-macOS only)

On macOS, Spotify works out of the box via AppleScript — no API credentials needed.

On other platforms, create a Spotify app at [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard), set the redirect URI to `http://127.0.0.1:8888/callback`, and grab your Client ID and Client Secret.

Create a `.env` file in the plugin root:

```
SPOTIFY_CLIENT_ID=your_client_id
SPOTIFY_CLIENT_SECRET=your_client_secret
```

Then run the setup script once:

```bash
pip install requests python-dotenv
python scripts/get_token.py
```

This opens a browser, authorises the app, and saves tokens to `~/.spotify_nvim_tokens.json`. Tokens refresh automatically.

---

## Configuration

Defaults:

```lua
require('music').setup({
  poll_interval = 1000,             -- how often to check for track changes (ms)
  preferred_backend = 'apple_music', -- 'apple_music' | 'spotify' | 'auto'
  position = 'bottom-left',         -- 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'
  window = {
    width = 30,
    expanded_height = 16,           -- height when album art is visible
    compact_height = 3,             -- height after minimising
    expand_duration = 1500,         -- ms before shrinking to compact view
  },
  highlights = {
    background = 'Normal',          -- window background highlight group
    border = 'FloatBorder',         -- border highlight group
    text = 'NormalFloat',           -- text highlight group
  },
})
```

Any valid Neovim highlight group works — run `:Telescope highlights` or `:highlight` to browse what's available in your theme.

### Keymaps

| Key | Action |
|---|---|
| `<leader>kp` | Toggle the window |
| `<leader>ks` | Play / pause |
| `<leader>kn` | Next track |
| `<leader>kb` | Previous track |

### Health Check

Run `:checkhealth music` to verify dependencies are installed and backends are available.

---

## Supported Backends

| Backend | Platform | Auth | Playback Controls |
|---|---|---|---|
| **Apple Music** | macOS | None (AppleScript) | Full |
| **Spotify (local)** | macOS | None (AppleScript) | Full |
| **Spotify (Web API)** | All platforms | API credentials + Premium | Full |

Set `preferred_backend` to `'auto'` to detect which music app is running. When both Apple Music and Spotify are open, Apple Music takes priority.

When set to `'spotify'`, the plugin automatically picks the AppleScript backend on macOS and the Web API backend elsewhere.

---

## How It Works

The plugin polls the active music app every `poll_interval` milliseconds:

- **macOS** — uses `osascript` to talk to Spotify.app or Music.app directly
- **Other platforms** — uses the Spotify Web API via async `curl` calls

Album art is downloaded once per track and cached for the session, then rendered as Unicode block characters using chafa. A terminal with Unicode support is required (most modern terminals work — Ghostty, WezTerm, Kitty, iTerm2, Alacritty, Windows Terminal).

---

## Notes

- Spotify Web API playback controls require Premium (the macOS AppleScript backend has no such restriction)
- Apple Music requires macOS
- Token file at `~/.spotify_nvim_tokens.json` refreshes automatically on expiry
