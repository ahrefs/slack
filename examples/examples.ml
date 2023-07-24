open Cmdliner

(* flags *)
let addr =
  let doc = "ip address that the http server should use" in
  Arg.(value & opt string "0.0.0.0" & info [ "a"; "addr" ] ~docv:"ADDR" ~doc)

let port =
  let doc = "port number that the http server should use" in
  Arg.(value & opt int 8080 & info [ "p"; "port" ] ~docv:"PORT" ~doc)

let channel =
  let doc = "channel to send to" in
  Arg.(value & opt string "" & info [ "c"; "channel" ] ~docv:"CHANNEL" ~doc)

let channels_opt =
  let doc = "channel IDs to send to (comma separated)" in
  Arg.(value & opt (some string) None & info [ "c"; "channels" ] ~docv:"CHANNELS" ~doc)

let channel_id =
  let doc = "channel ID" in
  Arg.(value & opt string "" & info [ "c"; "channel" ] ~docv:"CHANNEL ID" ~doc)

let user_id =
  let doc = "user ID" in
  Arg.(value & opt string "" & info [ "u"; "user" ] ~docv:"USER ID" ~doc)

let user_id_list =
  let doc = "comma-separated user IDs" in
  Arg.(value & opt string "" & info [ "us"; "users" ] ~docv:"USER ID LIST" ~doc)

let timestamp =
  let doc = "timestamp of a message" in
  Arg.(value & opt string "" & info [ "ts"; "timestamp" ] ~docv:"TIMESTAMP" ~doc)

let text =
  let doc = "text to send" in
  Arg.(value & opt string "" & info [ "t"; "text" ] ~docv:"TEXT" ~doc)

let update =
  let doc = "text to update first message" in
  Arg.(value & opt string "" & info [ "u"; "update" ] ~docv:"UPDATE" ~doc)

let username =
  let doc = "username to send as" in
  Arg.(value & opt string "" & info [ "u"; "username" ] ~docv:"USERNAME" ~doc)

let usergroup =
  let doc = "usergroup" in
  Arg.(value & opt string "" & info [ "ug"; "usergroup" ] ~docv:"USERGROUP" ~doc)

let icon_url =
  let doc = "icon url to display for sender (supersede by icon_emoji)" in
  Arg.(value & opt string "" & info [ "iu"; "icon_url" ] ~docv:"ICON_URL" ~doc)

let icon_emoji =
  let doc = "icon emjoi to display for sender (supersede icon_url)" in
  Arg.(value & opt string "" & info [ "ie"; "icon-emoji" ] ~docv:"ICON_EMOJI" ~doc)

let include_disabled =
  let doc = "include disabled usergroup" in
  Arg.(value & opt (some bool) (Some true) & info [ "include_disabled" ] ~docv:"INCLUDE_DISABLED" ~doc)

(* commands *)
let echo =
  let doc = "launch the http server for the echo example" in
  let info = Cmd.info "echo" ~doc in
  let term = Term.(const Echo.http_server_action $ addr $ port) in
  Cmd.v info term

let send =
  let doc = "sending a text (as a user) using Slack APIs example" in
  let info = Cmd.info "send" ~doc in
  let term = Term.(const Sender.send $ icon_url $ icon_emoji $ username $ channel $ text) in
  Cmd.v info term

let send_file =
  let doc = "upload a file using Slack APIs example" in
  let info = Cmd.info "send_file" ~doc in
  let term = Term.(const Sender.send_file $ channels_opt $ text) in
  Cmd.v info term

let send_update =
  let doc = "sending a text then updating it using Slack APIs example" in
  let info = Cmd.info "send_update" ~doc in
  let term = Term.(const Sender.send_and_update $ channel $ text $ update) in
  Cmd.v info term

let join_conversation =
  let doc = "join a conversation using Slack APIs example" in
  let info = Cmd.info "join_convo" ~doc in
  let term = Term.(const Sender.join_conversation $ channel_id) in
  Cmd.v info term

let update_usergroup_users =
  let doc = "update a usergroup users list using Slack APIs example" in
  let info = Cmd.info "update_usergroup_users" ~doc in
  let term = Term.(const Sender.update_usergroup_users $ usergroup $ user_id_list) in
  Cmd.v info term

let get_user_info =
  let doc = "get a user info using Slack APIs example" in
  let info = Cmd.info "get_user" ~doc in
  let term = Term.(const Get_info.get_user $ user_id) in
  Cmd.v info term

let list_users =
  let doc = "list all users in workspace using Slack APIs example" in
  let info = Cmd.info "list_users" ~doc in
  let term = Term.(const Get_info.list_users $ const ()) in
  Cmd.v info term

let get_conversation_info =
  let doc = "get a conversation info using Slack APIs example" in
  let info = Cmd.info "get_convo" ~doc in
  let term = Term.(const Get_info.get_conversation $ channel_id) in
  Cmd.v info term

let get_conversation_replies =
  let doc = "get a conversation replies using Slack APIs example" in
  let info = Cmd.info "get_replies" ~doc in
  let term = Term.(const Get_info.get_replies $ channel_id $ timestamp) in
  Cmd.v info term

let list_usergroups =
  let doc = "list all usergroups in workspace using Slack APIs example" in
  let info = Cmd.info "list_usergroups" ~doc in
  let term = Term.(const Get_info.list_usergroups $ include_disabled $ const ()) in
  Cmd.v info term

let list_usergroup_users =
  let doc = "list all users in usergroup using Slack APIs example" in
  let info = Cmd.info "list_usergroup_users" ~doc in
  let term = Term.(const Get_info.list_usergroup_users $ usergroup $ include_disabled $ const ()) in
  Cmd.v info term

let default, info =
  let doc = "examples" in
  Term.(ret (const (`Help (`Pager, None)))), Cmd.info "examples" ~doc ~version:"0.0.0"

let () =
  let cmds =
    [
      echo;
      send;
      send_file;
      send_update;
      join_conversation;
      update_usergroup_users;
      get_user_info;
      get_conversation_info;
      get_conversation_replies;
      list_users;
      list_usergroups;
      list_usergroup_users;
    ]
  in
  let group = Cmd.group ~default info cmds in
  exit @@ Cmd.eval group
