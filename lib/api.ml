open Slack_t

(** APIs signatures--necessary to split the actual implementation in api_remote.ml and mock
    implementation in api_local.ml *)
module type S = sig
  (* messaging *)
  val send_chat_unfurl : ctx:Context.t -> req:chat_unfurl_req -> unit slack_response Lwt.t
  val send_message : ctx:Context.t -> msg:post_message_req -> post_message_res slack_response Lwt.t
  val send_message_webhook : ctx:Context.t -> url:string -> msg:post_message_req -> unit slack_response Lwt.t
  val update_message : ctx:Context.t -> msg:update_message_req -> update_message_res slack_response Lwt.t

  val upload_file : ctx:Context.t -> file:files_upload_req -> files_upload_res slack_response Lwt.t
  [@@deprecated
    "Use get_upload_url_external with complete_upload_external as per \
     https://api.slack.com/messaging/files#uploading_files. Otherwise, there is upload_file_v2 convenience function"]

  val get_permalink : ctx:Context.t -> req:get_permalink_req -> get_permalink_res slack_response Lwt.t

  val get_upload_url_external :
     ctx:Context.t ->
    req:get_upload_url_ext_req ->
    get_upload_url_ext_res slack_response Lwt.t

  val complete_upload_external :
     ctx:Context.t ->
    req:complete_upload_ext_req ->
    complete_upload_ext_res slack_response Lwt.t

  val upload_file_v2 : ctx:Context.t -> file:files_upload_req -> files_upload_res slack_response Lwt.t

  (* conversations *)
  val get_replies :
     ctx:Context.t ->
    conversation:conversations_replies_req ->
    conversations_replies_res slack_response Lwt.t

  val get_history :
     ctx:Context.t ->
    conversation:conversations_history_req ->
    conversations_history_res slack_response Lwt.t

  val get_conversations_info :
     ctx:Context.t ->
    conversation:conversations_info_req ->
    conversations_info_res slack_response Lwt.t

  val join_conversation : ctx:Context.t -> channel:conversations_join_req -> conversations_join_res slack_response Lwt.t

  (* usergroups *)
  val update_usergroup_users :
     ctx:Context.t ->
    usergroup:update_usergroups_users_req ->
    update_usergroups_users_res slack_response Lwt.t

  val list_usergroups : ctx:Context.t -> req:list_usergroups_req -> list_usergroups_res slack_response Lwt.t

  val list_usergroup_users :
     ctx:Context.t ->
    usergroup:list_usergroup_users_req ->
    list_usergroup_users_res slack_response Lwt.t

  (* users *)
  val get_user : ctx:Context.t -> user:user_info_req -> user_info_res slack_response Lwt.t
  val list_users : ctx:Context.t -> req:list_users_req -> list_users_res slack_response Lwt.t

  (* bookmarks *)
  val add_bookmark : ctx:Context.t -> req:add_bookmark_req -> add_bookmark_res slack_response Lwt.t
  val edit_bookmark : ctx:Context.t -> req:edit_bookmark_req -> edit_bookmark_res slack_response Lwt.t
  val list_bookmarks : ctx:Context.t -> req:list_bookmarks_req -> list_bookmarks_res slack_response Lwt.t
  val remove_bookmark : ctx:Context.t -> req:remove_bookmark_req -> remove_bookmark_res slack_response Lwt.t

  (* views *)
  val open_views : ctx:Context.t -> req:open_views_req -> open_views_res slack_response Lwt.t
  val push_views : ctx:Context.t -> req:push_views_req -> push_views_res slack_response Lwt.t
  val update_views : ctx:Context.t -> req:update_views_req -> update_views_res slack_response Lwt.t

  (* misc *)
  val send_auth_test : ctx:Context.t -> unit -> auth_test_res slack_response Lwt.t
end
