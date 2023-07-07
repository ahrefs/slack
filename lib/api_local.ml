(** Module for mocking test requests to slack--will output on Stdio *)

open Common
open Printf

let cwd = Sys.getcwd ()
let cache_dir = Filename.concat cwd "slack-api-cache"

(** return the file with a function f applied unless the file is empty;
 empty file:this is needed to simulate 404 returns from github *)
let with_cache_file url f =
  match get_local_file url with
  | "" -> Lwt.return_error (`Other "empty file")
  | file -> Lwt.return_ok (f file)
  | exception Slack_lib_error e -> Lwt.return_error (`Other e)

let default_post_message_res : Slack_t.post_message_res = { channel = "SOME_RETURN_POST_CHANNEL_ID"; ts = "SOME_TS" }
let default_update_message_res : Slack_t.update_message_res =
  { channel = "SOME_RETURN_UPDATE_CHANNEL_ID"; ts = "SOME_TS" }
let default_files_res : Slack_t.file =
  {
    id = "SOME_FILE_ID";
    name = None;
    title = None;
    mimetype = None;
    filetype = None;
    pretty_type = None;
    user = None;
    size = None;
    channels = [];
    ims = [];
    groups = [];
    permalink = None;
    permalink_public = None;
  }
let default_files_upload_res : Slack_t.files_upload_res = { ok = true; file = default_files_res }

let send_message ~ctx:_ ~msg =
  let json = msg |> Slack_j.string_of_post_message_req |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
  printf "will notify #%s\n" msg.channel;
  printf "%s\n" json;
  Lwt.return_ok { default_post_message_res with channel = msg.channel }

let send_message_webhook ~ctx:_ ~url ~msg =
  let json = msg |> Slack_j.string_of_post_message_req |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
  printf "will notify #%s\n" url;
  printf "%s\n" json;
  Lwt.return_ok ()

let update_message ~ctx:_ ~msg =
  let json = msg |> Slack_j.string_of_update_message_req |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
  printf "will update #%s at %s \n" msg.channel msg.ts;
  printf "%s\n" json;
  Lwt.return_ok { default_update_message_res with channel = msg.channel }

let upload_file ~ctx:_ ~file =
  let json = file |> Slack_j.string_of_files_upload_req |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
  match file.channels with
  | Some channels ->
    printf "will update #%s\n" channels;
    printf "%s\n" json;
    Lwt.return_ok { default_files_upload_res with file = { default_files_res with channels = [ channels ] } }
  | None -> Lwt.return_error (`Other "invalid file upload")

let join_conversation ~ctx:_ ~(channel : Slack_t.conversations_join_req) =
  printf "joining #%s...\n" channel.channel;
  let url = Filename.concat cache_dir (sprintf "%s_join" channel.channel) in
  with_cache_file url Slack_j.conversations_join_res_of_string

let send_chat_unfurl ~ctx:_ ~(req : Slack_t.chat_unfurl_req) =
  let data = req |> Slack_j.string_of_chat_unfurl_req |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
  printf "will unfurl in #%s\n" req.channel;
  printf "%s\n" data;
  Lwt.return_ok ()

let update_usergroup_users ~ctx:_ ~(usergroup : Slack_t.update_usergroups_users_req) =
  printf "updating #%s...\n" usergroup.usergroup;
  let url = Filename.concat cache_dir (sprintf "%s_usergroup_users" usergroup.usergroup) in
  with_cache_file url Slack_j.update_usergroups_users_res_of_string

let get_replies ~ctx:_ ~(conversation : Slack_t.conversations_replies_req) =
  let url = Filename.concat cache_dir (sprintf "%s_%s_replies" conversation.channel conversation.ts) in
  with_cache_file url Slack_j.conversations_replies_res_of_string

let get_conversations_info ~ctx:_ ~(conversation : Slack_t.conversations_info_req) =
  let url = Filename.concat cache_dir conversation.channel in
  with_cache_file url Slack_j.conversations_info_res_of_string

let get_user ~ctx:_ ~(user : Slack_t.user_info_req) =
  let url = Filename.concat cache_dir user.user in
  with_cache_file url Slack_j.user_info_res_of_string

let list_usergroups ~ctx:_ ~(req : Slack_t.list_usergroups_req) =
  let url = Filename.concat cache_dir (sprintf "%s_usergroups_list" @@ Option.get req.team_id) in
  with_cache_file url Slack_j.list_usergroups_res_of_string

let list_usergroup_users ~ctx:_ ~(usergroup : Slack_t.list_usergroup_users_req) =
  printf "listing #%s...\n" usergroup.usergroup;
  let url = Filename.concat cache_dir (sprintf "%s_list_usergroup_users" usergroup.usergroup) in
  with_cache_file url Slack_j.list_usergroup_users_res_of_string

let list_users ~ctx:_ ~(req : Slack_t.list_users_req) =
  printf "listing at cursor #%s...\n" @@ Option.get req.cursor;
  let url = Filename.concat cache_dir (sprintf "%s_list_users" @@ Option.get req.cursor) in
  with_cache_file url Slack_j.list_users_res_of_string

let send_auth_test ~ctx:_ () =
  Lwt.return
  @@ Ok ({ url = ""; team = ""; user = ""; team_id = ""; user_id = "test_slack_user" } : Slack_t.auth_test_res)
