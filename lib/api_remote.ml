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
let slack_api_request ~name ?ua ?headers ?body meth url read =
  match%lwt http_request ?ua ?headers ?body meth url with
  | Error e ->
    log#warn "Api %s request: %s errored: %s" name url e;
    Lwt.return_error (`Other e)
  | Ok s ->
  match Slack_j.slack_response_of_string read s with
  | Ok res -> Lwt.return_ok res
  | Error e ->
    log#warn "Api %s error: %s" name (Slack_j.string_of_slack_api_error e);
    Lwt.return_error e

let request_token_auth ~name ?(headers = []) ?body ~(ctx : Context.t) meth path read =
  let headers = sprintf "Authorization: Bearer %s" (Uri.pct_encode @@ Context.get_slack_access_token ctx) :: headers in
  let url = sprintf "https://slack.com/api/%s" path in
  slack_api_request ~name ~ua:ctx.ua ?body ~headers meth url read

(** [send_message ctx msg] notifies [msg.channel] with the payload [msg];
    uses web API with access token. *)
let send_message ~(ctx : Context.t) ~(msg : Slack_t.post_message_req) =
  log#info "sending to %s" msg.channel;
  let data = Slack_j.string_of_post_message_req msg in
  log#info "data to send in message to channel %s: %s" msg.channel data;
  let body = `Raw ("application/json", data) in
  request_token_auth ~ctx ~body
    ~name:(sprintf "chat.postMessage (%s)" msg.channel)
    `POST "chat.postMessage" Slack_j.read_post_message_res

(** [send_message_webhook ctx url msg] notifies the channel associated with the
    [url] for a legacy webhook with the payload [msg]. *)
let send_message_webhook ~(ctx : Context.t) ~url ~(msg : Slack_t.post_message_req) =
  let data = Slack_j.string_of_post_message_req msg in
  log#info "data to send in message to channel %s: %s" msg.channel data;
  let body = `Raw ("application/json", data) in
  match%lwt http_request ~ua:ctx.ua ~body `POST url with
  | Ok "ok" -> Lwt.return_ok ()
  | Ok e | Error e ->
    log#warn "Webhook chat.postMessage (%s) request errored: %s" msg.channel e;
    Lwt.return_error (`Other e)

(** [update_message ctx msg] update [msg] at timestamp [msg.ts]
      in channel [msg.channel] with the payload [msg];
      uses web API with access token *)
let update_message ~(ctx : Context.t) ~(msg : Slack_t.update_message_req) =
  log#info "updating message at timestamp %s in channel %s" msg.ts msg.channel;
  let data = Slack_j.string_of_update_message_req msg in
  let body = `Raw ("application/json", data) in
  log#info "data to update message in channel %s: %s" msg.channel data;
  request_token_auth
    ~name:(sprintf "chat.update (%s,%s)" msg.ts msg.channel)
    ~ctx ~body `POST "chat.update" Slack_j.read_update_message_res

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
  let args = www_form_of_files_upload_req file in
  let data = Web.make_url_args args in
  let body = `Raw ("application/x-www-form-urlencoded", data) in
  log#info "data to upload file: %s" data;
  request_token_auth ~ctx
    ~name:(sprintf "file.upload (%s)" @@ Option.default "<NO CHANNEL>" file.channels)
    ~body `POST "files.upload" Slack_j.read_files_upload_res

(** [join_conversation ctx channel ] will join the token owner
    [ctx.secrets.slack_access_token] to the [channel]. *)
let join_conversation ~(ctx : Context.t) ~(channel : Slack_t.conversations_join_req) =
  log#info "joining channel %s" channel.channel;
  let data = Slack_j.string_of_conversations_join_req channel in
  let body = `Raw ("application/json", data) in
  request_token_auth
    ~name:(sprintf "conversations.join (%s)" channel.channel)
    ~ctx ~body `POST "conversations.join" Slack_j.read_conversations_join_res

(** [send_chat_unfurl ctx req] unfurls link (payload [link.unfurls]) in [req.channel] at [req.ts];
      uses web API with access token *)
let send_chat_unfurl ~(ctx : Context.t) ~(req : Slack_t.chat_unfurl_req) =
  let data = Slack_j.string_of_chat_unfurl_req req in
  let body = `Raw ("application/json", data) in
  log#info "link to unfurl message in channel %s: %s" req.channel data;
  match%lwt
    request_token_auth ~ctx ~name:(sprintf "chat.unfurl (%s)" req.channel) ~body `POST "chat.unfurl" Slack_j.read_ok_res
  with
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
  let data = Slack_j.string_of_update_usergroups_users_req usergroup in
  let body = `Raw ("application/json", data) in
  request_token_auth
    ~name:(sprintf "usergroups.users.update (%s,[%s])" usergroup.usergroup (String.concat "; " usergroup.users))
    ~ctx ~body `POST "usergroups.users.update" Slack_j.read_update_usergroups_users_res

let www_form_of_list_usergroups_req (req : Slack_t.list_usergroups_req) =
  let fields =
    [
      string_field_val req.team_id "team_id";
      bool_field_val req.include_disabled "include_disabled";
      bool_field_val req.include_users "include_users";
      bool_field_val req.include_count "include_count";
    ]
  in
  list_filter_opt fields

(** [list_usergroups ctx req] gets the slack usergroups in the workspace info;
    uses web API with access token *)
let list_usergroups ~(ctx : Context.t) ~(req : Slack_t.list_usergroups_req) =
  log#info "listing usergroups %s" @@ Slack_j.string_of_list_usergroups_req req;
  let data = www_form_of_list_usergroups_req req in
  let args = Web.make_url_args data in
  let api_path = sprintf "usergroups.list?%s" args in
  request_token_auth
    ~name:(sprintf "usergroups.list (%s)" @@ Option.default "<NO TEAM ID>" req.team_id)
    ~ctx `GET api_path Slack_j.read_list_usergroups_res

let www_form_of_list_usergroup_users_req (usergroup : Slack_t.list_usergroup_users_req) =
  let fields =
    [
      Some ("usergroup", usergroup.usergroup);
      string_field_val usergroup.team_id "team_id";
      bool_field_val usergroup.include_disabled "include_disabled";
    ]
  in
  list_filter_opt fields

let list_usergroup_users ~ctx ~(usergroup : Slack_t.list_usergroup_users_req) =
  log#info "listing usergroup %s users" @@ usergroup.usergroup;
  let data = www_form_of_list_usergroup_users_req usergroup in
  let args = Web.make_url_args data in
  let api_path = sprintf "usergroups.users.list?%s" args in
  request_token_auth
    ~name:(sprintf "usergroups.users.list (%s)" usergroup.usergroup)
    ~ctx `GET api_path Slack_j.read_list_usergroup_users_res

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
  let data = www_form_of_conversations_replies_req conversation in
  let args = Web.make_url_args data in
  let api_path = sprintf "conversations.replies?%s" args in
  request_token_auth
    ~name:(sprintf "conversations.replies (%s, %s)" conversation.channel conversation.ts)
    ~ctx `GET api_path Slack_j.read_conversations_replies_res

let www_form_of_conversation_history_req (conversation : Slack_t.conversations_history_req) =
  let fields =
    [
      Some ("channel", conversation.channel);
      string_field_val conversation.cursor "cursor";
      bool_field_val conversation.include_all_metadata "include_all_metadata";
      bool_field_val conversation.inclusive "inclusive";
      string_field_val conversation.latest "latest";
      int_field_val conversation.limit "limit";
      string_field_val conversation.oldest "oldest";
    ]
  in
  list_filter_opt fields

let get_history ~(ctx : Context.t) ~(conversation : Slack_t.conversations_history_req) =
  log#info "getting conversations history of %s" conversation.channel;
  let data = www_form_of_conversation_history_req conversation in
  let args = Web.make_url_args data in
  let api_path = sprintf "conversations.history?%s" args in
  request_token_auth
    ~name:(sprintf "conversations.history (%s)" conversation.channel)
    ~ctx `POST api_path Slack_j.read_conversations_history_res

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
  let data = www_form_of_conversations_info_req conversation in
  let args = Web.make_url_args data in
  let api_path = sprintf "conversations.info?%s" args in
  request_token_auth
    ~name:(sprintf "conversations.info (%s)" conversation.channel)
    ~ctx `GET api_path Slack_j.read_conversations_info_res

let www_form_of_user_info_req = function
  | ({ user; include_locale = Some include_locale } : Slack_t.user_info_req) ->
    [ "user", user; "include_locale", Bool.to_string include_locale ]
  | { user; _ } -> [ "user", user ]

(** [get_user ctx user] gets the slack user info;
      uses web API with access token *)
let get_user ~(ctx : Context.t) ~(user : Slack_t.user_info_req) =
  log#info "getting user %s" user.user;
  let data = www_form_of_user_info_req user in
  let args = Web.make_url_args data in
  let api_path = sprintf "users.info?%s" args in
  request_token_auth ~name:(sprintf "users.info (%s)" user.user) ~ctx `GET api_path Slack_j.read_user_info_res

let www_form_of_list_users_req (req : Slack_t.list_users_req) =
  let fields =
    [
      string_field_val req.cursor "cursor";
      bool_field_val req.include_locale "include_locale";
      int_field_val req.limit "limit";
      string_field_val req.team_id "team_id";
    ]
  in
  list_filter_opt fields

let list_users ~(ctx : Context.t) ~(req : Slack_t.list_users_req) =
  log#info "getting users %s" @@ Slack_j.string_of_list_users_req req;
  let data = www_form_of_list_users_req req in
  let args = Web.make_url_args data in
  let api_path = sprintf "users.list?%s" args in
  request_token_auth
    ~name:(sprintf "users.list (%s)" @@ Slack_j.string_of_list_users_req req)
    ~ctx `GET api_path Slack_j.read_list_users_res

let add_bookmark ~(ctx : Context.t) ~(req : Slack_t.add_bookmark_req) =
  log#info "adding bookmark %s" @@ Slack_j.string_of_add_bookmark_req req;
  let data = Slack_j.string_of_add_bookmark_req req in
  let body = `Raw ("application/json", data) in
  let api_path = sprintf "bookmark.add" in
  request_token_auth
    ~name:(sprintf "bookmark.add (%s)" @@ Slack_j.string_of_add_bookmark_req req)
    ~ctx ~body `POST api_path Slack_j.read_add_bookmark_res

let edit_bookmark ~(ctx : Context.t) ~(req : Slack_t.edit_bookmark_req) =
  log#info "editting bookmark %s" @@ Slack_j.string_of_edit_bookmark_req req;
  let data = Slack_j.string_of_edit_bookmark_req req in
  let body = `Raw ("application/json", data) in
  let api_path = sprintf "bookmark.edit" in
  request_token_auth
    ~name:(sprintf "bookmark.edit (%s)" @@ Slack_j.string_of_edit_bookmark_req req)
    ~ctx ~body `POST api_path Slack_j.read_edit_bookmark_res

let list_bookmarks ~(ctx : Context.t) ~(req : Slack_t.list_bookmarks_req) =
  log#info "getting bookmarks %s" @@ Slack_j.string_of_list_bookmarks_req req;
  let data = Slack_j.string_of_list_bookmarks_req req in
  let body = `Raw ("application/json", data) in
  let api_path = sprintf "bookmarks.list" in
  request_token_auth
    ~name:(sprintf "bookmarks.list (%s)" @@ Slack_j.string_of_list_bookmarks_req req)
    ~ctx ~body `POST api_path Slack_j.read_list_bookmarks_res

let remove_bookmark ~(ctx : Context.t) ~(req : Slack_t.remove_bookmark_req) =
  log#info "removing bookmark %s" @@ Slack_j.string_of_remove_bookmark_req req;
  let data = Slack_j.string_of_remove_bookmark_req req in
  let body = `Raw ("application/json", data) in
  let api_path = sprintf "bookmark.remove" in
  request_token_auth
    ~name:(sprintf "bookmark.remove (%s)" @@ Slack_j.string_of_remove_bookmark_req req)
    ~ctx ~body `POST api_path Slack_j.read_remove_bookmark_res

let send_auth_test ~(ctx : Context.t) () =
  request_token_auth ~name:"retrieve bot information" ~ctx `POST "auth.test" Slack_j.read_auth_test_res
