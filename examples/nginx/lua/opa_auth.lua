local json = require "cjson"
local http = require "resty.http"

local function get_request_count(client_ip, time_window)
    -- Connect to Redis for rate limiting
    local redis = require "resty.redis"
    local red = redis:new()
    red:set_timeout(1000) -- 1 second timeout
    
    local ok, err = red:connect("redis", 6379)
    if not ok then
        ngx.log(ngx.ERR, "Failed to connect to Redis: ", err)
        return 1 -- Default to 1 if Redis is unavailable
    end
    
    local key = "rate_limit:" .. client_ip .. ":" .. time_window
    local count, err = red:incr(key)
    if not count then
        ngx.log(ngx.ERR, "Failed to increment counter: ", err)
        return 1
    end
    
    if count == 1 then
        red:expire(key, 60) -- 60 seconds for minute window
    end
    
    red:close()
    return count
end

local function call_opa_policy()
    local method = ngx.var.request_method
    local path = ngx.var.uri
    local user_agent = ngx.var.http_user_agent or ""
    local client_ip = ngx.var.remote_addr
    local name_param = ngx.var.arg_name or ""
    
    -- Get request count for rate limiting
    local request_count = get_request_count(client_ip, "minute")
    
    -- Prepare OPA input
    local opa_input = {
        input = {
            method = method,
            path = path,
            query_params = {
                name = name_param
            },
            headers = {
                ["user-agent"] = user_agent
            },
            request_count = request_count,
            time_window = "minute"
        }
    }
    
    -- Call OPA
    local httpc = http.new()
    httpc:set_timeout(5000) -- 5 second timeout
    
    local res, err = httpc:request_uri("http://opa:8181/v1/data/api/security/decision", {
        method = "POST",
        body = json.encode(opa_input),
        headers = {
            ["Content-Type"] = "application/json"
        }
    })
    
    if not res then
        ngx.log(ngx.ERR, "Failed to call OPA: ", err)
        return false, "OPA service unavailable"
    end
    
    if res.status ~= 200 then
        ngx.log(ngx.ERR, "OPA returned status: ", res.status)
        return false, "OPA error: " .. res.status
    end
    
    local decision = json.decode(res.body)
    
    -- Extract decision from OPA response
    local result = decision.result
    if not result then
        ngx.log(ngx.ERR, "No result in OPA response")
        return false, "Invalid OPA response"
    end
    
    -- Set headers for logging
    ngx.header["X-OPA-Decision"] = json.encode(result)
    ngx.header["X-OPA-Reason"] = result.reason or "No reason provided"
    
    -- Return decision
    return result.request_valid == true, result.reason or "Request denied"
end

-- Main execution
local allowed, reason = call_opa_policy()

if not allowed then
    ngx.status = 403
    ngx.say(json.encode({
        error = "Access denied",
        reason = reason
    }))
    ngx.exit(403)
end

-- If we get here, the request is allowed
ngx.exit(200)