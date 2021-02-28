local obj = {}
obj.__index = obj

-- Metadata
obj.name = "jira-issues"
obj.version = "1.0"
obj.author = "Pavel Makhov"
obj.homepage = "https://github.com/fork-my-spoons/jira-issues.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.indicator = nil
obj.timer = nil
obj.jira_host = nil
obj.jql = 'assignee=currentuser()+AND+resolution=Unresolved&fields=id,assignee,summary,status'
obj.jira_menu = {}
obj.icon_type = nil
obj.iconPath = hs.spoons.resourcePath("icons")

local auth_header

local function show_warning(status, body)
    hs.notify.new(function() end, {
        autoWithdraw = false,
        title = 'Jira Spoon',
        informativeText = string.format('Received status: %s\nbody:%s', status, string.sub(body, 1, 400))
    }):send()
end

local user_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#8e8e8e'}})
local ticket_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#8e8e8e'}})

local function styledText(text)
    return hs.styledtext.new(text, {color = {hex = '#8e8e8e'}})
end

local function updateMenu()
    local jira_url = obj.jira_host .. '/rest/api/2/search?jql=' .. obj.jql
    hs.http.asyncGet(jira_url, {Authorization = auth_header}, function(status, body)
        obj.jira_menu = {}

        if status ~=200 then
            show_warning(status, body)
            return
        end
        
        local issues = hs.json.decode(body).issues
        obj.indicator:setTitle(#issues)
    
        table.sort(issues, function(left, right) return left.fields.status.name < right.fields.status.name end)
    
        local cur_status = ''
        for _, issue in ipairs(issues) do
            if cur_status ~= issue.fields.status.name then
                table.insert(obj.jira_menu, { title = '-'})
                table.insert(obj.jira_menu, { title = issue.fields.status.name, disabled = true})
                cur_status = issue.fields.status.name
            end
            
            local avatar = (issue.fields.assignee == nil)
                and hs.image.imageFromPath(obj.iconPath .. '/unassigned.png')
                or hs.image.imageFromURL(issue.fields.assignee.avatarUrls['32x32'])
            local assignee_name = (issue.fields.assignee == nil)
                and styledText('Unassigned')
                or styledText(issue.fields.assignee.displayName)
            
            local transitions_url = obj.jira_host .. '/rest/api/2/issue/' .. issue.key .. '/transitions'
            
            local transitions_submenu = {}
            hs.http.asyncGet(transitions_url, {Authorization = auth_header}, function(status, body)

                if status ~= 200 then
                    show_warning(status, body)
                else
                    local transitions = hs.json.decode(body).transitions
                    for _, transition in ipairs(transitions) do
                        local transition_payload = string.format([[{ "transition": { "id": "%s" } }]], transition.id)
                        local header = {Authorization = auth_header}
                        header['content-type'] = 'application/json'
                        table.insert(transitions_submenu, {
                            image = hs.image.imageFromURL(transition.to.iconUrl):setSize({w=16,h=16}),
                            title = transition.name,
                            fn = function() hs.http.asyncPost(transitions_url, transition_payload, header, function(status, body) 
                                if status ~= 204 then
                                    show_warning(status, body)
                                end
                                updateMenu() end) 
                            end
                        })
                    end
                end
            end)

            table.insert(obj.jira_menu, {
                image = avatar,
                title = hs.styledtext.new(' ' .. issue.fields.summary .. '\n')
                    .. ticket_icon .. styledText(issue.key .. '   ')
                    .. user_icon .. assignee_name,
                menu = transitions_submenu,
                fn = function() os.execute(string.format('open %s/browse/%s', obj.jira_host, issue.key)) end
            })
        end
        
        table.insert(obj.jira_menu, { title = '-'})
        table.insert(obj.jira_menu, { title = 'Refresh', fn = function() updateMenu() end})
    end)
end

function obj:buildMenu()
    local ret = {}
    for _,v in ipairs(obj.jira_menu) do 
        table.insert(ret, v)
    end

    return ret
end

function obj:init()
    self.indicator = hs.menubar.new()
    self.indicator:setIcon(hs.image.imageFromPath(obj.iconPath .. '/jira-mark-gradient-blue.png'):setSize({w=16,h=16}), true)
    obj.indicator:setMenu(self.buildMenu)

    self.timer = hs.timer.new(300, updateMenu)
end

function obj:setup(args)
    self.jira_host = args.jira_host
    auth_header = 'Basic ' .. hs.base64.encode(string.format('%s:%s', args.login, args.api_token))
    if args.jql ~= nil then obj.jql = hs.http.encodeForQuery(args.jql) .. '&fields=id,assignee,summary,status' end
end

function obj:start()
    self.timer:fire()
    self.timer:start()
end


return obj