open ExtLib
open Printf

(** Mrkdwn formatting https://api.slack.com/reference/surfaces/formatting#basics *)
let escape_mrkdwn =
  String.replace_chars (function
    | '<' -> "&lt;"
    | '>' -> "&gt;"
    | '&' -> "&amp;"
    | c -> String.make 1 c
    )

let escaped_mrkdwn_re = Re2.create_exn {|(?P<escaped>&lt;|&gt;|&amp;)|}

let unescape_mrkdwn str =
  try
    Re2.replace_exn escaped_mrkdwn_re str ~f:(fun m ->
      match Re2.Match.get_exn m ~sub:(`Name "escaped") with
      | "&lt;" -> "<"
      | "&gt;" -> ">"
      | "&amp;" -> "&"
      | e -> Common.slack_lib_fail "impossible re2 mrkdwn unescape match: %s" e
    )
  with Re2.Exceptions.Regex_match_failed _ -> str

let link ~url ?text () =
  match text with
  | Some text -> sprintf "<%s|%s>" url text
  | None -> sprintf "<%s>" url

let bold = sprintf "*%s*"
let italicize = sprintf "_%s_"
let strike = sprintf "~%s~"
let line_break = sprintf "%s\n"
let blk_quote = sprintf ">%s"
let inline_code = sprintf "`%s`"
let multiline_code = sprintf "```%s```"
let list l = sprintf "- %s" (String.concat "\n- " l)

(* https://api.slack.com/reference/surfaces/formatting#mentioning-users *)
let mention_user member_id = sprintf "<@%s>" member_id

(* https://api.slack.com/reference/surfaces/formatting#mentioning-groups *)
let mention_usergroup group_id = sprintf "<!subteam^%s>" group_id
let mention_re = Re2.create_exn {|\B@[a-zA-Z0-9][a-zA-Z0-9._-]*|}

let highlight_mentions get_id_by_slack_name s =
  let subst s =
    String.lchop s
    |> get_id_by_slack_name
    |> Option.map (function
      | `User u -> mention_user u
      | `Group g -> mention_usergroup g
      )
    |> Option.default s
  in
  Re2.replace_exn mention_re s ~f:(fun m -> subst (Re2.Match.get_exn ~sub:(`Index 0) m))
