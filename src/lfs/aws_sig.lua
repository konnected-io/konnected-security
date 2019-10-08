local module = {}
local function sign(key, msg)
	return crypto.hmac('SHA256', msg, key)
end

local function getSignatureKey(key, dateStamp, regionName, serviceName)
    local kDate = sign('AWS4' .. key, dateStamp)
    local kRegion = sign(kDate, regionName)
    local kService = sign(kRegion, serviceName)
    return sign(kService, 'aws4_request')
end

local function url_quote(text)
	return string.gsub(text, "([^%w_%-~%.])", function(c) return string.format("%%%02X", string.byte(c)) end)
end

local function createSignature(aws_access_key, aws_secret_key, aws_session_token, region, service, method, url, payload)
	local t = rtctime.epoch2cal(rtctime.get())
	local amz_date = string.format("%04d%02d%02dT%02d%02d%02dZ", t['year'], t['mon'], t['day'], t['hour'], t['min'], t['sec'])
	local datestamp = amz_date:sub(1,8)

	local protocol, host, path
	protocol, host, path = string.match(url, "(%w+)://([^/]+)(.*)")
	path = path or '/'

	local canonical_headers = 'host:' .. host .. ':443\n'
	local signed_headers = 'host'

	local credential_scope = datestamp .. '/' .. region .. '/' .. service .. '/' .. 'aws4_request'

	local canonical_querystring = (
		'X-Amz-Algorithm=AWS4-HMAC-SHA256' ..
		'&X-Amz-Credential=' .. url_quote(aws_access_key .. '/' .. credential_scope) ..
		'&X-Amz-Date=' .. amz_date ..
		'&X-Amz-Expires=86400' ..
		'&X-Amz-SignedHeaders=' .. signed_headers
	)
	local payload_hash = 'UNSIGNED-PAYLOAD'
	if payload ~= nil then
		payload_hash = crypto.toHex(crypto.hash('SHA256', payload))
	end
	local canonical_request = (
		method .. '\n' .. path .. '\n' ..
		canonical_querystring .. '\n' .. canonical_headers .. '\n' ..
		signed_headers .. '\n' .. payload_hash
	)
	-- print('canonical_request', canonical_request)
	local string_to_sign = 'AWS4-HMAC-SHA256\n' .. amz_date .. '\n' .. credential_scope .. '\n' ..  crypto.toHex(crypto.hash('SHA256', canonical_request))

	local signing_key = getSignatureKey(aws_secret_key, datestamp, region, service)
	local signature = crypto.toHex(crypto.hmac('SHA256', string_to_sign, signing_key))
	local uri =  protocol .. '://' .. host .. path .. '?' .. canonical_querystring .. '&X-Amz-Signature=' .. signature
	if aws_session_token ~= nil then
		uri = uri .. '&X-Amz-Security-Token=' .. url_quote(aws_session_token)
	end

	return uri
end
module.createSignature = createSignature
return module
