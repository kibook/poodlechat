-- Config setting utilities
function IsSet(value)
	return value and value ~= ''
end

function IsDiscordSendEnabled()
	return IsSet(Config.DiscordWebhookId) and IsSet(Config.DiscordWebhookToken)
end

function IsDiscordReceiveEnabled()
	return IsSet(Config.DiscordBotToken) and IsSet(Config.DiscordChannel)
end

function IsDiscordReportEnabled()
	return IsSet(Config.DiscordReportChannel) and IsSet(Config.DiscordBotToken)
end

function IsDiscordEnabled()
	return IsDiscordSendEnabled() or IsDiscordReceiveEnabled() or IsDiscordReportEnabled()
end
