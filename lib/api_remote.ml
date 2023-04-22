(** The remote API call implementations that actually interacts with Slack *)

open ExtLib
open Printf
open Devkit
open Common

let log = Log.from "slack"

(*************************************** WWW FIELD HELPERS ***********************************)
let list_filter_opt = List.filter_map id

let bool_field_val field name =
  match field with
  | Some field_val -> Some (name, Bool.to_string field_val)
  | None -> None

let int_field_val field name =
  match field with
  | Some field_val -> Some (name, Int.to_string field_val)
  | None -> None

let string_field_val field name =
  match field with
  | Some field_val -> Some (name, field_val)
  | None -> None

(************************************ SLACK REQUEST HELPERS ********************************)
let slack_api_request ?ua ?headers ?body meth url read =
  match%lwt http_request ?ua ?headers ?body meth url with
  | Error e -> Lwt.return_error (`Other e)
  | Ok s -> Lwt.return @@ Slack_j.slack_response_of_string read s

let bearer_token_header access_token = sprintf "Authorization: Bearer %s" (Uri.pct_encode access_token)

let request_token_auth ~name ?headers ?body ~(ctx : Context.t) meth path read =
  log#info "%s: starting request" name;
  let headers = bearer_token_header (Context.get_slack_access_token ctx) :: Option.default [] headers in
  let url = sprintf "https://slack.com/api/%s" path in
  match%lwt slack_api_request ?body ~headers meth url read with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "%s: failure : %s" name (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

(** [send_message ctx msg] notifies [msg.channel] with the payload [msg];
      uses web API with access token *)
let send_message ~(ctx : Context.t) ~(msg : Slack_t.post_message_req) =
  log#info "sending to %s" msg.channel;
  let headers = [ bearer_token_header (Context.get_slack_access_token ctx) ] in
  let url = "https://slack.com/api/chat.postMessage" in
  let data = Slack_j.string_of_post_message_req msg in
  let body = `Raw ("application/json", data) in
  log#info "data to send in message to channel %s: %s" msg.channel data;
  match%lwt slack_api_request ~ua:ctx.ua ~body ~headers `POST url Slack_j.read_post_message_res with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "failed to send message: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

(** [update_message ctx msg] update [msg] at timestamp [msg.ts]
      in channel [msg.channel] with the payload [msg];
      uses web API with access token *)
let update_message ~(ctx : Context.t) ~(msg : Slack_t.update_message_req) =
  log#info "updating message at timestamp %s in channel %s" msg.ts msg.channel;
  let headers = [ bearer_token_header (Context.get_slack_access_token ctx) ] in
  let url = "https://slack.com/api/chat.update" in
  let data = Slack_j.string_of_update_message_req msg in
  let body = `Raw ("application/json", data) in
  log#info "data to update message in channel %s: %s" msg.channel data;
  match%lwt slack_api_request ~ua:ctx.ua ~body ~headers `POST url Slack_j.read_update_message_res with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "failed to update message: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

let www_form_of_files_upload_req (file : Slack_t.files_upload_req) =
  let fields =
    [
      string_field_val file.channels "channels";
      string_field_val file.content "content";
      string_field_val file.filename "filename";
      string_field_val file.filetype "filetype";
      string_field_val file.initial_comment "initial_comment";
      string_field_val file.thread_ts "thread_ts";
      string_field_val file.title "title";
    ]
  in
  list_filter_opt fields

(** [upload_file ctx file] upload [file] to channels noted in [file.channels]
      with content [file.content]; Not supporting file upload through form using
      `file` currently
      uses web API with access token *)
let upload_file ~(ctx : Context.t) ~(file : Slack_t.files_upload_req) =
  let headers = [ bearer_token_header (Context.get_slack_access_token ctx) ] in
  let url = "https://slack.com/api/files.upload" in
  let args = www_form_of_files_upload_req file in
  let data = Web.make_url_args args in
  let body = `Raw ("application/x-www-form-urlencoded", data) in
  log#info "data to upload file: %s" data;
  match%lwt slack_api_request ~ua:ctx.ua ~body ~headers `POST url Slack_j.read_files_upload_res with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "failed to upload file: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

(** [join_conversation ctx channel ] will join the token owner 
    [ctx.secrets.slack_access_token] to the [channel]. *)
let join_conversation ~(ctx : Context.t) ~(channel : Slack_t.conversations_join_req) =
  log#info "joining channel %s" channel.channel;
  let headers = [ bearer_token_header (Context.get_slack_access_token ctx) ]
  and url = "https://slack.com/api/conversations.join" in
  let data = Slack_j.string_of_conversations_join_req channel in
  let body = `Raw ("application/json", data) in
  match%lwt slack_api_request ~ua:ctx.ua ~body ~headers `POST url Slack_j.read_conversations_join_res with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "failed to join conversation %s: %s" channel.channel (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

(** [send_chat_unfurl ctx req] unfurls link (payload [link.unfurls]) in [req.channel] at [req.ts];
      uses web API with access token *)
let send_chat_unfurl ~(ctx : Context.t) ~(req : Slack_t.chat_unfurl_req) =
  let headers = [ bearer_token_header (Context.get_slack_access_token ctx) ] in
  let url = "https://slack.com/api/chat.unfurl" in
  let data = Slack_j.string_of_chat_unfurl_req req in
  let body = `Raw ("application/json", data) in
  log#info "link to unfurl message in channel %s: %s" req.channel data;
  match%lwt slack_api_request ~ua:ctx.ua ~body ~headers `POST url Slack_j.read_ok_res with
  | Ok (_res : Slack_t.ok_res) -> Lwt.return_ok ()
  | Error e ->
    log#warn "failed to send unfurl(s) for link(s) [%s] to channel %s: %s"
      (String.concat ";" (List.map (fun (x, _) -> x) req.unfurls))
      req.channel (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

(** [update_usergroup_users ctx usergroup ] will replace the current usergroups
    users with the list of users in [usergroup]. *)
let update_usergroup_users ~(ctx : Context.t) ~(usergroup : Slack_t.update_usergroups_users_req) =
  log#info "updating usergroup %s with users: [%s]" usergroup.usergroup (String.concat "; " usergroup.users);
  let headers = [ bearer_token_header (Context.get_slack_access_token ctx) ]
  and url = "https://slack.com/api/usergroups.users.update" in
  let data = Slack_j.string_of_update_usergroups_users_req usergroup in
  let body = `Raw ("application/json", data) in
  match%lwt slack_api_request ~ua:ctx.ua ~body ~headers `POST url Slack_j.read_update_usergroups_users_res with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "failed to update user group %s with users [%s]: %s" usergroup.usergroup
      (String.concat "; " usergroup.users) (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

let www_form_of_conversations_replies_req (conversation : Slack_t.conversations_replies_req) =
  let fields =
    [
      Some ("channel", conversation.channel);
      Some ("ts", conversation.ts);
      string_field_val conversation.cursor "cursor";
      bool_field_val conversation.include_all_metadata "include_all_metadata";
      bool_field_val conversation.inclusive "inclusive";
      string_field_val conversation.latest "latest";
      int_field_val conversation.limit "limit";
      string_field_val conversation.oldest "oldest";
    ]
  in
  list_filter_opt fields

let get_replies ~(ctx : Context.t) ~(conversation : Slack_t.conversations_replies_req) =
  log#info "getting replies from channel %s at ts: %s" conversation.channel conversation.ts;
  let headers = [ bearer_token_header (Context.get_slack_access_token ctx) ] in
  let url = "https://slack.com/api/conversations.replies" in
  let data = www_form_of_conversations_replies_req conversation in
  let args = Web.make_url_args data in
  let url = sprintf "%s?%s" url args in
  match%lwt slack_api_request ~ua:ctx.ua ~headers `GET url Slack_j.read_conversations_replies_res with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "failed to get replies from channel %s at %s: %s" conversation.channel conversation.ts
      (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

let www_form_of_conversations_info_req (conversation : Slack_t.conversations_info_req) =
  let fields =
    [
      Some ("channel", conversation.channel);
      bool_field_val conversation.include_locale "include_locale";
      bool_field_val conversation.include_num_members "include_num_members";
    ]
  in
  list_filter_opt fields

(** [get_conversations_info ctx conversation] gets the slack conversation info;
      uses web API with access token *)
let get_conversations_info ~(ctx : Context.t) ~(conversation : Slack_t.conversations_info_req) =
  log#info "getting conversation channel %s" conversation.channel;
  let headers = [ bearer_token_header (Context.get_slack_access_token ctx) ] in
  let url = "https://slack.com/api/conversations.info" in
  let data = www_form_of_conversations_info_req conversation in
  let args = Web.make_url_args data in
  let url = sprintf "%s?%s" url args in
  match%lwt slack_api_request ~ua:ctx.ua ~headers `GET url Slack_j.read_conversations_info_res with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "failed to get conversation channel %s info: %s" conversation.channel (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

let www_form_of_user_info_req = function
  | ({ user; include_locale = Some include_locale } : Slack_t.user_info_req) ->
    [ "user", user; "include_locale", Bool.to_string include_locale ]
  | { user; _ } -> [ "user", user ]

(** [get_user ctx user] gets the slack user info;
      uses web API with access token *)
let get_user ~(ctx : Context.t) ~(user : Slack_t.user_info_req) =
  log#info "getting user %s" user.user;
  let headers = [ bearer_token_header (Context.get_slack_access_token ctx) ] in
  let url = "https://slack.com/api/users.info" in
  let data = www_form_of_user_info_req user in
  let args = Web.make_url_args data in
  let url = sprintf "%s?%s" url args in
  match%lwt slack_api_request ~ua:ctx.ua ~headers `GET url Slack_j.read_user_info_res with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "failed to get user %s: %s" user.user (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

let send_auth_test ~(ctx : Context.t) () =
  request_token_auth ~name:"retrieve bot information" ~ctx `POST "auth.test" Slack_j.read_auth_test_res
