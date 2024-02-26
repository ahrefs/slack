open Slack_lib
open Devkit
open Printf

let log = Log.from "echo_example"

module ApiHelpers = Utils.ApiHelpers (Api_remote)

let alternate_unfurl = ref true

let slack_echo_event_handler ctx event =
  match event with
  | Slack_t.Message event when Option.is_none event.bot_id ->
    ( match event.text with
    | None ->
      log#error "There is no text in the message.";
      Lwt.return_ok ""
    | Some text ->
      ( match%lwt ApiHelpers.send_text_msg ~ctx ~channel:event.channel ~text with
      | Ok (_res : Slack_t.post_message_res) -> Lwt.return_ok ""
      | Error e ->
        log#error "Nope, did not work: %s" (Slack_j.string_of_slack_api_error e);
        Lwt.return_ok ""
      )
    )
  | Link_shared e ->
    let unfurl_link (link_shared_link : Slack_t.link_shared_link) =
      let open Slack_t in
      let link_unfurl : unfurl =
        match !alternate_unfurl with
        | true ->
          Blocks { blocks = [ Section { text = { text_type = Mrkdwn; text = "some other text in a section" } } ] }
        | false -> Message_attachment (make_message_attachment ~text:"i unfurled this link!" ())
      in
      alternate_unfurl := not !alternate_unfurl;
      link_shared_link.url, link_unfurl
    in
    let req : Slack_t.chat_unfurl_req =
      { channel = e.channel; ts = e.message_ts; unfurls = List.map unfurl_link e.links }
    in
    ( match%lwt Api_remote.send_chat_unfurl ~ctx ~req with
    | Ok () -> Lwt.return_ok "unfurl sent successfully"
    | Error e ->
      let msg = sprintf "failed to send to %s:\n %s\n" req.channel (Slack_j.string_of_slack_api_error e) in
      print_endline msg;
      Lwt.return_error msg
    )
  | _ -> Lwt.return_ok ""

let handler ctx request path =
  let open Httpev in
  match request.meth, List.map Web.urldecode path with
  | _, [ "events" ] ->
    log#info "%s" request.body;
    Utils.process_slack_event ctx request.headers request.body ~event_handler:(slack_echo_event_handler ctx)
  | _, _ ->
    log#error "unknown path : %s" (Httpev.show_request request);
    Lwt.return_error "not found"

let http_server_action addr port =
  Lwt_main.run (Common_example.run_server ~ctx:Common_example.get_ctx_example ~addr ~port ~handler)
