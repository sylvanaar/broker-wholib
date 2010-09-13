local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local WhoLib = LibStub and LibStub:GetLibrary('LibWho-2.0', true)
if not LDB or not WhoLib then
    return
end

local AppName = "Broker_WhoLib"
local Icon = [[Interface\AddOns\]] .. AppName .. [[\icon.tga]]

local tmp = {}
local QueueNames = {
        ' USER',
        ' QUIET',
        ' SCANNING',
}

local function sortCache(a, b)
    a, b = WhoLib.Cache[a], WhoLib.Cache[b]
    if a == nil or b == nil then
        return b ~= nil
    end
    if a.inqueue ~= b.inqueue then
        return a.inqueue
    end
    return (a and a.last or 0) > (b and b.last or 0)
end

local function getTimeInMinutes(since)
	if since == nil then
        return "0"
    end
	local minutes = (time()-since) / 60
	if minutes < 1 then
        return "< 1"
    end
	return tostring(math.floor(minutes))
end

local tooltip = CreateFrame("GameTooltip", AppName .. "_Tooltip", UIParent)
function tooltip:OnShow()
    WhoLib:UpdateWeights()
    self:ClearLines()
    self:AddLine('|cff00ff00WhoLib Queues:|r')
    for num, name in ipairs(QueueNames) do
        self:AddLine('|cffffff00' .. name .. '|r (' .. (math.floor(WhoLib.queue_bounds[num]*100)) .. '% chance)')
        if(#WhoLib.Queue[num] == 0) then
            self:AddLine('|cff888888empty|r')
        else
            for _, v in ipairs(WhoLib.Queue[num]) do
                local text
                if v.info then
                    text = 'UserInfo: ' .. v.info
                elseif v.gui then
                    text = 'WhoFrame: ' .. v.query
                elseif num == 1 then
                    text = 'Console: ' .. v.query
                else
                    text = 'Who: ' .. v.query
                end
                self:AddLine(text)
            end
        end
    end

    wipe(tmp)
    for k, v in pairs(WhoLib.Cache) do
        tmp[#tmp+1] = k
    end

    if #tmp == 0 then
        self:AddLine('|cff00ff00WhoLib Cache:|r')
        self:AddLine('|cff888888empty|r')
    else
        self:AddLine(('|cff00ff00WhoLib Cache: %s entries|r'):format(tostring(#tmp)))
        table.sort(tmp, sortCache)
        local data
        for i, name in ipairs(tmp) do
            data = WhoLib.Cache[name]
            tmp[i] = nil
            if data.inqueue then
                self:AddLine(('%s : |cff8888FFquerying... (%s min)|r'):format(name, getTimeInMinutes(data.last)))
            else
                if data.valid then
                    if data.data.Online then
                        local sex = data.data.Sex and (data.data.Sex==2 and MALE or FEMALE) or ""
                        self:AddLine(('%s : |cff88FF88%s - %s %s  (%s min)|r'):format(name, tostring(data.data.Level), sex, tostring(data.data.Class), getTimeInMinutes(data.last)))
                    else
                        local status = data.Online == nil and "not found" or "offline"
                        self:AddLine(('%s : |cff88FF88%s  (%s min)|r'):format(name, status, getTimeInMinutes(data.last)))
                    end
                else
                    self:AddLine(('%s : |cff888888no info|r'):format(name))
                end
            end
        end
    end
end

local BWL = {
    type = "data source",
    label = AppName,
    text = "",
    icon = Icon,
    tooltip = tooltip,
}

local function update()
    local queries = 0
    for k in pairs(WhoLib.CacheQueue) do
         queries = queries + 1
    end

    BWL.text = #WhoLib.Queue[1] .. '/' .. #WhoLib.Queue[2] .. '/' .. #WhoLib.Queue[3] .. ":" .. queries .. (WhoLib.WhoInProgress and " ? " or " - ") .. WhoLib:GetQueryInterval() .. "s"
    if tooltip:IsShown() then
        tooltip:OnShow()
    end
end

BWL.OnClick = function(frame, button)
    if button == "LeftButton" then
        WhoLib:SetWhoLibDebug(not WhoLib:GetWhoLibDebug())
    elseif button == "RightButton" then
        WhoLib:Reset()
        update()
    end
end

WhoLib.RegisterCallback(BWL, 'WHOLIB_QUERY_ADDED', update)
WhoLib.RegisterCallback(BWL, 'WHOLIB_QUERY_RESULT', update)
LDB:NewDataObject(AppName, BWL)
