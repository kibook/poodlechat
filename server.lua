-- API URLs
local DISCORD_API = 'https://discord.com/api'
local DISCORD_CDN = 'https://cdn.discord.com/avatars/'
local STEAM_API = 'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key='

RegisterNetEvent('poodlechat:reply')

-- Queue to rate limit Discord requests
local DiscordQueue = {}

function EnqueueDiscordRequest(cb)
	table.insert(DiscordQueue, 1, cb)
end

function ProcessDiscordQueue()
	table.remove(DiscordQueue)()
end

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

function IsDiscordEnabled()
	return IsDiscordSendEnabled() or IsDiscordReceiveEnabled()
end

function GetIDFromSource(Type, ID)
	local IDs = GetPlayerIdentifiers(ID)
	for k, CurrentID in pairs(IDs) do
		local ID = stringsplit(CurrentID, ':')
		if (ID[1]:lower() == string.lower(Type)) then
			return ID[2]:lower()
		end
	end
	return nil
end

function stringsplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

function SendToDiscord(name, message, color)
	local connect = {
		{
			["color"] = color,
			["description"] = message
		}
	}

	EnqueueDiscordRequest(function()
		PerformHttpRequest(
			DISCORD_API..'/webhooks/'..Config.DiscordWebhookId..'/'.. Config.DiscordWebhookToken,
			function(err, text, headers) end,
			'POST',
			json.encode({
				username = Config.DiscordName,
				embeds = connect,
				avatar_url = Config.DiscordAvatar
			}),
			{['Content-Type'] = 'application/json' })
	end)
	--PerformHttpRequest(
	--	DISCORD_API .. '/channels/' .. Config.DiscordChannel .. '/messages',
	--	function(err, text, headers)
	--	end,
	--	'POST',
	--	json.encode({
	--		username = Config.DiscordName,
	--		embeds = connect,
	--		avatar_url = Config.DiscordAvatar
	--	}),
	--	{
	--		['Authorization'] = 'Bot ' .. Config.DiscordBotToken,
	--		['Content-Type'] = 'application/json'
	--	})
end

function GetNameWithRoleAndColor(source)
	local name = GetPlayerName(source)
	local role = nil

	for i = 1, #Config.Roles do
		if IsPlayerAceAllowed(tostring(source), Config.Roles[i].ace) then
			role = Config.Roles[i]
			break
		end
	end

	if role then
		return role.name .. ' | ' .. name, role.color
	else
		return name, nil
	end
end

-- Override default /say command
RegisterCommand('say', function(source, args, user)
	local message = table.concat(args, " ")

	if message == "" then
		return
	end

	message = Emojit(message)

	-- If source is a player, send a local message
	if source > 0 then
		local name, color = GetNameWithRoleAndColor(source)

		if not color then
			color = Config.DefaultLocalColor
		end

		TriggerClientEvent('poodlechat:localMessage', -1, source, name, color, message)
	-- If source is console, send to all players
	else
		TriggerClientEvent('chat:addMessage', -1, {color = {255, 255, 255}, args = {'console', message}})
	end
end, false)

-- Send local messages by default
AddEventHandler('chatMessage', function(source, name, message)
	if string.sub(message, 1, string.len("/")) ~= "/" then
		local name, color = GetNameWithRoleAndColor(source)

		if not color then
			color = Config.DefaultLocalColor
		end

		message = Emojit(message)

		TriggerClientEvent("poodlechat:localMessage", -1, source, name, color, message)
	end
	CancelEvent()
end)

RegisterCommand('me', function(source, args, user)
	local name = GetPlayerName(source)
	local message = table.concat(args, " ")

	if message == "" then
		return
	end

	message = Emojit(message)

	TriggerClientEvent("poodlechat:action", -1, source, name, message)
end, false)

function SendUserMessageToDiscord(source, name, message, avatar)
	local data = {}
	data.username = name .. ' [' .. source .. ']'
	data.content = message
	if avatar then
		data.avatar_url = avatar
	end
	data.tts = false

	EnqueueDiscordRequest(function()
		PerformHttpRequest(
			DISCORD_API..'/webhooks/'..Config.DiscordWebhookId..'/'..Config.DiscordWebhookToken,
			function(err, text, headers) end,
			'POST',
			json.encode(data),
			{['Content-Type'] = 'application/json'})
	end)
	--PerformHttpRequest(
	--	DISCORD_API .. '/channels/' .. Config.DiscordChannel .. '/messages',
	--	function(err, text, headers) end,
	--	'POST',
	--	json.encode(data),
	--	{
	--		['Authorization'] = 'Bot ' .. Config.DiscordBotToken,
	--		['Content-Type'] = 'application/json'
	--	})
end

function SendMessageWithDiscordAvatar(source, name, message)
	if not IsSet(Config.DiscordBotToken) then
		return false
	end

	local id = GetIDFromSource('discord', source)

	if id then
		EnqueueDiscordRequest(function()
			PerformHttpRequest(DISCORD_API .. '/users/' .. id, function(err, text, headers)
				local hash = json.decode(text)['avatar']
				local avatar = DISCORD_CDN .. id .. '/' .. hash .. '.png'
				SendUserMessageToDiscord(source, name, message, avatar)
			end, 'GET', '', {['Authorization'] = 'Bot ' .. Config.DiscordBotToken})
		end)

		return true
	end

	return false
end

function SendMessageWithSteamAvatar(source, name, message)
	if not IsSet(Config.SteamKey) then
		return false
	end

	local id = GetIDFromSource('steam', source)

	if id then
		PerformHttpRequest(STEAM_API .. Config.SteamKey .. '&steamids=' .. tonumber(id, 16), function(err, text, headers)
			local avatar = string.match(text, '"avatarfull":"(.-)","')
			SendUserMessageToDiscord(source, name, message, avatar)
		end)

		return true
	end

	return false
end


function GlobalCommand(source, args, user)
	local name, color = GetNameWithRoleAndColor(source)
	local message = table.concat(args, ' ')

	if message == '' then
		return
	end

	if not color then
		color = Config.DefaultGlobalColor
	end

	message = Emojit(message)

	TriggerClientEvent('chat:addMessage', -1, {color = color, args = {'[Global] ' .. name, message}})

	-- Send global messages to Discord
	if IsDiscordSendEnabled() then
		-- Escape @everyone and @here to prevent mentions on Discord
		if string.match(message, "@everyone") then
			message = message:gsub("@everyone", "`@everyone`")
		end
		if string.match(message, "@here") then
			message = message:gsub("@here", "`@here`")
		end

		-- Try getting avatar from Discord, Steam, or fallback to no avatar
		if not SendMessageWithDiscordAvatar(source, name, message) then
			if not SendMessageWithSteamAvatar(source, name, message) then
				SendUserMessageToDiscord(source, name, message, nil)
			end
		end
	end
end

RegisterCommand('global', GlobalCommand, false)
RegisterCommand('g', GlobalCommand, false)

function Whisper(source, id, message)
	local name, color = GetNameWithRoleAndColor(source)
	local found = false

	if message == "" then
		return
	end

	message = Emojit(message)

	-- First, search by ID
	for _, playerId in ipairs(GetPlayers()) do
		if playerId == id then
			found = true
			break
		end
	end

	-- Then, try by name
	if not found then
		id = string.lower(id)
		for _, playerId in ipairs(GetPlayers()) do
			local playerName = string.lower(GetPlayerName(playerId))
			if playerName == id then
				id = playerId
				found = true
				break
			end
		end
	end

	if found then
		-- Echo the message to the sender's chat
		TriggerClientEvent('poodlechat:whisperEcho', source, id, GetPlayerName(id), message)
		-- Send the message to the recipient
		TriggerClientEvent('poodlechat:whisper', id, source, name, message)
		-- Set the /reply target for sender and recipient
		TriggerClientEvent('poodlechat:setReplyTo', id, source)
		TriggerClientEvent('poodlechat:setReplyTo', source, id)
	else
		TriggerClientEvent('poodlechat:whisperError', source, id)
	end
end

function WhisperCommand(source, args, user)
	local id = args[1]

	table.remove(args, 1)
	local message = table.concat(args, " ")

	Whisper(source, id, message)
end

RegisterCommand('whisper', WhisperCommand, false)
RegisterCommand('w', WhisperCommand, false)

AddEventHandler('poodlechat:reply', function(target, message)
	Whisper(source, target, message)
end)

RegisterCommand('clear', function(source, args, user)
	TriggerClientEvent('chat:clear', source)
end, false)

AddEventHandler('playerConnecting', function() 
	SendToDiscord("Server Login", "**" .. GetPlayerName(source) .. "** is connecting to the server.", 65280)
end)

AddEventHandler('playerDropped', function(reason) 
	local color = 16711680
	if string.match(reason, "Kicked") or string.match(reason, "Banned") then
		color = 16007897
	end
	SendToDiscord("Server Logout", "**" .. GetPlayerName(source) .. "** has left the server. \n Reason: " .. reason, color)
end)

-- Display Discord messages in in-game chat
local LastMessageId = nil

-- Get the last message ID to start from
function GetLastDiscordMessage()
	PerformHttpRequest(
	DISCORD_API .. '/channels/' .. Config.DiscordChannel .. '/messages?limit=1',
	function(err, text, headers)
		local data = json.decode(text)
		LastMessageId = data[#data].id
	end,
	'GET',
	'',
	{
		['Authorization'] = 'Bot ' .. Config.DiscordBotToken
	})
end

function DiscordMessage(message)
	if message.id == Config.DiscordWebhookId then
		return
	end

	if message.content == '' then
		return
	end

	TriggerClientEvent('chat:addMessage', -1, {
		color = Config.DiscordColor,
		args = {'[Discord] ' .. message.name, message.content}
	})
end

function GetDiscordMessages()
	PerformHttpRequest(
		DISCORD_API ..'/channels/'..Config.DiscordChannel..'/messages?after='..LastMessageId,
		function(err, text, headers)
			if err ~= 200 then
				print(err, text)
				return
			end

			local data = json.decode(text)

			if #data > 0 then
				-- Extract messages from response
				local messages = {}
				for _, message in ipairs(data) do
					messages[message.id] = {
						id = message.author.id,
						name = message.author.username,
						content = message.content
					}
				end

				-- Sort by ID
				local ids = {}
				for id, message in pairs(messages) do
					table.insert(ids, id)
				end
				table.sort(ids)

				-- Send to in-game chat
				for _, id in ipairs(ids) do
					DiscordMessage(messages[id])
				end

				LastMessageId = ids[#ids]
			end
		end,
		'GET',
		'',
		{['Authorization'] = 'Bot ' .. Config.DiscordBotToken})
end

if IsDiscordEnabled() then
	CreateThread(function()
		if IsDiscordReceiveEnabled() then
			while not LastMessageId do
				Wait(Config.DiscordRateLimit)
				GetLastDiscordMessage()
			end
		end

		while true do
			Wait(Config.DiscordRateLimit)

			if IsDiscordReceiveEnabled() then
				EnqueueDiscordRequest(GetDiscordMessages)
			end

			ProcessDiscordQueue()
		end
	end)
end
