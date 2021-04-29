# Jira Menu Bar App

<p align="center">
   <a href="https://github.com/fork-my-spoons/jira-issues.spoon/issues">
    <img alt="GitHub issues" src="https://img.shields.io/github/issues/fork-my-spoons/jira-issues.spoon">
  </a>
  <a href="https://github.com/fork-my-spoons/jira-issues.spoon/releases">
    <img alt="GitHub all releases" src="https://img.shields.io/github/downloads/fork-my-spoons/jira-issues.spoon/total">
  </a>
</p>

Shows a list of Jira tickets assigned to a user and grouped by a status. It's also possible to transition selected ticket to a different status.

<p align="center">
  <img src="https://github.com/fork-my-spoons/jira-issues.spoon/raw/main/screenshots/jira.png"/>
</p>

By default it shows a list of tickets returned by a following JQL: 

```assignee=currentuser() AND resolution=Unresolved```

In order to show a different list (for example issues from the backlog or issues with a label) go to Jira's advanced search, construct a query and use it in the app's config.

# Installation

 - install [Hammerspoon](http://www.hammerspoon.org/) - a powerfull automation tool for OS X
   - Manually:

      Download the [latest release](https://github.com/Hammerspoon/hammerspoon/releases/latest), and drag Hammerspoon.app from your Downloads folder to Applications.
   - Homebrew:

      ```brew install hammerspoon --cask```

 - download [jira-issues.spoon](https://github.com/fork-my-spoons/jira-issues.spoon/releases/latest/download/jira-issues.spoon.zip), unzip and double click on a .spoon file. It will be installed under `~/.hammerspoon/Spoons` folder.
 
 - open ~/.hammerspoon/init.lua and add the following snippet, with your parameters:
 
```lua
-- JIRA
hs.loadSpoon('jira-issues')
spoon['jira-issues']:setup({
    jira_host = 'https://jira.tmnt.ca',
    login = 'mikey',
    api_token = 'cowabunga123',   
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
    api_token = 'cowabunga123',
    jql = 'project = TMNT AND status = Open AND assignee in (EMPTY)'
})
spoon['jira-issues']:start()
```

Here is atlassian documentation on how to get an API token: [Manage API tokens for your Atlassian account](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/). In case you are using an old version of Jira, simply put your password instead of an API token.  
This app uses icons, to properly display them, install a [feather-font](https://github.com/AT-UI/feather-font) by [downloading](https://github.com/AT-UI/feather-font/raw/master/src/fonts/feather.ttf) this .ttf font and installing it.
