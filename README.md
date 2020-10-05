# PoodleChat

Chat extension used on the Poodle's Palace FiveM and RedM servers:
- [fivem.khzae.net](https://fivem.khzae.net)
- [redm.khzae.net](https://redm.khzae.net)

Based on the following resources:
- https://github.com/DevLanceGood/RPChat
- https://github.com/Tazi0/Server-Logging
- https://forum.cfx.re/t/release-emojis-for-chat-fivemojis-1-0/150713

# Features

- Text chat is proximity by default
- /global or /g to send a message to all players
- /whisper or /w to send a private message
- Optionally sends events and global messages to a Discord channel via a webhook
- Configurable roles based on aces
- Configurable emoji shortcuts (:heart:, :smile:, and so on)

# Configuration

## General

The following variables in [config.lua](config.lua) control general settings for the chat:

| Variable                 | Description                                                           |
|--------------------------|-----------------------------------------------------------------------|
| `ACTION_COLOR`           | The colour for action messages (/me).                                 |
| `DEFAULT_LOCAL_COLOR`    | The default colour for local messages.                                |
| `DEFAULT_GLOBAL_COLOR`   | The default colour for global messages.                               |
| `WHISPER_COLOR`          | The colour for received whisper messages.                             |
| `WHISPER_ECHO_COLOR`     | The colour for sent whisper messages.                                 |
| `ACTION_DISTANCE`        | The distance between players at which actions will be visible.        |
| `LOCAL_MESSAGE_DISTANCE` | The distance between players at which local messages will be visible. |

## Discord

The following variables in [config.lua](config.lua) control the Discord integration:

| Variable          | Description                                                                          |
|-------------------|--------------------------------------------------------------------------------------|
| `DISCORD_WEBHOOK` | The webhook URL to use to send messages to a channel.                                |
| `DISCORD_NAME`    | The name to use when sending event messages (joins/disconnects).                     |
| `DISCORD_AVATAR`  | The avatar to use when sending event messages or if no avatar is found for a player. |
| `DISCORD_BOT`     | A Discord bot token to use in order to retrieve avatars from Discord.                |
| `STEAM_KEY`       | A Steam key to use in order to retrieve avatars from Steam.                          |

All of these are optional, and can be left with their default value (empty string, `''`) to disable the Discord integration.

## Roles

Roles are labels that appear next to a player's name in chat, such as "Admin" or "Moderator". Each role is associated with an ace, so that any players with that ace will receive that role. Optionally, each role can be given a colour that overrides the default local and global chat colours for names.

The list of available roles is configured in [config.lua](config.lua).

Example:

```
ROLES = {
    {name = 'Admin', ace = 'chat.admin'},
    {name = 'Moderator', color = {0, 255, 0}, ace = 'chat.moderator'}
}
```

In `server.cfg`:

```
add_ace group.admin chat.admin allow
add_ace group.moderator chat.moderator allow
```

## Emoji

Shortcuts for emoji can be configured in [emoji.lua](emoji.lua).

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
