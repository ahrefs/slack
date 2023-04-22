open Slack_lib
open Devkit
open Printf

let log = Log.from "get_info_example"

module Api = Api_remote

let get_user user =
  let run =
    let user : Slack_t.user_info_req = { user; include_locale = None } in
    match%lwt Api.get_user ~user ~ctx:Common_example.get_ctx_example with
    | Ok res ->
      printf "user %s got:\n %s\n" user.user (Slack_j.string_of_user_info_res res);
      Lwt.return_unit
    | Error e ->
      printf "unable to get user %s info:\n%s\n" user.user (Slack_j.string_of_slack_api_error e);
      Lwt.return_unit
  in
  Lwt_main.run run

let get_conversation channel =
  let run =
    let conversation : Slack_t.conversations_info_req =
      { channel; include_locale = None; include_num_members = None }
    in
    match%lwt Api.get_conversations_info ~conversation ~ctx:Common_example.get_ctx_example with
    | Ok res ->
      printf "channel %s got:\n %s\n" channel (Slack_j.string_of_conversations_info_res res);
      Lwt.return_unit
    | Error e ->
      printf "unable to get channel %s info:\n%s\n" channel (Slack_j.string_of_slack_api_error e);
      Lwt.return_unit
  in
  Lwt_main.run run

let get_replies channel ts =
  let run =
    let conversation : Slack_t.conversations_replies_req = { Utils.empty_conversations_replies_req with channel; ts } in
    match%lwt Api.get_replies ~conversation ~ctx:Common_example.get_ctx_example with
    | Ok res ->
      printf "channel %s at ts %s got:\n %s\n" channel ts (Slack_j.string_of_conversations_replies_res res);
      Lwt.return_unit
    | Error `Not_in_channel ->
      printf "Cannot get channel %s info because you are not in the channel\n" channel;
      Lwt.return_unit
    | Error e ->
      printf "unable to get channel %s at ts %s info:\n%s\n" channel ts (Slack_j.string_of_slack_api_error e);
      Lwt.return_unit
  in
  Lwt_main.run run
