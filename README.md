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
The interface for the APIs are in [api.ml](./lib/api.ml).  
| Function                                          | Slack API                                                                                                                                                                                             | Scope                                                                                                                                                                                                                                              | Description                                                                              |
|---------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| `send_message context message_req`                | [chat.postMessage](https://api.slack.com/methods/chat.postMessage)                                                                                                                                    | [chat:write](https://api.slack.com/scopes/chat:write)                                                                                                                                                                                              | Sends a message to a particular channel.                                                 |
| `update_message context update_message_req`       | [chat.update](https://api.slack.com/methods/chat.update)                                                                                                                                              | [chat:write](https://api.slack.com/scopes/chat:write)                                                                                                                                                                                              | Update a message in a particular channel at a timestamp.                                 |
| `upload_file context files_req`                   | [files.upload](https://api.slack.com/methods/files.upload)                                                                                                                                            | [files:write](https://api.slack.com/scopes/files:write)                                                                                                                                                                                            | Upload a file and share it to some specified channel(s).                                 |
| `get_conversations_info context conversation_req` | [conversations.info](https://api.slack.com/methods/conversations.info)                                                                                                                                | [channels:read](https://api.slack.com/scopes/channels:read), [groups:read](https://api.slack.com/scopes/groups:read), [im:read](https://api.slack.com/scopes/im:read),  [mpim:read](https://api.slack.com/scopes/mpim:read)                        | Get a conversation information using its channel ID.                                     |
| `get_user context user_req`                       | [users.info](https://api.slack.com/methods/users.info)                                                                                                                                                | [users:read](https://api.slack.com/scopes/users:read)                                                                                                                                                                                              | Get a user information using their user ID.                                              |
| `send_auth_test context ()`                       | [Event Subscription URL Verification](https://api.slack.com/apis/connections/events-api#the-events-api__subscribing-to-event-types__events-api-request-urls__request-url-configuration--verification) |                                                                                                                                                                                                                                                    | Use during subscribing to event hooks, as Slack needs to verify that you own the server. |
| `send_chat_unfurl context req`                    | [chat.unfurl](https://api.slack.com/methods/chat.unfurl)                                                                                                                                              | [links:write](https://api.slack.com/scopes/links:write)                                                                                                                                                                                            | Unfurl a `link_shared` event.                                                            |
| `get_replies context conversation_req`            | [conversations.replies](https://api.slack.com/methods/conversations.replies)                                                                                                                          | [channels:history](https://api.slack.com/scopes/channels:history), [groups:history](https://api.slack.com/scopes/groups:history), [im:history](https://api.slack.com/scopes/im:history), [mpim:history](https://api.slack.com/scopes/mpim:history) | Get replies of a conversation thread.                                                    |
| `join_conversation context channel_req`           | [conversations.join](https://api.slack.com/methods/conversations.join)                                                                                                                                | [channels:join](https://api.slack.com/scopes/channels:join)                                                                                                                                                                                        | Make the token owner join a channel.                                                     |
| `update_usergroup_users context usergroup_req`    | [usergroups.users.update](https://api.slack.com/methods/usergroups.users.update)                                                                                                                      | [usergroups:write](https://api.slack.com/scopes/usergroups:write)                                                                                                                                                                                  | Update members of a usergroup with the current users list.                               |

NB: the scopes might change, so please refer to the API page and update this table.

## Utils Implemented
Some common utilities that help with simple tasks in [utils.ml](./lib/utils.ml):  

1. empty requests payloads: help with quickly writing different payloads, a default 
empty payload is created for all the API calls.  

2. `send_text_msg context channel text`: simple text message sending to a channel.  

3. `update_text_msg context channel update_text timestamp`: update a message in some 
channel at a timestamp with a simple text.  

4. `validate_signature version signing_key headers body`: validating the token in a Slack 
event.  

5. `process_slack_event context headers body event_handler`: correctly respond to Slack 
event API verification request and validate other incoming payload from Slack before passing 
the verified payload to the event handler.  

6. `get_channel_type context channel`: check if channel is a Slack channel, direct message, 
or group.  

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

2. sending a message:   
```sh
# send "hello there" to channel1
./example send -c channel1 -t 'hello there'
# send as username "WOW" with emoji thumb's up
./example send -u "WOW" --ie=":+1:" -t "hello there" -c channel1
```

3. uploading a file:  
```sh
# send "hello there" as a snippet to channel1
/example send_file --channel="channel1" --text='hello there'
```
4. sending a message then updating it after 3 seconds:  
```sh
# send "hello there" to channel1 then updating the message to say 'general kenobi'
./example send_update --channel="channel1" --text='hello there' --update='general kenobi'
```
5. get a user info:  
```sh
./example get_user -u U046XN0M2R5
```
6. get a channel info:  
```sh
./example get_convo -c C049XFXK286
```

7. get a conversation's replies info:  
```sh
./example get_replies -c D049WPTCGMC --ts "1675329533.687169"
```

8. join a conversation:
```sh
./example join_convo -c C04NLK6F9KJ
```

9. update a usergroup users:
```sh
./example update_usergroup_users --ug S04NV4DF0LQ --us "U046XN0M2R5, U04D7HU80BT"
```

## Development

### Overview

The signature for the APIs are in [api.ml](./lib/api.ml) with its implementation that calls the Slack API in [api_remote.ml](./lib/api_remote.ml) and local mock implementation in [api_local.ml](./lib/api_local.ml).  

The payloads to send are defined as types using ATD in [slack.atd](./lib/slack.atd) as `<API name>_req` and the response is parsed as types `<API name>_res`.  The [atd_adapters.ml](./lib/atd_adapters.ml) file defines how the Slack API responses are parsed as success/failure.  

### Testing

The [test.ml](./lib_test/test.ml) file defines simple test cases for running the utils and making sure the return object is correctly parsed by our ATD.  To add a case, add to any of the existing list of cases or start a new list for a new API/utils.  

If your test requires caches from the Slack API (useful to test ATD), add the JSON return value as a file in the [slack-api-cache](./lib_test/slack-api-cache) directory.  
