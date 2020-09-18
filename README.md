# PoodleChat

Chat resource used on the Poodle's Palace FiveM and RedM servers:
- [fivem.khzae.net](https://fivem.khzae.net)
- [redm.khzae.net](https://redm.khzae.net)

Based on the following resources:
- https://github.com/DevLanceGood/RPChat
- https://github.com/Tazi0/Server-Logging

# Features

- Text chat is proximity by default
- /global or /g to send a message to all players
- /whisper or /w to send a private message
- Optionally sends events and global messages to a Discord channel via a webhook

# Configuration

The following variables in [server.lua](server.lua) control the Discord integration:

| Variable          | Description                                                                          |
|-------------------|--------------------------------------------------------------------------------------|
| `DISCORD_WEBHOOK` | The webhook URL to use to send messages to a channel.                                |
| `DISCORD_NAME`    | The name to use when sending event messages (joins/disconnects).                     |
| `DISCORD_AVATAR`  | The avatar to use when sending event messages or if no avatar is found for a player. |
| `DISCORD_BOT`     | A Discord bot token to use in order to retrieve avatars from Discord.                |
| `STEAM_KEY`       | A Steam key to to use in order to retrieve avatars from Steam.                       |

All of these are optional, and can be left with their default value (empty string, `''`) to disable the Discord integration.

# Commands

```
/clear
```

Clears the chat window history.

```
/global [message]
/g [message]
```

Sends a message to all players in the server.

```
/me [action]
```

Sends a message to nearby players in the form of `[name] [action]`.

```
/reply [message]
/r [message]
```

Sends a message to the last player that sent you a private message (`/whisper`) or that you sent a private message to.

```
/say [message]
```

Sends a message to nearby players. The default text chat is also overridden to be proximity-based.

```
/whisper [player] [message]
/w [player] [message]
```

Sends a private message to a player. `[player]` can be either an ID number or name.
