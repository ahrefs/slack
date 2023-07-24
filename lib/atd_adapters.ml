(** Error detection in Slack API response. The web API communicates errors using
    an [error] field rather than status codes. Note, on the other hand, that
    webhooks do use status codes to communicate errors. *)
module Slack_response_adapter : Atdgen_runtime.Json_adapter.S = struct
  let normalize (x : Yojson.Safe.t) =
    match x with
    | `Assoc fields -> begin
      match List.assoc "ok" fields with
      | `Bool true -> `List [ `String "Ok"; x ]
      | `Bool false -> begin
        match List.assoc "error" fields with
        | `String msg -> `List [ `String "Error"; `String msg ]
        | _ -> x
      end
      | _ | (exception Not_found) -> x
    end
    | _ -> x

  let restore (x : Yojson.Safe.t) =
    let mk_fields ok fields = ("ok", `Bool ok) :: List.filter (fun (k, _) -> k <> "ok") fields in
    match x with
    | `List [ `String "Ok"; `Assoc fields ] -> `Assoc (mk_fields true fields)
    | `List [ `String "Error"; `String msg ] -> `Assoc (mk_fields false [ "error", `String msg ])
    | _ -> x
end

module Unfurl_adapter : Atdgen_runtime.Json_adapter.S = struct
  let normalize (x : Yojson.Safe.t) =
    match x with
    | `Assoc fields -> begin
      match List.assoc "blocks" fields with
      | `Bool true -> `List [ `String "Blocks"; x ]
      | `Bool false -> `List [ `String "Message_attachment"; x ]
      | _ | (exception Not_found) -> x
    end
    | _ -> x

  let restore (x : Yojson.Safe.t) =
    match x with
    | `List [ `String "Blocks"; `Assoc fields ] -> `Assoc fields
    | `List [ `String "Message_attachment"; `Assoc fields ] -> `Assoc fields
    | _ -> x
end
