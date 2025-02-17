open Slack_lib
open ExtLib
open Devkit
open Printf

let log = Log.from "sender_example"

module ApiHelpers = Utils.ApiHelpers (Api_remote)

let send icon_url icon_emoji username channel text =
  let run =
    let ctx = Common_example.get_ctx_example in
    match username with
    | "" ->
      ( match%lwt ApiHelpers.send_text_msg ~ctx ~channel ~text with
      | Ok res ->
        printf "sent '%s' to %s (%s) at %s.\n%!" text channel res.channel res.ts;
        Lwt.return_unit
      | Error e ->
        printf "failed to send to %s:\n %s\n%!" channel (Slack_j.string_of_slack_api_error e);
        Lwt.return_unit
      )
    | username ->
      ( match%lwt ApiHelpers.send_text_msg_as_user ~ctx ~channel ~text ~username ~icon_url ~icon_emoji () with
      | Ok res ->
        printf "sent '%s' as %s to %s (%s) at %s.\n%!" text username channel res.channel res.ts;
        Lwt.return_unit
      | Error e ->
        printf "failed to send to %s:\n %s\n%!" channel (Slack_j.string_of_slack_api_error e);
        Lwt.return_unit
      )
  in
  Lwt_main.run run

let send_file channels content =
  let run =
    let ctx = Common_example.get_ctx_example in
    let req = Slack_j.make_files_upload_req ?channels ~content () in
    match%lwt Api_remote.upload_file ~ctx ~req with
    | Ok res ->
      printf "file uploaded: %s" res.file.id;
      ( match res.file.permalink with
      | Some permalink -> printf " at %s" permalink
      | None ->
      match res.file.permalink_public with
      | Some permalink -> printf " (public %s)" permalink
      | None -> ()
      );
      print_endline "\n%!";
      Lwt.return_unit
    | Error e ->
      printf "failed to send to %s\n%!" (Slack_j.string_of_slack_api_error e);
      Lwt.return_unit
  in
  Lwt_main.run run

let send_and_update channel text update =
  let run =
    let ctx = Common_example.get_ctx_example in
    match%lwt ApiHelpers.send_text_msg ~ctx ~channel ~text with
    | Ok res ->
      printf "sent '%s' to %s (%s) at %s.\n%!" text channel res.channel res.ts;
      printf "sleeping...";
      let%lwt () = Lwt_unix.sleep 3. in
      printf "woke up\n%!";
      let ts = res.ts in
      log#info "ts: %s" ts;
      ( match%lwt ApiHelpers.update_text_msg ~ctx ~channel:res.channel ~ts ~update with
      | Ok res ->
        printf "updated '%s' to '%s' in channel %s at %s.\n%!" text update res.channel res.ts;
        Lwt.return_unit
      | Error e ->
        printf "failed to send to %s:\n %s\n%!" channel (Slack_j.string_of_slack_api_error e);
        Lwt.return_unit
      )
    | Error e ->
      printf "failed to send to %s:\n %s\n%!" channel (Slack_j.string_of_slack_api_error e);
      Lwt.return_unit
  in
  Lwt_main.run run

let join_conversation channel =
  let run =
    let ctx = Common_example.get_ctx_example in
    let channel : Slack_t.conversations_join_req = { channel } in
    match%lwt Api_remote.join_conversation ~ctx ~channel with
    | Ok conversation ->
      printf "conversation joined sent successfully\n%s\n%!" (Slack_j.string_of_conversations_join_res conversation);
      Lwt.return_unit
    | Error e ->
      printf "failed join channel %s:\n %s\n%!" channel.channel (Slack_j.string_of_slack_api_error e);
      Lwt.return_unit
  in
  Lwt_main.run run

let update_usergroup_users usergroup user_id_list =
  let run =
    let ctx = Common_example.get_ctx_example in
    let users = List.map String.trim (String.split_on_char ',' user_id_list) in
    let usergroup : Slack_t.update_usergroups_users_req = { usergroup; users; include_count = None; team_id = None } in
    match%lwt Api_remote.update_usergroup_users ~ctx ~usergroup with
    | Ok usergroup ->
      printf "conversation joined sent successfully\n%s\n%!" (Slack_j.string_of_update_usergroups_users_res usergroup);
      Lwt.return_unit
    | Error e ->
      printf "failed to update usergroup %s:\n %s\n%!" usergroup.usergroup (Slack_j.string_of_slack_api_error e);
      Lwt.return_unit
  in
  Lwt_main.run run
