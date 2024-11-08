include Block_kit_j

(******************* Objects ***********************)

let make_plain_text' ~text ?emoji () = Block_kit_j.(Plain_text (make_plain_text ~text ?emoji ()))
let make_mrkdwn_text' ~text ?verbatim () = Block_kit_j.(Mrkdwn (make_mrkdwn_text ~text ?verbatim ()))

let make_option_group ~(label : plain_text) ?(options : option_object list option) =
  Block_kit_j.make_option_group ~label:(Plain_text label) ?options

let make_option_object ~text ~value ?(description : plain_text option) url =
  let description = Option.map (fun v -> Plain_text v) description in
  Block_kit_j.make_option_object ~text ~value ?description url

let make_conversation_dialog_object ~(title : plain_text) ~(text : plain_text) ~(confirm : plain_text)
  ~(deny : plain_text) url
  =
  Block_kit_j.make_confirmation_dialog_object ~title:(Plain_text title) ~text:(Plain_text text)
    ~confirm:(Plain_text confirm) ~deny:(Plain_text deny) url

(******************* Elements ***********************)

let make_multi_users_select_menu ?action_id ?initial_users ?confirm ?max_selected_items ?focus_on_load
  ?(place_holder : plain_text option) ()
  =
  let place_holder =
    Option.map
      (fun (v : plain_text) ->
        if String.length v.text >= 150 then
          raise (Invalid_argument (Printf.sprintf "text limit 150char exceeded: %s" v.text));
        Plain_text v
      )
      place_holder
  in
  Block_kit_j.(
    Multi_users_select_menu
      (make_multi_users_select_menu ?action_id ?initial_users ?confirm ?max_selected_items ?focus_on_load ?place_holder
         ()
      )
  )

let make_multi_static_select_menu ?action_id ~(options : option_object list)
  ?(initial_option : option_object list option) ?confirm ?max_selected_items ?focus_on_load
  ?(place_holder : plain_text option) ()
  =
  List.iter
    (fun (o : option_object) ->
      let o_str = string_of_option_object o in
      if String.length o_str > 75 then
        raise (Invalid_argument (Printf.sprintf "option_object limit 75char exceeded: %s" o_str))
    )
    options;
  let place_holder =
    Option.map
      (fun (v : plain_text) ->
        if String.length v.text >= 150 then
          raise (Invalid_argument (Printf.sprintf "text limit 150char exceeded: %s" v.text));
        Plain_text v
      )
      place_holder
  in
  let initial_option = Option.map (fun v -> List.map (fun o -> Option_object o) v) initial_option in
  Block_kit_j.(
    Multi_static_select_menu
      (make_multi_static_select_menu ?action_id ~options ?inital_options:initial_option ?confirm ?max_selected_items
         ?focus_on_load ?place_holder ()
      )
  )

let make_multi_static_select_menu_group ?action_id ~(option_groups : option_group list)
  ?(initial_option : option_group list option) ?confirm ?max_selected_items ?focus_on_load
  ?(place_holder : plain_text option) ()
  =
  let place_holder =
    Option.map
      (fun (v : plain_text) ->
        if String.length v.text >= 150 then
          raise (Invalid_argument (Printf.sprintf "text limit 150char exceeded: %s" v.text));
        Plain_text v
      )
      place_holder
  in
  let initial_option = Option.map (fun v -> List.map (fun o -> Option_group o) v) initial_option in
  Block_kit_j.(
    Multi_static_select_menu
      (make_multi_static_select_menu ?action_id ~option_groups ?inital_options:initial_option ?confirm
         ?max_selected_items ?focus_on_load ?place_holder ()
      )
  )

let make_static_select_menu ?action_id ~(options : option_object list) ?(initial_option : option_object option) ?confirm
  ?focus_on_load ?(place_holder : plain_text option) ()
  =
  if List.length options > 100 then raise (Invalid_argument "option objects limit 100 exceeded");
  let place_holder =
    Option.map
      (fun (v : plain_text) ->
        if String.length v.text >= 150 then
          raise (Invalid_argument (Printf.sprintf "text limit 150char exceeded: %s" v.text));
        Plain_text v
      )
      place_holder
  in
  let initial_option = Option.map (fun o -> Option_object o) initial_option in
  Block_kit_j.(
    Static_select_menu
      (make_static_select_menu ?action_id ~options ?initial_option ?confirm ?focus_on_load ?place_holder ())
  )

let make_static_select_menu_group ?action_id ~(option_groups : option_group list)
  ?(initial_option : option_group option) ?confirm ?focus_on_load ?(place_holder : plain_text option) ()
  =
  if List.length option_groups > 100 then raise (Invalid_argument "option objects limit 100 exceeded");
  let place_holder =
    Option.map
      (fun (v : plain_text) ->
        if String.length v.text >= 150 then
          raise (Invalid_argument (Printf.sprintf "text limit 150char exceeded: %s" v.text));
        Plain_text v
      )
      place_holder
  in
  let initial_option = Option.map (fun o -> Option_group o) initial_option in
  Block_kit_j.(
    Static_select_menu
      (make_static_select_menu ?action_id ~option_groups ?initial_option ?confirm ?focus_on_load ?place_holder ())
  )

let make_plain_text_input ?action_id ?initial_value ?multiline ?min_length ?max_length ?dispatch_action_config
  ?focus_on_load ?place_holder ()
  =
  Block_kit_j.(
    Plain_text_input
      (make_plain_text_input ?action_id ?initial_value ?multiline ?min_length ?max_length ?dispatch_action_config
         ?focus_on_load ?place_holder ()
      )
  )

let make_button ~(text : plain_text) ?action_id ?url ?value ?style ?confirm ?accessibility_label () =
  if String.length text.text > 75 then
    raise (Invalid_argument (Printf.sprintf "text limit 150char exceeded: %s" text.text));
  Block_kit_j.(
    Button (make_button ~text:(Plain_text text) ?action_id ?url ?value ?style ?confirm ?accessibility_label ())
  )

(******************* Blocks ***********************)

let make_divider ?block_id () = Block_kit_j.(Divider (make_divider ?block_id ()))

let make_input ~(label : plain_text) ~element ?dispatch_action ?block_id ?(hint : plain_text option) ?optional () =
  let label =
    if String.length label.text > 2000 then
      raise (Invalid_argument (Printf.sprintf "text limit 2000char exceeded: %s" label.text));
    Plain_text label
  in
  let hint =
    Option.map
      (fun (hint : plain_text) ->
        if String.length hint.text > 2000 then
          raise (Invalid_argument (Printf.sprintf "text limit 2000char exceeded: %s" hint.text));
        Plain_text hint
      )
      hint
  in
  Block_kit_j.(Input (make_input ~label ~element ?dispatch_action ?block_id ?hint ?optional ()))

let make_section ?(text : text_object option) ?block_id ?fields ?accessory ?expand () =
  Block_kit_j.(Section (make_section ?text ?block_id ?fields ?accessory ?expand ()))

(******************* Views ***********************)

let make_modal ~(title : plain_text) ~blocks ?(close : plain_text option) ?(submit : plain_text option)
  ?(private_metadata : string option) ?(callback_id : string option) ?(clear_on_close : bool option)
  ?(notify_on_close : bool option) ?(external_id : string option) ?(submit_disabled : bool option) ()
  =
  let validate_plain_text (plain_text : plain_text) =
    if String.length plain_text.text > 24 then
      raise (Invalid_argument (Printf.sprintf "text limit 24char exceeded: %s" plain_text.text));
    Plain_text plain_text
  in
  let title = validate_plain_text title in
  let close = Option.map (fun (v : plain_text) -> validate_plain_text v) close in
  let submit = Option.map (fun (v : plain_text) -> validate_plain_text v) submit in
  Block_kit_j.(
    Modal
      (make_modal ~title ~blocks ?close ?submit ?private_metadata ?callback_id ?clear_on_close ?notify_on_close
         ?external_id ?submit_disabled ()
      )
  )
