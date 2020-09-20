-- DISCORD CONFIGURATION

-- URL of the Discord webhook. Leave as '' to disable sending messages to Discord
local DISCORD_WEBHOOK = ''

-- The name to use on Discord for system messages
local DISCORD_NAME = ''

-- The default avatar to use on Discord
local DISCORD_AVATAR = ''

-- Discord bot token for getting player avatars from Discord
local DISCORD_BOT = ''

-- Steam key for getting player avatars from Steam. Leave as '' to disable Steam integration.
local STEAM_KEY = ''

-- Roles that can appear in front of player names, based on an ace.
--
-- Example:
--   {name = 'Admin', ace = 'chat.admin'}
--
-- To show this role for all members of group.admin:
--   add_ace group.admin chat.admin allow
local Roles = {
	--{name = 'Admin', ace = 'chat.admin'},
	--{name = 'Moderator', ace = 'chat.moderator'}
}

-- END OF DISCORD CONFIGURATION

-- API URLs
local DISCORD_API = 'https://discordapp.com/api/users/'
local DISCORD_CDN = 'https://cdn.discordapp.com/avatars/'
local STEAM_API = 'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key='

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
	PerformHttpRequest(DISCORD_WEBHOOK, function(err, text, headers) end, 'POST', json.encode({username = DISCORD_NAME, embeds = connect, avatar_url = DISCORD_IMAGE}), { ['Content-Type'] = 'application/json' })
end

function GetNameWithRole(source)
	local name = GetPlayerName(source)
	local role = nil

	for i = 1, #Roles do
		if IsPlayerAceAllowed(tostring(source), Roles[i].ace) then
			role = Roles[i].name
			break
		end
	end

	if role then
		return role .. ' | ' .. name
	else
		return name
	end
end

-- Override default /say command
RegisterCommand('say', function(source, args, user)
	local message = table.concat(args, " ")

	-- If source is a player, send a local message
	if source > 0 then
		local name = GetNameWithRole(source)

		if message == "" then
			return
		end

		TriggerClientEvent('poodlechat:localMessage', -1, source, name, message)
	-- If source is console, send to all players
	else
		TriggerClientEvent('chat:addMessage', -1, {color = {255, 255, 255}, args = {'console', message}})
	end
end, false)

-- Send local messages by default
AddEventHandler('chatMessage', function(source, name, message)
	if string.sub(message, 1, string.len("/")) ~= "/" then
		local name = GetNameWithRole(source)
		TriggerClientEvent("poodlechat:localMessage", -1, source, name, message)
	end
	CancelEvent()
end)

RegisterCommand('me', function(source, args, user)
	local name = GetPlayerName(source)
	local message = table.concat(args, " ")

	if message == "" then
		return
	end

	TriggerClientEvent("poodlechat:action", -1, source, name, message)
end, false)

function SendUserMessageToDiscord(source, name, message, avatar)
	if avatar then
		PerformHttpRequest(DISCORD_WEBHOOK, function(err, text, headers) end, 'POST', json.encode({username = name .. " [" .. source .. "]", content = message, avatar_url = avatar, tts = false}), { ['Content-Type'] = 'application/json' })
	else
		PerformHttpRequest(DISCORD_WEBHOOK, function(err, text, headers) end, 'POST', json.encode({username = name .. " [" .. source .. "]", content = message, tts = false}), { ['Content-Type'] = 'application/json' })
	end
end

function SendMessageWithDiscordAvatar(source, name, message)
	if DISCORD_BOT == '' then
		return false
	end

	local id = GetIDFromSource('discord', source)

	if id then
		PerformHttpRequest(DISCORD_API .. id, function(err, text, headers)
			local hash = json.decode(text)['avatar']
			local avatar = DISCORD_CDN .. id .. '/' .. hash .. '.png'
			SendUserMessageToDiscord(source, name, message, avatar)
		end, 'GET', '', {['Authorization'] = 'Bot ' .. DISCORD_BOT})

		return true
	end

	return false
end

function SendMessageWithSteamAvatar(source, name, message)
	if STEAM_KEY == '' then
		return false
	end

	local id = GetIDFromSource('steam', source)

	if id then
		PerformHttpRequest(STEAM_API .. STEAM_KEY .. '&steamids=' .. tonumber(id, 16), function(err, text, headers)
			local avatar = string.match(text, '"avatarfull":"(.-)","')
			SendUserMessageToDiscord(source, name, message, avatar)
		end)

		return true
	end

	return false
end

function GlobalCommand(source, args, user)
	local name = GetNameWithRole(source)
	local message = table.concat(args, ' ')

	if message == '' then
		return
	end

	TriggerClientEvent('chat:addMessage', -1, {color = {212, 175, 55}, args = {'[Global] ' .. name, message}})

	-- Send global messages to Discord
	if DISCORD_WEBHOOK ~= '' then
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

RegisterCommand('global', function(source, args, user)
	GlobalCommand(source, args, user)
end, false)

RegisterCommand('g', function(source, args, user)
	GlobalCommand(source, args, user)
end, false)

function Whisper(source, id, message)
	local name = GetNameWithRole(source)
	local found = false

	if message == "" then
		return
	end

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

RegisterCommand('whisper', function(source, args, user)
	WhisperCommand(source, args, user)
end, false)

RegisterCommand('w', function(source, args, user)
	WhisperCommand(source, args, user)
end, false)

RegisterNetEvent('poodlechat:reply')
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
