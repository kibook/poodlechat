Config = {}

-- Colour for action messages (/me)
Config.ActionColor = {200, 0, 255}

-- Default colour for local messages
Config.DefaultLocalColor = {0, 153, 204}

-- Default colour for global messages
Config.DefaultGlobalColor = {212, 175, 55}

-- Colour for private messages received from other players
Config.WhisperColor = {254, 127, 156}

-- Colour for private messages sent to other players
Config.WhisperEchoColor = {204, 77, 106}

-- Distance at which action messages are visible
Config.ActionDistance = 50

-- Distance at which local messages are visible
Config.LocalMessageDistance = 50

-- URL of a Discord webhook to post with. Leave as '' to disable sending messages to Discord.
Config.DiscordWebhook = ''

-- The default name to use on Discord.
Config.DiscordName = ''

-- The default avatar to use on Discord.
Config.DiscordAvatar = ''

-- A Discord bot token, used for getting player avatars from Discord.
Config.DiscordBotToken = ''

-- A Steam API key, used for getting avatars from Steam.
Config.SteamKey = ''

-- Roles that can appear in front of player names, based on an ace.
-- Optionally, each role can be given a custom colour.
--
-- Example:
--   {name = 'Admin', color = {255, 0, 0}, ace = 'chat.admin'}
--
-- To show this role for all members of group.admin:
--   add_ace group.admin chat.admin allow
Config.Roles = {
	--{name = 'Admin', ace = 'chat.admin'},
	--{name = 'Moderator', color = {0, 255, 0}, ace = 'chat.moderator'}
}
