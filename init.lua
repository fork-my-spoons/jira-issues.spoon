local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Spoonira"
obj.version = "1.0"
obj.author = "Pavel Makhov"
obj.homepage = "https://github.com/streetturtle/spoonify"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.indicator = nil
obj.timer = nil
obj.jira_host = nil
obj.jql = 'assignee=currentuser()+AND+resolution=Unresolved&fields=id,assignee,summary,status'
obj.login = nil
obj.passowrd = nil

obj.iconPath = hs.spoons.resourcePath("icons")

local function show_warning(status, body)
    hs.alert(string.format('Jira spoon Error: received status: %s error message: %s', status, body))
end

local user_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#8e8e8e'}})
local ticket_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#8e8e8e'}})

local function styledText(text)
    return hs.styledtext.new(text, {color = {hex = '#8e8e8e'}})
end

local function updateMenu()
    local jira_url = obj.jira_host .. '/rest/api/2/search?jql=' .. obj.jql
    hs.http.asyncGet(jira_url, {Authorization = 'Basic ' .. hs.base64.encode(string.format('%s:%s', obj.login, obj.password))}, function(status, body) 
        if status ~=200 then
            show_warning(status, body)
            return
        end
        
        local issues = hs.json.decode(body).issues
        obj.indicator:setTitle(#issues)
        local jira_menu = {}
    
        table.sort(issues, function(left, right) return left.fields.status.name < right.fields.status.name end)
    
        local cur_status = ''
        for _, issue in ipairs(issues) do
            if cur_status ~= issue.fields.status.name then
                table.insert(jira_menu, { title = '-'})
                table.insert(jira_menu, { title = issue.fields.status.name, disabled = true})
                cur_status = issue.fields.status.name
            end
            
            local avatar = (issue.fields.assignee == nil)
                and hs.image.imageFromPath(obj.iconPath .. '/unassigned.png')
                or hs.image.imageFromURL(issue.fields.assignee.avatarUrls['32x32'])
            local assignee_name = (issue.fields.assignee == nil)
                and styledText('Unassigned')
                or styledText(issue.fields.assignee.displayName)
            
                table.insert(jira_menu, {
                image = avatar,
                title = hs.styledtext.new(' ' .. issue.fields.summary .. '\n')
                .. ticket_icon .. styledText(issue.key .. '   ')
                .. user_icon .. assignee_name,
                fn = function() os.execute(string.format('open %s/browse/%s', obj.jira_host, issue.key)) end
            })
        end
        
        table.insert(jira_menu, { title = '-'})
        table.insert(jira_menu, { title = 'Refresh', fn = function() updateMenu() end})

        obj.indicator:setMenu(jira_menu)
    end)
end


function obj:init()
    self.indicator = hs.menubar.new()
    self.indicator:setIcon(hs.image.imageFromPath(obj.iconPath .. '/jira-mark-gradient-blue.png'):setSize({w=16,h=16}), false)

    self.timer = hs.timer.new(300, updateMenu)
end

function obj:setup(args)
    self.jira_host = args.jira_host
    self.login = args.login
    self.password = args.password
    if args.jql ~= nil then obj.jql = hs.http.encodeForQuery(args.jql) .. '&fields=id,assignee,summary,status' end
end

function obj:start()
    self.timer:fire()
    self.timer:start()
end


return obj