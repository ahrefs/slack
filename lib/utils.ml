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
  | exception Yojson.Json_error e -> Lwt.return_error (sprintf "Invalid events notification: %s" e)
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
    event_handler notification.event
  )

(** [process_slack_interaction] handles slack interactions which are
    similar to slack notifications except that they are specifically
    for handling features such as block actions, shortcuts and modals
*)
let process_slack_interaction (ctx : Context.t) headers body ~interaction_handler =
  match Uri.query_of_encoded body |> List.assoc "payload" with
  | [] -> Lwt.return_error "Empty payload"
  | payload :: _ ->
  match interaction_of_string payload with
  | exception Yojson.Json_error e -> Lwt.return_error (sprintf "Invalid interaction: %s, payload: %s" e payload)
  | interaction ->
  match validate_signature ?signing_key:ctx.secrets.slack_signing_secret ~headers body with
  | Error e -> Lwt.return_error (sprintf "signature not validated: %s" e)
  | Ok () -> interaction_handler interaction

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
  | conversation -> Error (`Other (sprintf "did not get valid conversation info for channel %s" conversation.id))

let show_channel_type = function
  | Channel -> "channel"
  | DirectMessage -> "direct message"
  | Group -> "group"

(** [ ApiHelpers Api_Impl] is a functor that wraps Api for simple functionalities such as sending texts *)
module ApiHelpers (Api : Api.S) = struct
  let send_text_msg ~ctx ~channel ~text =
    let msg = make_post_message_req ~channel ~text () in
    Api.send_message ~ctx ~msg

  let update_text_msg ~ctx ~channel ~update ~ts =
    let msg = make_update_message_req ~channel ~text:update ~ts () in
    Api.update_message ~ctx ~msg

  let send_text_msg_as_user ~ctx ~channel ~text ~username ?icon_url ?icon_emoji () =
    let msg = make_post_message_req ~channel ~text ~username ?icon_url ?icon_emoji () in
    Api.send_message ~ctx ~msg

  let get_channel_type ~(ctx : Context.t) ~channel =
    let conversation = make_conversations_info_req ~channel () in
    match%lwt Api.get_conversations_info ~ctx ~conversation with
    | Error e -> Lwt.return_error e
    | Ok ({ channel; _ } : conversations_info_res) -> Lwt.return @@ conversation_type_of_conversation channel
end
