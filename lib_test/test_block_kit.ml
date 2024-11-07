open Slack_lib.Block_kit_safe

let () =
  let label = make_plain_text ~text:"hello" () in
  let element = make_plain_text_input () in
  make_input ~label ~element () |> string_of_input |> Yojson.Basic.prettify |> print_endline
