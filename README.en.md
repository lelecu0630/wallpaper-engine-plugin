# Wallpaper Engine Local MCP

A Windows-only local MCP plugin for controlling Wallpaper Engine from compatible ChatGPT desktop Work/Codex clients. This is an experimental, unofficial integration.

## Requirements

- Windows and Wallpaper Engine
- Node.js 20 or later, available on PATH
- A desktop client with local stdio MCP/plugin support and the installed Codex CLI

## Installation

1. Download the full repository ZIP and extract it.
2. Start Wallpaper Engine so the installer can detect its installation directory.
3. Run `INSTALL.cmd`.
4. Fully quit and restart ChatGPT, then select **Wallpaper Engine Local** in a new Work conversation.

The installer copies the server to `%LOCALAPPDATA%\WallpaperEngineMCP\0.1.0`, writes absolute launch paths, and registers the local marketplace/plugin through the installed Codex CLI. No API key or npm dependencies are needed. This is a local stdio server, not a remote MCP URL for web ChatGPT.

For custom paths:

```powershell
.\install.ps1 -WallpaperEnginePath 'D:\Steam\steamapps\common\wallpaper_engine' -WorkshopPath 'D:\Steam\steamapps\workshop\content\431960'
```

## Tools

| Tool | Purpose |
|---|---|
| `status` | Inspect installation paths and accessible app windows |
| `list_wallpapers` | Search and paginate downloaded wallpapers |
| `read_project` | Read allowed project.json metadata |
| `control` | Play, pause, stop, mute, unmute, next wallpaper |
| `apply_wallpaper` | Apply a local wallpaper |
| `apply_properties` | Change existing exposed wallpaper properties |
| `window_snapshot` | Return a window PNG and accessibility elements |
| `ui_action` | Invoke/select/toggle controls or set values |
| `window_pointer` | Experimental targeted click, drag and scroll |
| `window_text` | Experimental window-targeted text input |

## Included fixes and workflow

- Invalid NaN/Infinity accessibility rectangles become null with boundsValid=false.
- Bitmap dimensions are explicitly passed as integers.
- Diagnostics exclude tiny helper windows.
- Server instructions ask the assistant to continue within requested editing scope without repetitive conversational confirmations. Host approval prompts remain governed by the client.

## Validation and limitations

Six protocol/input-validation tests pass. The user reported successful enumeration of 532 wallpapers, usable wallpaper-picker captures, and a setting change followed by restoration. Editor GPU regions may capture as black. Complete effect authoring and save/reopen workflows are not yet verified. Commands returning submitted=true indicate submission, not confirmed success.

No dedicated subscription or upload tools are provided. General coordinate actions are not a semantic security boundary. Target windows are checked against configured Wallpaper Engine executable paths. There is no arbitrary shell tool or global SendInput tool. Metadata access is restricted to configured project/workshop roots. Original projects should be copied before editing; automatic copying is not implemented.

## Development

```sh
node --test test.mjs
node diagnose.mjs
```

Use `DIAGNOSE.cmd` for interactive diagnostics. An empty window list may indicate desktop isolation. Do not interpret a blank screenshot as successful editor access.

## Uninstall

Remove the plugin in ChatGPT or run `codex plugin remove wallpaper-engine-local@wallpaper-local`. Remove the marketplace with `codex plugin marketplace remove wallpaper-local` if desired.

## References

- https://help.wallpaperengine.io/en/functionality/cli.html
- https://developers.openai.com/plugins/build/plugins

한국어: [README.md](README.md)
