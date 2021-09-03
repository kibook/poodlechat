RegisterServerEvent('chat:init')
RegisterServerEvent('chat:addTemplate')
RegisterServerEvent('chat:addMessage')
RegisterServerEvent('chat:addSuggestion')
RegisterServerEvent('chat:removeSuggestion')
RegisterServerEvent('_chat:messageEntered')
RegisterServerEvent('chat:clear')
RegisterServerEvent('__cfx_internal:commandFallback')
RegisterNetEvent('playerJoining')

local VORP = ServerConfig.Framework == 'VORP' and exports.vorp_core:vorpAPI()

local nicknames = json.decode(GetResourceKvpString('nicknames')) or {}

function GetNickname(source)
	local identifier = GetIDFromSource(ServerConfig.Identifier, source)

	if identifier then
		return nicknames[identifier]
	end
end

function HasNickname(source)
	local identifier = GetIDFromSource(ServerConfig.Identifier, source)

	if identifier then
		return nicknames[identifier] ~= nil
	else
		return false
	end
end

function SetNickname(source, nickname)
	local identifier = GetIDFromSource(ServerConfig.Identifier, source)

	if identifier then
		nicknames[identifier] = nickname
		SetResourceKvp('nicknames', json.encode(nicknames))
		return true
	else
		return false
	end
end

function GetRealName(source)
	return GetPlayerName(source) or '?'
end

function GetName(source)
	if VORP then
		local char = VORP.getCharacter(source)
		return char.firstname .. ' ' .. char.lastname
	elseif HasNickname(source) then
		return GetNickname(source)
	else
		return GetRealName(source)
	end
end

function GetNameWithId(source)
	return '[' .. source .. '] ' .. GetName(source)
end

RegisterCommand("nick", function(source, args, raw)
	local nickname = args[1] and table.concat(args, ' ')

	if nickname and string.len(nickname) > ServerConfig.MaxNicknameLen then
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0 ,0},
			args = {'Error', 'Nicknames cannot be more than ' .. ServerConfig.MaxNicknameLen .. ' characters long'}
		})
		return
	end

	if SetNickname(source, nickname) then
		if nickname then
			TriggerClientEvent('chat:addMessage', source, {
				color = {255, 255, 128},
				args = {'Your nickname was set to ' .. nickname}
			})
		else
			TriggerClientEvent('chat:addMessage', source, {
				color = {255, 255, 128},
				args = {'Your nickname has been unset'}
			})
		end
	else
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'Failed to set nickname'}
		})
	end
end, true)

AddEventHandler('_chat:messageEntered', function(author, color, message, channel)
    if not message or not author then
        return
    end

    TriggerEvent('chatMessage', source, author, message, channel)

    if not WasEventCanceled() then
        TriggerClientEvent('chatMessage', -1, author,  { 255, 255, 255 }, message)
    end

    print(author .. '^7: ' .. message .. '^7')
end)

AddEventHandler('__cfx_internal:commandFallback', function(command)
    local name = GetNameWithId(source)

    TriggerEvent('chatMessage', source, name, '/' .. command)

    if not WasEventCanceled() then
        TriggerClientEvent('chatMessage', -1, name, { 255, 255, 255 }, '/' .. command)
    end

    CancelEvent()
end)

-- player join messages
AddEventHandler('chat:init', function()
    TriggerClientEvent('chatMessage', -1, '', { 255, 255, 255 }, '^2* ' .. GetName(source) .. '^r^2 joined.')
end)

AddEventHandler('playerDropped', function(reason)
    TriggerClientEvent('chatMessage', -1, '', { 255, 255, 255 }, '^2* ' .. GetName(source) .. '^r^2 left (' .. reason .. ')')
end)

-- command suggestions for clients
local function refreshCommands(player)
    if GetRegisteredCommands then
        local registeredCommands = GetRegisteredCommands()

        local suggestions = {}

        for _, command in ipairs(registeredCommands) do
            if IsPlayerAceAllowed(player, ('command.%s'):format(command.name)) then
                table.insert(suggestions, {
                    name = '/' .. command.name,
                    help = ''
                })
            end
        end

        TriggerClientEvent('chat:addSuggestions', player, suggestions)
    end
end

AddEventHandler('chat:init', function()
    refreshCommands(source)
end)

AddEventHandler('onServerResourceStart', function(resName)
    Wait(500)

    for _, player in ipairs(GetPlayers()) do
        refreshCommands(player)
    end
end)

-- API URLs
local DISCORD_CDN = 'https://cdn.discordapp.com/avatars/'
local STEAM_API = 'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key='

RegisterNetEvent('poodlechat:staffMessage')
RegisterNetEvent('poodlechat:globalMessage')
RegisterNetEvent('poodlechat:actionMessage')
RegisterNetEvent('poodlechat:whisperMessage')
RegisterNetEvent('poodlechat:getPermissions')
RegisterNetEvent('poodlechat:report')
RegisterNetEvent('poodlechat:sendToDiscord')
RegisterNetEvent('poodlechat:mute')
RegisterNetEvent('poodlechat:unmute')
RegisterNetEvent('poodlechat:showMuted')

local LogColors = {
	['name'] = '\x1B[35m',
	['default'] = '\x1B[0m',
	['error'] = '\x1B[31m',
	['success'] = '\x1B[32m',
	['warning'] = '\x1B[33m'
}

function Log(label, message)
	local color = LogColors[label]

	if not color then
		color = LogColors.default
	end

	print(string.format('%s[%s]%s %s', color, label, LogColors.default, message))
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

function SendToDiscord(message, color)
	local connect = {
		{
			["color"] = color,
			["description"] = message
		}
	}

	exports.discord_rest:executeWebhook(ServerConfig.DiscordWebhookId, ServerConfig.DiscordWebhookToken, {
		username = ServerConfig.DiscordName,
		embeds = connect,
		avatar_url = ServerConfig.DiscordAvatar
	})
end

function GetNameWithRoleAndColor(source)
	local name = GetNameWithId(source)
	local role = nil

	for i = 1, #ServerConfig.Roles do
		if IsPlayerAceAllowed(tostring(source), ServerConfig.Roles[i].ace) then
			role = ServerConfig.Roles[i]
			break
		end
	end

	if role then
		return role.name .. ' | ' .. name, role.color
	else
		return name, nil
	end
end

function Emojit(text)
	for i = 1, #Emoji do
		for k = 1, #Emoji[i][1] do
			text = string.gsub(text, Emoji[i][1][k], Emoji[i][2])
		end
	end
	return text
end

function LocalMessage(source, message)
	if message == '' then
		return
	end

	message = Emojit(message)

	local name, color = GetNameWithRoleAndColor(source)

	if not color then
		color = Config.DefaultLocalColor
	end

	local license

	if not IsPlayerAceAllowed(source, ServerConfig.NoMuteAce) then
		license = GetIDFromSource(ServerConfig.Identifier, source)
	else
		license = false
	end

	TriggerClientEvent('poodlechat:localMessage', -1, source, license, name, color, message)

	exports.logmanager:log {
		player = source,
		message = ("Sent a local message: %s"):format(message)
	}
end

function SendUserMessageToDiscord(source, name, message, avatar)
	local data = {}
	data.username = name .. ' [' .. source .. ']'
	data.content = message
	if avatar then
		data.avatar_url = avatar
	end
	data.tts = false

	exports.discord_rest:executeWebhook(ServerConfig.DiscordWebhookId, ServerConfig.DiscordWebhookToken, data)
end

function SendMessageWithDiscordAvatar(source, name, message)
	if not IsSet(ServerConfig.DiscordBotToken) then
		return false
	end

	local id = GetIDFromSource('discord', source)

	if id then
		exports.discord_rest:getUser(id, ServerConfig.DiscordBotToken):next(function(user)
			local avatar = DISCORD_CDN .. id .. '/' .. user.avatar .. '.png'
			SendUserMessageToDiscord(source, name, message, avatar)
		end)

		return true
	end

	return false
end

function SendMessageWithSteamAvatar(source, name, message)
	if not IsSet(ServerConfig.SteamKey) then
		return false
	end

	local id = GetIDFromSource('steam', source)

	if id then
		PerformHttpRequest(STEAM_API .. ServerConfig.SteamKey .. '&steamids=' .. tonumber(id, 16), function(status, text, headers)
			local avatar = string.match(text, '"avatarfull":"(.-)","')
			SendUserMessageToDiscord(source, name, message, avatar)
		end)

		return true
	end

	return false
end

function GlobalMessage(source, message)
	if message == '' then
		return
	end

	message = Emojit(message)

	local name, color = GetNameWithRoleAndColor(source)

	if not color then
		color = Config.DefaultGlobalColor
	end

	local license

	if not IsPlayerAceAllowed(source, ServerConfig.NoMuteAce) then
		license = GetIDFromSource(ServerConfig.Identifier, source)
	else
		license = false
	end

	TriggerClientEvent('poodlechat:globalMessage', -1, source, license, name, color, message)

	exports.logmanager:log {
		player = source,
		message = ("Sent a global message: %s"):format(message)
	}

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

AddEventHandler('poodlechat:globalMessage', function(message)
	GlobalMessage(source, message)
end)

function LocalCommand(source, args, raw)
	local message = table.concat(args, ' ')
	LocalMessage(source, message)
end

RegisterCommand('say', function(source, args, raw)
	-- If source is a player, send a local message
	if source and source > 0 then
		LocalCommand(source, args, raw)
	-- If source is console, send to all players
	else
		TriggerClientEvent('chat:addMessage', -1, {color = {255, 255, 255}, args = {'console', table.concat(args, ' ')}})
	end
end, true)

-- Send messages to current channel by default
AddEventHandler('chatMessage', function(source, name, message, channel)
	if string.sub(message, 1, string.len("/")) ~= "/" then
		if channel == 'Global' then
			GlobalMessage(source, message)
		elseif channel == 'Local' then
			LocalMessage(source, message)
		elseif channel == 'Staff' then
			StaffMessage(source, message)
		end
	end
	CancelEvent()
end)

AddEventHandler('poodlechat:actionMessage', function(message)
	local name = GetName(source)

	if message == '' then
		return
	end

	message = Emojit(message)

	local license

	if not IsPlayerAceAllowed(source, ServerConfig.NoMuteAce) then
		license = GetIDFromSource(ServerConfig.Identifier, source)
	else
		license = false
	end

	TriggerClientEvent("poodlechat:action", -1, source, license, name, message)

	exports.logmanager:log {
		player = source,
		message = ("Performed an action: %s"):format(message)
	}
end, false)

function GetPlayerId(id)
	-- First, search by ID
	for _, playerId in ipairs(GetPlayers()) do
		if playerId == id then
			return playerId
		end
	end

	-- Then, try by name
	id = string.lower(id)

	for _, playerId in ipairs(GetPlayers()) do
		if string.lower(GetName(playerId)) == id then
			return playerId
		end
	end

	return nil
end

AddEventHandler('poodlechat:whisperMessage', function(id, message)
	local name, color = GetNameWithRoleAndColor(source)

	if message == '' then
		return
	end

	message = Emojit(message)

	local target = GetPlayerId(id)

	if target then
		local sendLicense
		local recvLicense

		if not IsPlayerAceAllowed(source, ServerConfig.NoMuteAce) then
			sendLicense = GetIDFromSource(ServerConfig.Identifier, source)
		else
			sendLicense = false
		end

		if not IsPlayerAceAllowed(target, ServerConfig.NoMuteAce) then
			recvLicense = GetIDFromSource(ServerConfig.Identifier, target)
		else
			recvLicense = false
		end

		-- Echo the message to the sender's chat
		TriggerClientEvent('poodlechat:whisperEcho', source, target, recvLicense, GetNameWithId(target), message)
		-- Send the message to the recipient
		TriggerClientEvent('poodlechat:whisper', target, source, sendLicense, name, message)
		-- Set the /reply target for sender and recipient
		TriggerClientEvent('poodlechat:setReplyTo', target, source)
		TriggerClientEvent('poodlechat:setReplyTo', source, target)

		exports.logmanager:log {
			player = source,
			message = ("Whispered to %s: %s"):format(GetRealName(target), message)
		}
	else
		TriggerClientEvent('poodlechat:whisperError', source, id)
	end
end)

function StaffMessage(source, message)
	if not IsPlayerAceAllowed(source, ServerConfig.StaffChannelAce) then
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'You do not have access to the Staff channel.'}
		})
		return
	end

	if message == '' then
		return
	end

	message = Emojit(message)

	local name, color = GetNameWithRoleAndColor(source)

	if not color then
		color = Config.DefaultStaffColor
	end

	for _, playerId in ipairs(GetPlayers()) do
		if IsPlayerAceAllowed(playerId, ServerConfig.StaffChannelAce) then
			TriggerClientEvent('chat:addMessage', playerId, {
				color = color,
				args = {'[Staff] ' .. name, message}
			});
		end
	end

	exports.logmanager:log {
		player = source,
		message = ("Sent a staff message: %s"):format(message)
	}
end

AddEventHandler('poodlechat:staffMessage', function(message)
	StaffMessage(source, message)
end)

function SetPermissions(source)
	TriggerClientEvent('poodlechat:setPermissions', source, {
		canAccessStaffChannel = IsPlayerAceAllowed(source, ServerConfig.StaffChannelAce)
	})
end

AddEventHandler('poodlechat:getPermissions', function()
	SetPermissions(source)
end)

RegisterCommand('poodlechat_refresh_perms', function(source, args, raw)
	for _, playerId in ipairs(GetPlayers()) do
		SetPermissions(playerId)
	end
end, true)

function IsResponseOk(status)
	return status >= 200 and status <= 299
end

function SendReportToDiscord(source, id, reason)
	local reporterName = GetName(source)
	local reporteeName = GetName(id)
	local reporterLicense = GetIDFromSource(ServerConfig.Identifier, source)
	local reporteeLicense = GetIDFromSource(ServerConfig.Identifier, id)
	local reporterIp = GetPlayerEndpoint(source)
	local reporteeIp = GetPlayerEndpoint(id)

	local message = table.concat({
		'**Reporter:** ' .. reporterName,
		'**License:** ' .. reporterLicense,
		'**IP:** ' .. reporterIp,
		'',
		'**Player Reported:** ' .. reporteeName,
		'**License:** ' .. reporteeLicense,
		'**IP:** ' .. reporteeIp,
		'',
		'**Reason:** ' .. reason
	}, '\n')

	local data = {
		embeds = {
			{
				['color'] = ServerConfig.DiscordReportColor,
				['description'] = message
			}
		}
	}

	exports.discord_rest:executeWebhookUrl(ServerConfig.DiscordReportWebhook, data):next(function()
		TriggerClientEvent('chat:addMessage', source, {
			color = ServerConfig.DiscordReportFeedbackColor,
			args = {ServerConfig.DiscordReportFeedbackSuccessMessage}
		})
	end, function()
		Log('error', string.format('Failed to send report: %d %s %s\n%s', status, text, json.encode(headers), message))

		TriggerClientEvent('chat:addMessage', source, {
			color = ServerConfig.DiscordReportFeedbackColor,
			args = {ServerConfig.DiscordReportFeedbackFailureMessage}
		})
	end)
end

AddEventHandler('poodlechat:report', function(player, reason)
	if not IsDiscordReportEnabled() then
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'The report function is not enabled.'}
		})
		return
	end

	local id = GetPlayerId(player)

	if id then
		SendReportToDiscord(source, id, reason)
	else
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'No player with ID or name ' .. player .. ' exists'}
		})
	end
end)

AddEventHandler('poodlechat:mute', function(player)
	local id = tonumber(GetPlayerId(player))

	if id then
		local license = GetIDFromSource(ServerConfig.Identifier, id)

		if license then
			TriggerClientEvent('poodlechat:mute', source, id, license)
		else
			TriggerClientEvent('chat:addMessage', source, {
				color = {255, 0, 0},
				args = {'Error', 'Failed to mute player'}
			})
		end
	else
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'No player with ID or name ' .. player .. ' exists'}
		})
	end
end)

AddEventHandler('poodlechat:unmute', function(player)
	local id = tonumber(GetPlayerId(player))

	if id then
		local license = GetIDFromSource(ServerConfig.Identifier, id)
		TriggerClientEvent('poodlechat:unmute', source, id, license)
	else
		TriggerClientEvent('chat:addMessage', source, {
			color = {255, 0, 0},
			args = {'Error', 'No player with ID or name ' .. player .. ' exists'}
		})
	end
end)

AddEventHandler('poodlechat:showMuted', function(mutedPlayers)
	local players = GetPlayers()

	local mutedPlayerIds = {}

	for license, name in pairs(mutedPlayers) do
		for _, id in ipairs(players) do
			if GetIDFromSource(ServerConfig.Identifier, id) == license then
				table.insert(mutedPlayerIds, tonumber(id))
			end
		end
	end

	TriggerClientEvent('poodlechat:showMuted', source, mutedPlayerIds)
end)

AddEventHandler('playerJoining', function()
	SendToDiscord("**" .. GetName(source) .. "** is connecting to the server.", 65280)
end)

AddEventHandler('playerDropped', function(reason)
	local color = 16711680
	if string.match(reason, "Kicked") or string.match(reason, "Banned") then
		color = 16007897
	end

	SendToDiscord("**" .. GetName(source) .. "** has left the server. \n Reason: " .. reason, color)
end)

AddEventHandler('poodlechat:sendToDiscord', SendToDiscord)

exports('sendToDiscord', SendToDiscord)

-- Display Discord messages in in-game chat
local LastMessageId = nil

function DeleteDiscordMessage(message)
	exports.discord_rest:deleteMessage(ServerConfig.DiscordChannel, message.id, ServerConfig.DiscordBotToken)
end

function DiscordMessage(message)
	if message.author.id == ServerConfig.DiscordWebhookId then
		return
	end

	if message.content == '' then
		return
	end

	if string.sub(message.content, 1, #ServerConfig.ChatCommandPrefix) == ServerConfig.ChatCommandPrefix then
		local principal = 'identifier.discord:' .. message.author.id

		if IsPrincipalAceAllowed(principal, ServerConfig.ExecuteCommandsAce) then
			local command = string.sub(message.content, #ServerConfig.ChatCommandPrefix + 1)
			local commandName = string.match(command, "([^ ]+)")

			if IsPrincipalAceAllowed(principal, 'command.' .. commandName) then
				ExecuteCommand(string.sub(message.content, #ServerConfig.ChatCommandPrefix + 1))
			else
				Log('error', principal .. ' is not allowed to execute ' .. commandName .. ' from Discord')
			end
		else
			Log('error', principal .. ' is not allowed to execute commands from Discord')
		end

		if ServerConfig.DeleteChatCommands then
			DeleteDiscordMessage(message)
		end
	else
		TriggerClientEvent('chat:addMessage', -1, {
			color = ServerConfig.DiscordColor,
			args = {'[Discord] ' .. message.author.username, message.content}
		})
	end
end

local LastMessageId

function GetDiscordMessages()
	return exports.discord_rest:getChannelMessages(ServerConfig.DiscordChannel, {after = LastMessageId}, ServerConfig.DiscordBotToken):next(function(data)
		if #data > 0 then
			-- Extract messages from response
			local messages = {}

			for _, message in ipairs(data) do
				table.insert(messages, message)
			end

			-- Sort by ID
			table.sort(messages, function(a, b)
				return a.id < b.id
			end)

			-- Send to in-game chat
			for _, message in ipairs(messages) do
				DiscordMessage(message)
			end

			LastMessageId = messages[#messages].id
		end
	end, function(err)
		Log('warning', ('Failed to receive messages: %d'):format(err))
	end)
end

-- Get the last message ID to start from
function InitDiscordReceive()
	return exports.discord_rest:getChannel(ServerConfig.DiscordChannel, ServerConfig.DiscordBotToken):next(function(channel)
		Log('success', 'Ready to receive Discord messages!')
		LastMessageId = channel.last_message_id
	end, function(err)
		Log('error', ('Failed to initialize: %d'):format(err))
		Citizen.Wait(5000)
	end)
end

if IsDiscordReceiveEnabled() then
	Citizen.CreateThread(function()
		while not LastMessageId do
			Citizen.Await(InitDiscordReceive())
		end

		while true do
			Citizen.Await(GetDiscordMessages())
		end
	end)
end
