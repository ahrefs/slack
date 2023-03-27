open Printf
open ExtLib
open Slack_j
open Slack_t

(*****************  General Slack Utilities for Handling Event Hooks  *****************)

(** [ validate_signature signing_key headers body ] validate the signature
    from a Slack event API hook. 
*)
let validate_signature ?(version = "v0") ?signing_key ~headers body =
  match signing_key with
  | None -> Ok ()
  | Some key ->
  match List.assoc_opt "x-slack-signature" headers with
  | None -> Error "unable to find header X-Slack-Signature"
  | Some signature ->
  match List.assoc_opt "x-slack-request-timestamp" headers with
  | None -> Error "unable to find header X-Slack-Request-Timestamp"
  | Some timestamp ->
    let basestring = Printf.sprintf "%s:%s:%s" version timestamp body in
    let expected_signature = Printf.sprintf "%s=%s" version (Common.sign_string_sha256 ~key ~basestring) in
    if String.equal expected_signature signature then Ok () else Error "signatures don't match"

(** [ process_slack_notification ] is a general handling function for Slack event callback
    notification where it validates the signature of incoming hooks and then pass it to your
    [ notification_handler ] to process the actual notification.  It also has handlings for
    the URL verification challenge so to support that, you need to make sure your handler
    returns a [string Lwt.t] (and you always should return [200s] code otherwise,
    Slack will retry).
*)
let process_slack_notification (ctx : Context.t) headers body ~notification_handler =
  match event_notification_of_string body with
  | Url_verification payload -> Lwt.return_ok payload.challenge
  | Event_callback notification ->
  match validate_signature ?signing_key:ctx.secrets.slack_signing_secret ~headers body with
  | Error e -> Lwt.return_error (sprintf "signature not validated: %s" e)
  | Ok () -> notification_handler notification

(** [ process_slack_event ] is the same as [ process_slack_notification ] but will disregard
    the notification detail and only process the notification event using your
    [ event_handler ].
*)
let process_slack_event (ctx : Context.t) headers body ~event_handler =
  process_slack_notification ctx headers body ~notification_handler:(fun notification ->
    event_handler notification.event)

(***************** Utilities over Slack API returns  *****************)

(** conversation types of a [Slack channel] *)
type conversation_type =
  | Channel
  | DirectMessage
  | Group

(** [ channel_type_of_conversation ] returns a [conversation_type] of a some
    [ conversation ] API result
*)
let conversation_type_of_conversation = function
  | ({ is_channel = true; _ } : conversation) -> Ok Channel
  | { is_im = true; _ } -> Ok DirectMessage
  | { is_group = true; _ } -> Ok Group
  | conversation -> Error (sprintf "did not get valid conversation info for channel %s" conversation.id)

let show_channel_type = function
  | Channel -> "channel"
  | DirectMessage -> "direct message"
  | Group -> "group"

(***************** Empty Slack API Requests Payloads  *****************)
let empty_attachments =
  {
    mrkdwn_in = None;
    fallback = None;
    color = None;
    pretext = None;
    author_name = None;
    author_link = None;
    author_icon = None;
    title = None;
    title_link = None;
    text = None;
    fields = None;
    image_url = None;
    thumb_url = None;
    ts = None;
    footer = None;
  }

let empty_post_msg_req =
  {
    channel = "";
    text = None;
    attachments = None;
    blocks = None;
    username = None;
    icon_url = None;
    icon_emoji = None;
    metadata = None;
    mrkdwn = None;
    parse = None;
    thread_ts = None;
    unfurl_links = None;
    unfurl_media = None;
  }

let empty_update_msg_req =
  {
    channel = "";
    ts = "";
    text = None;
    attachments = None;
    blocks = None;
    link_names = None;
    metadata = None;
    parse = None;
    reply_broadcast = None;
  }

let empty_conversations_info_req = { channel = ""; include_locale = None; include_num_members = None }

let empty_conversations_replies_req =
  {
    channel = "";
    ts = "";
    include_all_metadata = None;
    cursor = None;
    inclusive = None;
    latest = None;
    limit = None;
    oldest = None;
  }

let empty_files_upload_req =
  {
    channels = None;
    content = None;
    filename = None;
    filetype = None;
    initial_comment = None;
    thread_ts = None;
    title = None;
  }

(** [ ApiHelpers Api_Impl] is a functor that wraps Api for simple functionalities such as sending texts *)
module ApiHelpers (Api : Api.S) = struct
  let send_text_msg ~ctx ~channel ~text =
    let msg = { empty_post_msg_req with channel; text = Some text } in
    Api.send_message ~ctx ~msg

  let update_text_msg ~ctx ~channel ~update ~ts =
    let msg = { empty_update_msg_req with channel; text = Some update; ts } in
    Api.update_message ~ctx ~msg

  let send_text_msg_as_user ~ctx ~channel ~text ~username ?icon_url ?icon_emoji () =
    let msg = { empty_post_msg_req with channel; text = Some text; username = Some username; icon_url; icon_emoji } in
    Api.send_message ~ctx ~msg

  let get_channel_type ~(ctx : Context.t) ~channel =
    let conversation = { empty_conversations_info_req with channel } in
    match%lwt Api.get_conversations_info ~ctx ~conversation with
    | Error e -> Lwt.return_error @@ sprintf "unable to get conversation info for channel %s: %s" channel e
    | Ok ({ channel; _ } : conversations_info_res) -> Lwt.return @@ conversation_type_of_conversation channel
end
