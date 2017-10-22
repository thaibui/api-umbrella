local date = require "date"

local epoch = date.epoch()

local _M = {}

function _M.format(parsed)
  local result
  if type(parsed) == "table" and parsed.fmt then
    result = parsed:fmt("${iso}Z")
  end

  return result
end

function _M.to_timestamp(parsed)
  local result
  if type(parsed) == "table" and parsed.fmt then
    result = (parsed - epoch):spanseconds()
  end

  return result
end

function _M.postgres_to_timestamp(time)
  local parsed
  if type(time) == "string" then
    parsed = _M.parse_postgres(time)
  end

  return _M.to_timestamp(parsed)
end

function _M.format_postgres(time)
  local parsed
  if type(time) == "string" then
    parsed = _M.parse_postgres(time)
  elseif type(time) == "number" then
    parsed = _M.parse_timestamp(time)
  end

  return _M.format(parsed)
end

function _M.format_timestamp(time)
  local parsed
  if type(time) == "number" then
    parsed = _M.parse_timestamp(time)
  end

  return _M.format(parsed)
end

function _M.parse_timestamp(time)
  local parsed
  if type(time) == "number" then
    parsed = date(time)
  end

  return parsed
end

function _M.parse_postgres(time)
  local parsed
  if time then
    local matches, match_err = ngx.re.match(time, [[^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}(\.\d+)?)(([\-\+]\d{2})(:(\d{2}))?)?$]], "jo")
    if matches then
      local year = tonumber(matches[1])
      local month = tonumber(matches[2])
      local day = tonumber(matches[3])
      local hour = tonumber(matches[4])
      local min = tonumber(matches[5])
      local sec = tonumber(matches[6])
      local tz_hour = tonumber(matches[9])
      local tz_min = tonumber(matches[11])

      parsed = date(year, month, day, hour, min, sec)

      if tz_hour then
        local tz_sec = tz_hour * 60 * 60
        if tz_min then
          local tz_min_sec = tz_min * 60
          if tz_hour < 0 then
            tz_sec = tz_sec - tz_min_sec
          else
            tz_sec = tz_sec + tz_min_sec
          end
        end

        parsed:addseconds(-1 * tz_sec)
      end
    elseif match_err then
      ngx.log(ngx.ERR, "regex error: ", match_err)
    end
  end

  return parsed
end

return _M