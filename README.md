# Jira Menu Bar App

Shows a list of Jira tickets grouped by a status which are assigned to a user:

<p align="center">
  <img src="https://github.com/fork-my-spoons/jira-issues.spoon/raw/main/screenshots/jira.png"/>
</p>

By default it shows a list of tickets returned by a following JQL: 

```assignee=currentuser() AND resolution=Unresolved```

In order to show a different list (for example issues from the backlog or issues with a label) go to Jira's advanced search, construct a query and use it in the app's config.

# Installation

 - install [Hammerspoon](http://www.hammerspoon.org/) - a powerfull automation tool for OS X
   - Manually:

      Download the [latest release], and drag Hammerspoon.app from your Downloads folder to Applications.
   - Homebrew:

      ```brew install hammerspoon --cask```

 - download [jira-issues.spoon](https://github.com/fork-my-spoons/jira-issues.spoon/raw/main/jira-issues.spoon.zip), unzip and double click on a .spoon file. It will be installed under `~/.hammerspoon/Spoons` folder.
 
 - open ~/.hammerspoon/init.lua and add the following snippet, with your parameters:
 
```lua
-- JIRA
hs.loadSpoon('jira-issues')
spoon['jira-issues']:setup({
    jira_host = 'https://jira.tmnt.ca',
    login = 'mikey',
    password = 'cowabunga123',   
})
spoon['jira-issues']:start()
```

or, if you want to have a custom list of issues:

```lua
-- JIRA
hs.loadSpoon('jira-issues')
spoon['jira-issues']:setup({
    jira_host = 'https://jira.tmnt.ca',
    login = 'mikey',
    password = 'cowabunga123',
    jql = 'project = TMNT AND status = Open AND assignee in (EMPTY)'
})
spoon['jira-issues']:start()
```

This app uses icons, to properly display them, install a [feather-font](https://github.com/AT-UI/feather-font) by [downloading](https://github.com/AT-UI/feather-font/raw/master/src/fonts/feather.ttf) this .ttf font and installing it.
