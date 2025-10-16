local obj = {}
obj.__index = obj

-- Metadata
obj.name = "jira-issues"
obj.version = "1.3"
obj.author = "Pavel Makhov"
obj.homepage = "https://github.com/fork-my-spoons/jira-issues.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.indicator = nil
obj.timer = nil
obj.jira_host = nil
obj.jql = 'assignee=currentuser() AND resolution=Unresolved'
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
    local jira_url = obj.jira_host .. '/rest/api/3/search/jql?jql=' .. hs.http.encodeForQuery(obj.jql) .. '&fields=id,assignee,summary,status'
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
                or hs.image.imageFromURL(issue.fields.assignee.avatarUrls['32x32']):setSize({w=32,h=32})
            local assignee_name = (issue.fields.assignee == nil)
                and styledText('Unassigned')
                or styledText(issue.fields.assignee.displayName)
            
            local transitions_url = obj.jira_host .. '/rest/api/3/issue/' .. issue.key .. '/transitions'
            
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
        
        table.insert(obj.jira_menu, { title = '-' })
        table.insert(obj.jira_menu, { 
            image = hs.image.imageFromName('NSTouchBarSearchTemplate'),
            title = 'Open filter', 
            fn = function() 
                os.execute(string.format('open "%s/issues/?jql=%s"', obj.jira_host, hs.http.encodeForQuery(obj.jql))) 
            end})
        table.insert(obj.jira_menu, { 
            image = hs.image.imageFromName('NSAddTemplate'), 
            title = 'Create issue', 
            fn = function() os.execute(string.format('open %s/secure/CreateIssue.jspa', obj.jira_host)) end
        })
        table.insert(obj.jira_menu, { title = '-' })
        table.insert(obj.jira_menu, { 
            image = hs.image.imageFromName('NSRefreshTemplate'), 
            title = 'Refresh', 
            fn = function() updateMenu() end
        })
        table.insert(obj.jira_menu, { 
            image = hs.image.imageFromName('NSTouchBarDownloadTemplate'), 
            title = 'Check for updates', 
            fn = function() obj:check_for_updates() end})
    end)
end

function obj:check_for_updates()
    local release_url = 'https://api.github.com/repos/fork-my-spoons/jira-issues.spoon/releases/latest'
    hs.http.asyncGet(release_url, {}, function(status, body)
        local latest_release = hs.json.decode(body)
        latest = latest_release.tag_name:sub(2)
        
        if latest == obj.version then
            hs.notify.new(function() end, {
                autoWithdraw = false,
                title = 'Jira Issues Spoon',
                informativeText = "You have the latest version installed!"
            }):send()
        else
            hs.notify.new(function() 
                os.execute('open ' .. latest_release.assets[1].browser_download_url)
            end, 
            {
                title = 'Jira Issues Spoon',
                informativeText = "New version is available",
                actionButtonTitle = "Download",
                hasActionButton = true
            }):send()
        end
    end)
end

function obj:buildMenu()
    return obj.jira_menu
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
    if args.jql ~= nil then obj.jql = args.jql end
end

function obj:start()
    self.timer:fire()
    self.timer:start()
end


return obj