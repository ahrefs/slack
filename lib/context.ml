open Common

type t = {
  ua : string;
  secrets : Config_t.secrets;
}

let make_secrets ?slack_access_token ?slack_signing_secret () : Config_t.secrets =
  { slack_access_token; slack_signing_secret }

let make ~ua ~secrets = { ua; secrets }

let get_secrets path =
  let secrets = get_local_file_with path ~f:Config_j.secrets_of_string in
  match secrets.slack_access_token with
  | None -> slack_lib_fail "slack_access_token is not defined in file '%s'" path
  | _ -> secrets

let get_ctx ?(secrets_path = "secrets.json") ?(ua = "slack_api") () = make ~ua ~secrets:(get_secrets secrets_path)

let empty_ctx () = make ~ua:"slack_api" ~secrets:(make_secrets ())
