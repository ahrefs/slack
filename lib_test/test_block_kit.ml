open Slack_lib.Block_kit_safe

let () =
  let label = make_plain_text ~text:"hello" () in
  let element = make_plain_text_input () in
  make_input ~label ~element () |> string_of_block |> Yojson.Basic.prettify |> print_endline

let string_of_todo_list_ids ~project_id ~todo_list_id = Printf.sprintf "%d.%d" project_id todo_list_id

type todo_list_option = {
  id : int;
  project_id : int;
  label : string;
}
[@@deriving make]

let make_modal_v2 (todo_list_options : todo_list_option list) =
  let open Slack_lib.Block_kit_safe in
  let modal_blks =
    let todo_list_select_menu_blk =
      let static_select_menu =
        let options =
          List.map
            (fun (todo_list : todo_list_option) ->
              let value = string_of_todo_list_ids ~project_id:todo_list.project_id ~todo_list_id:todo_list.id in
              let text = Plain_text (make_plain_text ~text:todo_list.label ()) in
              make_option_object ~text ~value ()
            )
            todo_list_options
        in
        let initial_option = List.hd options in
        make_static_select_menu ~initial_option ~options ()
      in
      let label = make_plain_text ~text:"Todo-list" () in
      make_input ~label ~element:static_select_menu ()
    in

    let todo_name_blk =
      let plain_text_input = make_plain_text_input () in
      let label = make_plain_text ~text:"Name" () in
      make_input ~label ~element:plain_text_input ()
    in

    let todo_description_blk =
      let plain_text_input = make_plain_text_input ~multiline:true () in
      let label = make_plain_text ~text:"Description" () in
      make_input ~label ~element:plain_text_input ()
    in

    (* Block list *)
    [ todo_list_select_menu_blk; todo_name_blk; todo_description_blk ]
  in

  string_of_blocks modal_blks

let () =
  make_modal_v2
    [
      { id = 1; project_id = 1; label = "todolist1" };
      { id = 2; project_id = 2; label = "todolist2" };
      { id = 3; project_id = 3; label = "todolist3" };
    ]
  |> Yojson.Basic.prettify
  |> print_endline
