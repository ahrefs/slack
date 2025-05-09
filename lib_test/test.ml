open Slack_lib
open Common
open Printf

let log = Devkit.Log.from "test"

module Api = Api_local
module Utils_local = Utils.ApiHelpers (Api)

let simple_text_msg_cases =
  [ "channel1", "msgblah"; "otherone", "mrkdown here _msgblah_ "; "otherone", "new line \n  _msgblah_ " ]

let process_send_msg (channel, text) =
  Printf.printf "simple_test--------channel: %s--------\n" channel;
  let ctx = Context.empty_ctx () in
  match%lwt Utils_local.send_text_msg ~ctx ~channel ~text with
  | Ok _ -> Lwt.return_unit
  | Error e ->
    log#error "failed to send message: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let text_msg_as_user_cases =
  [
    "channel1", "msgblah", "me", "https://example.com/some.jpg", ":thumbsup:";
    "otherone", "mrkdown here _msgblah_ ", "me", "https://example.com/some.jpg", ":thumbsup:";
    "otherone", "new line \n  _msgblah_ ", "me", "https://example.com/some.jpg", ":thumbsup:";
  ]

let process_send_msg_as_user (channel, text, username, icon_url, icon_emoji) =
  Printf.printf "as_user_test--------channel: %s--------\n" channel;
  let ctx = Context.empty_ctx () in
  match%lwt Utils_local.send_text_msg_as_user ~ctx ~channel ~text ~icon_url ~icon_emoji ~username () with
  | Ok _ -> Lwt.return_unit
  | Error e ->
    log#error "failed to send message: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let user_list = [ "U046XN0M2R5"; "U04A3C2LC6N"; "UG3UGF1AM" ]

let process_get_user_res user =
  Printf.printf "get_user_test--------user: %s--------\n" user;
  let ctx = Context.empty_ctx () in
  let user : Slack_t.user_info_req = { user; include_locale = None } in
  match%lwt Api.get_user ~ctx ~user with
  | Ok res ->
    let json = res |> Slack_j.string_of_user_info_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to get user: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let conversation_list = [ "C049XFXK286"; "C04CXBYNC68"; "D049WPTCGMC" ]

let process_get_conversations_info_res channel =
  Printf.printf "get_conversations_info--------channel: %s--------\n" channel;
  let ctx = Context.empty_ctx () in
  let conversation = Slack_j.make_conversations_info_req ~channel () in
  match%lwt Api.get_conversations_info ~ctx ~conversation with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_conversations_info_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    ( match%lwt Utils_local.get_channel_type ~ctx ~channel with
    | Ok channel_type ->
      Printf.printf "channel type is: %s\n" (Utils.show_channel_type channel_type);
      Lwt.return_unit
    | Error e ->
      print_endline (Slack_j.string_of_slack_api_error e);
      Lwt.return_unit
    )
  | Error e ->
    log#error "failed to get conversation: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let conversation_ts_list =
  [
    "D049WPTCGMC", "1675329533.687169";
    "D049WPTCGMC", "1675329544.950899";
    "D049WPTCGMC", "1675330543.480229";
    "D049WPTCGMC", "1675329534.687279";
  ]

let process_get_conversations_replies_res (channel, ts) =
  Printf.printf "get_conversations_replies--------channel: %s--------\n" channel;
  let ctx = Context.empty_ctx () in
  let conversation = Slack_j.make_conversations_replies_req ~channel ~ts () in
  match%lwt Api.get_replies ~ctx ~conversation with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_conversations_replies_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to get conversation: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let process_get_conversations_history_res channel =
  Printf.printf "get_conversations_history--------channel: %s--------\n" channel;
  let ctx = Context.empty_ctx () in
  let conversation = Slack_j.make_conversations_history_req ~channel () in
  match%lwt Api.get_history ~ctx ~conversation with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_conversations_history_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to get conversation: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let conversation_join_list = [ "C047C6ECFNX"; "C049XFXK286" ]

let process_conversations_join channel =
  Printf.printf "get_conversations_replies--------channel: %s--------\n" channel;
  let ctx = Context.empty_ctx () in
  let channel : Slack_t.conversations_join_req = { channel } in
  match%lwt Api.join_conversation ~ctx ~channel with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_conversations_join_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to join conversation: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let file_list =
  [
    "C049XFXK286", "some file content here";
    "C04CXBYNC68", "some file content there weird characters 1i0134uuuoqiwejfm_()/,sadlk.asd\\slqwep[ofjvn";
  ]

let process_upload_file (channels, content) =
  Printf.printf "upload_file_to--------channels: %s--------\n" channels;
  let ctx = Context.empty_ctx () in
  let req : Slack_t.files_upload_req = Slack_j.make_files_upload_req ~filename:"test" ~channels ~content () in
  match%lwt Api.upload_file ~ctx ~req with
  | Ok res ->
    let json = res |> Slack_j.string_of_files_upload_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to get conversation: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let update_usergroup_users_list = [ "S04XV4DF0LQ", [ "U046XN0M2R5"; "U04D7HU80BT" ]; "S04NV4DF0LQ", [ "U046XN0M2R5" ] ]

let process_update_usergroup_users (usergroup, users) =
  Printf.printf "update_users_of--------usergroup: %s--------\n" usergroup;
  let ctx = Context.empty_ctx () in
  let usergroup : Slack_t.update_usergroups_users_req = { usergroup; users; include_count = None; team_id = None } in
  match%lwt Api.update_usergroup_users ~ctx ~usergroup with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_update_usergroups_users_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to update users of usergroup %s: %s" usergroup.usergroup (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let list_usergroups_team_id_list = [ "T0475L7BATY" ]

let process_list_usergroups team_id =
  Printf.printf "list_usergroups_of--------team_id: %s--------\n" team_id;
  let ctx = Context.empty_ctx () in
  let req : Slack_t.list_usergroups_req =
    { include_count = None; team_id = Some team_id; include_users = Some true; include_disabled = Some true }
  in
  match%lwt Api.list_usergroups ~ctx ~req with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_list_usergroups_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to update users of usergroup %s: %s" team_id (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let list_usergroup_users_usergroup_id_list = [ "S04NV4DF0LQ" ]

let process_list_usergroup_users usergroup =
  Printf.printf "list_usergroup_users_of--------usergroup_id: %s--------\n" usergroup;
  let ctx = Context.empty_ctx () in
  let usergroup : Slack_t.list_usergroup_users_req = { usergroup; team_id = None; include_disabled = Some true } in
  match%lwt Api.list_usergroup_users ~ctx ~usergroup with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_list_usergroup_users_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to get users of usergroup %s: %s" usergroup.usergroup (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let list_users_cursors_list = [ "dXNlcjpVMDQ2WE4wTTJSNQ==" ]

let process_list_users cursor =
  Printf.printf "list_users--------cursor: %s--------\n" cursor;
  let ctx = Context.empty_ctx () in
  let req : Slack_t.list_users_req = { cursor = Some cursor; include_locale = None; limit = None; team_id = None } in
  match%lwt Api.list_users ~ctx ~req with
  | Ok res ->
    let json = res |> Slack_j.string_of_list_users_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to get users at cursor %s: %s" cursor (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let add_bookmarks_list = [ "C1RQ000", "bookmark-1", "link" ]

let process_add_bookmark (channel_id, title, type_) =
  Printf.printf "add_bookmark_to_channel_id_of--------channel_id: %s--------\n" channel_id;
  let ctx = Context.empty_ctx () in
  let req : Slack_t.add_bookmark_req = Slack_j.make_add_bookmark_req ~channel_id ~title ~type_ () in
  match%lwt Api.add_bookmark ~ctx ~req with
  | Ok res ->
    let json = res |> Slack_j.string_of_add_bookmark_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to add bookmark (channel %s, title %s, type %s): %s" channel_id title type_
      (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let edit_bookmarks_id_list = [ "C1RQ000", "Bk033XFJ9BTJ" ]

let process_edit_bookmark (bookmark_id, channel_id) =
  Printf.printf "edit_bookmark_to_channel_id_of--------channel_id: %s--------\n" channel_id;
  let ctx = Context.empty_ctx () in
  let req : Slack_t.edit_bookmark_req = Slack_j.make_edit_bookmark_req ~channel_id ~bookmark_id () in
  match%lwt Api.edit_bookmark ~ctx ~req with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_edit_bookmark_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to edit bookmark (bookmark %s, channel %s): %s" bookmark_id channel_id
      (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let list_bookmarks_id_list = [ "C1RQ000" ]

let process_list_bookmarks channel_id =
  Printf.printf "list_bookmarks_to_channel_id_of--------channel_id: %s--------\n" channel_id;
  let ctx = Context.empty_ctx () in
  let req : Slack_t.list_bookmarks_req = Slack_j.make_list_bookmarks_req ~channel_id in
  match%lwt Api.list_bookmarks ~ctx ~req with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_list_bookmarks_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to list bookmarks in channel %s: %s" channel_id (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let remove_bookmarks_id_list = [ "C1RQ000", "Bk033XFJ9BTJ" ]

let process_remove_bookmark (bookmark_id, channel_id) =
  Printf.printf "remove_bookmark_to_channel_id_of--------channel_id: %s--------\n" channel_id;
  let ctx = Context.empty_ctx () in
  let req : Slack_t.remove_bookmark_req = Slack_j.make_remove_bookmark_req ~channel_id ~bookmark_id () in
  match%lwt Api.remove_bookmark ~ctx ~req with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_remove_bookmark_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to remove bookmark (bookmark %s, channel %s): %s" bookmark_id channel_id
      (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let list_conversations_types_list = [ "public_channel"; "im,mpim" ]

let process_list_conversations types =
  Printf.printf "list_conversations--------types: %s--------\n" types;
  let ctx = Context.empty_ctx () in
  let req : Slack_t.conversations_list_req = Slack_j.make_conversations_list_req ~types () in
  match%lwt Api.list_conversations ~ctx ~req with
  | Ok res ->
    let json =
      res |> Slack_j.string_of_conversations_list_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    log#error "failed to list conversations: %s" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let views_list =
  let title = Slack_lib.Block_kit_safe.make_plain_text ~text:"dummy" () in
  let view = Slack_lib.Block_kit_safe.make_modal ~title ~blocks:[] () in
  [ Some "ref1", None, view; None, Some "ref1", view; Some "ref1", Some "ref1", view; None, None, view ]

let process_open_views (ref1, ref2, view) =
  Printf.printf "open_views----------------\n";
  let req : Slack_t.open_views_req = { trigger_id = ref1; interactivity_pointer = ref2; view } in
  let ctx = Context.empty_ctx () in
  match%lwt Api.open_views ~ctx ~req with
  | Ok res ->
    let json = res |> Slack_j.string_of_open_views_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    Printf.printf "failed to open views: %s\n" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let process_push_views (ref1, ref2, view) =
  Printf.printf "push_views----------------\n";
  let req : Slack_t.push_views_req = { trigger_id = ref1; interactivity_pointer = ref2; view } in
  let ctx = Context.empty_ctx () in
  match%lwt Api.push_views ~ctx ~req with
  | Ok res ->
    let json = res |> Slack_j.string_of_push_views_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    Printf.printf "failed to push views: %s\n" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let process_update_views (ref1, ref2, view) =
  Printf.printf "update_views----------------\n";
  let req : Slack_t.update_views_req = { view_id = ref1; external_id = ref2; view; hash = None } in
  let ctx = Context.empty_ctx () in
  match%lwt Api.update_views ~ctx ~req with
  | Ok res ->
    let json = res |> Slack_j.string_of_update_views_res |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string in
    print_endline json;
    Lwt.return_unit
  | Error e ->
    Printf.printf "failed to update views: %s\n" (Slack_j.string_of_slack_api_error e);
    Lwt.return_unit

let mock_slack_event_dir = "mock-slack-events"

let get_mock_slack_events () =
  List.map (Filename.concat mock_slack_event_dir) (get_sorted_files_from mock_slack_event_dir)

let process_events path =
  Printf.printf "===== file %s =====\n" path;
  try
    let notification = Slack_j.event_callback_notification_of_string (get_local_file path) in
    let json =
      notification
      |> Slack_j.string_of_event_callback_notification
      |> Yojson.Basic.from_string
      |> Yojson.Basic.pretty_to_string
    in
    printf "%s\n" json;
    Lwt.return_unit
  with
  | Yojson.Json_error e ->
    printf "failed to parse slack event json %s due to: %s\n" path e;
    Lwt.return_unit
  | e ->
    printf "failed to process slack event %s due to:\n%s\n" path (Printexc.to_string e);
    Lwt.return_unit

let mock_slack_interaction_dir = "mock-slack-interactions"

let get_mock_slack_interactions () =
  List.map (Filename.concat mock_slack_interaction_dir) (get_sorted_files_from mock_slack_interaction_dir)

let process_interactions path =
  Printf.printf "===== file %s =====\n" path;
  try
    let text = get_local_file path in
    let interaction =
      if Filename.check_suffix path "www" then
        Uri.query_of_encoded text |> List.assoc "payload" |> List.hd |> Slack_j.interaction_of_string
      else Slack_j.interaction_of_string (get_local_file path)
    in
    let json =
      interaction |> Slack_j.string_of_interaction |> Yojson.Basic.from_string |> Yojson.Basic.pretty_to_string
    in
    printf "%s\n" json;
    Lwt.return_unit
  with
  | Yojson.Json_error e ->
    printf "failed to parse slack interaction json %s due to: %s\n" path e;
    Lwt.return_unit
  | e ->
    printf "failed to process slack interaction %s due to:\n%s\n" path (Printexc.to_string e);
    Lwt.return_unit

let test_lexer () =
  let lexbuf =
    Lexing.from_string
      {|<http://example.com|example link>
<http://example.com>
<#C0838UC2D|general>
<@UNIOCDINAO>
to:<@UNIOCDINAO>
<!subteam^UIAOBCD>
<!special mention> :star-struck: smile `inline code`
this`inline code`rocks
```codeblock
type poly = [ `Foo | `Bar ]
```|}
  in
  try
    while true do
      Slex.read lexbuf |> Slex.show_token |> print_endline
    done
  with Slex.EOF -> ()

let () =
  let slack_events = get_mock_slack_events () in
  let slack_interactions = get_mock_slack_interactions () in
  Lwt_main.run
    (let%lwt () = Lwt_list.iter_s process_send_msg simple_text_msg_cases in
     let%lwt () = Lwt_list.iter_s process_send_msg_as_user text_msg_as_user_cases in
     let%lwt () = Lwt_list.iter_s process_get_user_res user_list in
     let%lwt () = Lwt_list.iter_s process_get_conversations_replies_res conversation_ts_list in
     let%lwt () = Lwt_list.iter_s process_get_conversations_info_res conversation_list in
     let%lwt () = Lwt_list.iter_s process_get_conversations_history_res conversation_list in
     let%lwt () = Lwt_list.iter_s process_conversations_join conversation_join_list in
     let%lwt () = Lwt_list.iter_s process_upload_file file_list in
     let%lwt () = Lwt_list.iter_s process_update_usergroup_users update_usergroup_users_list in
     let%lwt () = Lwt_list.iter_s process_list_usergroups list_usergroups_team_id_list in
     let%lwt () = Lwt_list.iter_s process_list_usergroup_users list_usergroup_users_usergroup_id_list in
     let%lwt () = Lwt_list.iter_s process_list_users list_users_cursors_list in
     let%lwt () = Lwt_list.iter_s process_list_conversations list_conversations_types_list in
     let%lwt () = Lwt_list.iter_s process_add_bookmark add_bookmarks_list in
     let%lwt () = Lwt_list.iter_s process_edit_bookmark edit_bookmarks_id_list in
     let%lwt () = Lwt_list.iter_s process_list_bookmarks list_bookmarks_id_list in
     let%lwt () = Lwt_list.iter_s process_remove_bookmark remove_bookmarks_id_list in
     let%lwt () = Lwt_list.iter_s process_open_views views_list in
     let%lwt () = Lwt_list.iter_s process_push_views views_list in
     let%lwt () = Lwt_list.iter_s process_update_views views_list in
     let%lwt () = Lwt_list.iter_s process_events slack_events in
     let%lwt () = Lwt_list.iter_s process_interactions slack_interactions in
     Lwt.return_unit
    );
  test_lexer ()
