# Slack Api and Utils

Utilities to interact with Slack's [Web API](https://api.slack.com/methods) and 
[Events API](https://api.slack.com/events), and to compose messages formatted in 
[mrkdwn](https://api.slack.com/reference/surfaces/formatting).  

## Configurations
To use the library, you first need to create a Slack app, install it in your workspace.  

1. [Create a Slack app](https://api.slack.com/apps?new_app=1).  

2. Click "Install to Workspace", and when prompted to grant permissions to your workspace, click "Allow".  

3. Set up **Web API** from [here](https://api.slack.com/web), click on 
"OAuth & Permissions" in your app dashboard's sidebar. Give your bot a *Bot Token 
Scope* for your intended API usages. 
Copy the generated bot token (`xoxb-XXXX`) to the `slack_access_token` field of your 
secrets file. This token is used by the bot to authenticate to the workspace, and 
remains valid until the token is revoked or the app is uninstalled.  

4. To receive events you need to configure webhook for receiving messages from 
[here](https://api.slack.com/apis/connections/events-api). 
NB: During the [url verification handshake](https://api.slack.com/events-api#the-events-api__subscribing-to-event-types__events-api-request-urls__request-url-configuration--verification__url-verification-handshake), you should tell Slack to direct event 
notifications to a path `<server_domain>/path/to/events/handler` where you can use 
our `process_slack_event` [handler](./lib/utils.ml). Ensure the server is running 
before triggering the handshake.  

You need to provide a path for a `secrets.json` file that contains the bot's Slack 
access token for your app when you initializing the [context](./lib/context.ml) (an 
example in [echo.ml](./examples/echo.ml#28):  
```json
{
    "slack_access_token": "xoxb-..."
}
```

## APIs Implemented
The interface for the APIs are in [api.ml](./lib/api.ml).  To use these APIs please 
include the required [scopes](https://api.slack.com/scopes) for the bot token.

## Utils Implemented
Some common utilities that help with simple tasks in [utils.ml](./lib/utils.ml).  

## Examples
Rather than having automated CI tests which would require a lot of dependencies on 
live servers and apps, we have examples for you to configure and run on your own 
(which we also use to debug our remote capabilities).  

Included in the examples are:  
1. a simple [echo server](./examples/echo.ml) where you can chat with the bot (on 
any channel it's added to or direct messages if you enable it) and the bot will echo 
your message.  You need to go through the same configuration steps above to run the 
examples and for the verification path during Slack event subscription 
`<server_domain>/events`.  This example further include link unfurling when the user send 
a link to it.  

You can run the binary to listen to your Slack events webhook on TCP port 8080 using:  
```sh
./example echo
```

2. Sending direct API requests such as:  
```sh
# send "hello there" to channel1
./example send -c channel1 -t 'hello there'
# send as username "WOW" with emoji thumb's up
./example send -u "WOW" --ie=":+1:" -t "hello there" -c channel1

# send "hello there" as a snippet to channel1
/example send_file --channel="channel1" --text='hello there'

# send "hello there" to channel1 then updating the message to say 'general kenobi'
./example send_update --channel="channel1" --text='hello there' --update='general kenobi'

./example get_user -u U046XN0M2R5

./example get_convo -c C049XFXK286

./example get_replies -c D049WPTCGMC --ts "1675329533.687169"

./example join_convo -c C04NLK6F9KJ

./example update_usergroup_users --ug S04NV4DF0LQ --us "U046XN0M2R5, U04D7HU80BT"
#etc
```

## Development

### Overview

The signature for the APIs are in [api.ml](./lib/api.ml) with its implementation that calls the Slack API in [api_remote.ml](./lib/api_remote.ml) and local mock implementation in [api_local.ml](./lib/api_local.ml).  

The payloads to send are defined as types using ATD in [slack.atd](./lib/slack.atd) as `<API name>_req` and the response is parsed as types `<API name>_res`.  The [atd_adapters.ml](./lib/atd_adapters.ml) file defines how the Slack API responses are parsed as success/failure.  

### Testing

The [test.ml](./lib_test/test.ml) file defines simple test cases for running the utils and making sure the return object is correctly parsed by our ATD.  To add a case, add to any of the existing list of cases or start a new list for a new API/utils.  

If your test requires caches from the Slack API (useful to test ATD), add the JSON return value as a file in the [slack-api-cache](./lib_test/slack-api-cache) directory.  
