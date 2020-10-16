Config = {}

-- Colour for action messages (/me)
Config.ActionColor = {200, 0, 255}

-- Default colour for local messages
Config.DefaultLocalColor = {0, 153, 204}

-- Default colour for global messages
Config.DefaultGlobalColor = {212, 175, 55}

-- Colour for messages from Discord
Config.DiscordColor = {115, 138, 219}

-- Colour for private messages received from other players
Config.WhisperColor = {254, 127, 156}

-- Colour for private messages sent to other players
Config.WhisperEchoColor = {204, 77, 106}

-- Distance at which action messages are visible
Config.ActionDistance = 50

-- Distance at which local messages are visible
Config.LocalMessageDistance = 50

-- ID of a Discord webhook to post with. Leave as '' to disable sending messages to Discord.
Config.DiscordWebhookId = ''

-- Token for the above Discord webhook. Leave as '' to disable sending messages to Discord.
Config.DiscordWebhookToken = ''

-- The default name to use on Discord.
Config.DiscordName = ''

-- The default avatar to use on Discord.
Config.DiscordAvatar = ''

-- A Discord bot token, used for getting messages and player avatars. Leave as '' to disable.
Config.DiscordBotToken = ''

-- Discord channel ID to echo messages in-game from. Leave as '' to disable showing Discord messages in-game.
Config.DiscordChannel = ''

-- Discord channel to post player reports in.
Config.DiscordReportChannel = ''

-- Colour used for the report message embed on Discord.
Config.DiscordReportColor = 0xfe7f9c

-- Message sent to players upon submitting a report.
Config.DiscordReportFeedbackMessage = 'Your report has been submitted.'

-- Colour for the above feedback message.
Config.DiscordReportFeedbackColor = {255, 165, 0}

-- Time in milliseconds between any two Discord requests.
Config.DiscordRateLimit = 2000

-- A Steam API key, used for getting avatars from Steam. Leave as '' to disable.
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
