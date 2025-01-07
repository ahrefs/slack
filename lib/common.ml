open Devkit
open ExtLib

exception Slack_lib_error of string

let slack_lib_fail fmt = Printf.ksprintf (fun e -> raise (Slack_lib_error e)) fmt

let http_request ?ua ?headers ?body meth path =
  match%lwt Web.http_request_lwt ?ua ~verbose:true ?headers ?body meth path with
  | `Ok s -> Lwt.return_ok s
  | `Error e -> Lwt.return_error e

let get_local_file path =
  try Std.input_file path
  with exn -> slack_lib_fail "unable to get local file from %s because:\n%s" path (Exn.to_string exn)

let get_local_file_with ~f path = f @@ get_local_file path

let get_sorted_files_from dir =
  let files = Sys.readdir dir in
  Array.sort String.compare files;
  Array.to_list files

let sign_string_sha256 ~key ~basestring = Digestif.SHA256.(hmac_string ~key basestring |> to_hex)
