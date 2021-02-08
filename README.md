# Jira Menu Bar App

Shows Jira tickets assigned to a user. Could be customized to show a list of ticket for a given JQL.

# Installation

 - download and install [Hammerspoon](https://github.com/Hammerspoon/hammerspoon/releases/latest)
 - download and install [Jira Spoon]()
 - open ~/.hammerspoon/init.lua and add following snippet:

```lua
-- JIRA
hs.loadSpoon("jira")
spoon.jira:setup({
    jira_host = 'https://jira.tmnt.ca',
    login = 'mikey',
    password = 'cowabunga123',
    jql = 'project = tmnt'
})
spoon.jira:start()
```

This app uses icons, to properly display them, install a [feather-font](https://github.com/AT-UI/feather-font) by [downloading](https://github.com/AT-UI/feather-font/raw/master/src/fonts/feather.ttf1) this .ttf font and installing it.