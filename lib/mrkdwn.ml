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

module Cmarkit_slack = struct
  let renderer =
    (* https://www.markdownguide.org/tools/slack/#slack-markdown-support-in-posts *)
    (* https://slack.com/intl/en-gb/help/articles/202288908-Format-your-messages *)
    let inline c inline =
      let open Cmarkit in
      let module C = Cmarkit_renderer.Context in
      let strong_emphasis c e =
        let i = Inline.Emphasis.inline e in
        C.byte c '*';
        C.inline c i;
        C.byte c '*'
      in
      let emphasis c e =
        let i = Inline.Emphasis.inline e in
        C.byte c '_';
        C.inline c i;
        C.byte c '_'
      in
      let strikethrough c s =
        let i = Inline.Strikethrough.inline s in
        C.byte c '~';
        C.inline c i;
        C.byte c '~'
      in
      let link c l =
        match Inline.Link.reference l with
        | `Inline (ld, _) ->
          begin
            match Link_definition.dest ld with
            | None -> C.inline c (Inline.Link.text l)
            | Some (dest, _) ->
              C.byte c '<';
              C.string c dest;
              C.byte c '|';
              C.inline c (Inline.Link.text l);
              C.byte c '>'
          end;
          true
        | _ -> false
      in
      match inline with
      | Inline.Strong_emphasis (e, _) ->
        strong_emphasis c e;
        true
      | Inline.Emphasis (e, _) ->
        emphasis c e;
        true
      | Inline.Ext_strikethrough (s, _) ->
        strikethrough c s;
        true
      | Inline.Link (l, _) -> link c l
      | _ -> false (* let the default renderer handle that *)
    in
    let block c block =
      let open Cmarkit in
      let module C = Cmarkit_renderer.Context in
      match block with
      | Block.Heading (heading, _) ->
        let inline = Block.Heading.inline heading in
        C.byte c '*';
        C.inline c inline;
        C.byte c '*';
        C.byte c '\n';
        true
      | _ -> false
    in
    let default_renderer = Cmarkit_commonmark.renderer () in
    let renderer = Cmarkit_renderer.make ~inline ~block () in
    Cmarkit_renderer.compose default_renderer renderer
end

let of_doc = Cmarkit_renderer.doc_to_string Cmarkit_slack.renderer
