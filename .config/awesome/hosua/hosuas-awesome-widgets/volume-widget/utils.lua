

local utils = {}

local function split(string_to_split, separator)
    if separator == nil then separator = "%s" end
    local t = {}

    for str in string.gmatch(string_to_split, "([^".. separator .."]+)") do
        table.insert(t, str)
    end

    return t
end

function utils.extract_sinks_and_sources(output, use_pactl)
    local sinks = {}
    local sources = {}
    local device
    local properties
    local ports
    local in_sink = false
    local in_source = false
    local in_device = false
    local in_properties = false
    local in_ports = false
    
    use_pactl = use_pactl or false
    
    -- Get default sink and source names (only for pactl)
    local default_sink_name = nil
    local default_source_name = nil
    if use_pactl then
        local handle = io.popen("pactl get-default-sink 2>/dev/null")
        if handle then
            default_sink_name = handle:read("*a"):gsub("%s+", "")
            handle:close()
        end
        handle = io.popen("pactl get-default-source 2>/dev/null")
        if handle then
            default_source_name = handle:read("*a"):gsub("%s+", "")
            handle:close()
        end
    end
    
    for line in output:gmatch("[^\r\n]+") do
        if use_pactl and string.match(line, '^Source #') then
            in_sink = false
            in_source = true
            in_device = true
            in_properties = false
            local id = line:match('Source #(%d+)')
            device = {
                id = id,
                is_default = false
            }
            table.insert(sources, device)
        elseif use_pactl and string.match(line, '^Sink #') then
            in_sink = true
            in_source = false
            in_device = true
            in_properties = false
            local id = line:match('Sink #(%d+)')
            device = {
                id = id,
                is_default = false
            }
            table.insert(sinks, device)
        elseif string.match(line, 'source%(s%) available.') then
            in_sink = false
            in_source = true
        elseif string.match(line, 'sink%(s%) available.') then
            in_sink = true
            in_source = false
        elseif string.match(line, 'index:') then
            in_device = true
            in_properties = false
            device = {
                id = line:match(': (%d+)'),
                is_default = string.match(line, '*') ~= nil
            }
            if in_sink then
                table.insert(sinks, device)
            elseif in_source then
                table.insert(sources, device)
            end
        end

        if string.match(line, '^\tproperties:') then
            in_device = false
            in_properties = true
            properties = {}
            device['properties'] = properties
        end

        if string.match(line, 'ports:') then
            in_device = false
            in_properties = false
            in_ports = true
            ports = {}
            device['ports'] = ports
        end

        if string.match(line, 'active port:') then
            in_device = false
            in_properties = false
            in_ports = false
            device['active_port'] = line:match(': (.+)'):gsub('<',''):gsub('>','')
        end

        if in_device then
            if use_pactl and string.match(line, '^\tName:') then
                local name = line:match('Name: (.+)')
                if name then
                    device.name = name:gsub("^%s+", ""):gsub("%s+$", "")
                    if in_sink and default_sink_name and device.name == default_sink_name then
                        device.is_default = true
                    elseif in_source and default_source_name and device.name == default_source_name then
                        device.is_default = true
                    end
                end
            elseif use_pactl and string.match(line, '^\tDescription:') then
                local desc = line:match('Description: (.+)')
                if desc then
                    if not device.properties then
                        device.properties = {}
                    end
                    device.properties.device_description = desc:gsub("^%s+", ""):gsub("%s+$", "")
                end
            else
                local t = split(line, ': ')
                local key = t[1]:gsub('\t+', ''):lower()
                local value = t[2]
                if value then
                    value = value:gsub('^<', ''):gsub('>$', '')
                    device[key] = value
                end
            end
        end

        if in_properties then
            local t = split(line, '=')
            local key = t[1]:gsub('\t+', ''):gsub('%.', '_'):gsub('-', '_'):gsub(':', ''):gsub("%s+$", "")
            local value
            if t[2] == nil then
                value = t[2]
            else
                value = t[2]:gsub('"', ''):gsub("^%s+", ""):gsub(' Analog Stereo', '')
            end
            properties[key] = value
        end

        if in_ports then
            local t = split(line, ': ')
            local key = t[1]
            if key ~= nil then
                key = key:gsub('\t+', '')
            end
            ports[key] = t[2]
        end
    end

    return sinks, sources
end

return utils