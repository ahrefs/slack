open Slack_lib
open Devkit
open Printf

let log = Log.from "common_example"

module Utils = Utils.ApiHelpers (Api_remote)

let get_ctx_example = Context.get_ctx ~secrets_path:"secrets.json" ()

let setup_http ~ctx ~port ~ip handler =
  let open Httpev in
  let connection = Unix.ADDR_INET (ip, port) in
  let%lwt () =
    Httpev.setup_lwt { default with name = "example server"; connection; access_log_enabled = false }
      (fun _http request ->
         let module Arg = Args (struct
             let req = request
           end)
         in
         let body r = Lwt.return (`Body r) in
         let ret ?(status = `Ok) ?(typ = "text/plain") ?extra r =
           let%lwt r = r in
           body @@ serve ~status ?extra request typ r
         in
         let ret_err status s = body @@ serve_text ~status request s in
         try%lwt
           let path =
             match Stre.nsplitc request.path '/' with
             | "" :: p -> p
             | _ -> Exn.fail "you are on a wrong path"
           in
           match%lwt handler ctx request path with
           | Ok s -> ret @@ Lwt.return s
           | Error e -> ret_err `Not_found e
         with
         | Arg.Bad s ->
           log#error "bad parameter %S : %s" s (Httpev.show_request request);
           ret_err `Not_found (sprintf "bad parameter %s" s)
         | exn ->
           log#error ~exn "internal error : %s" (Httpev.show_request request);
           ret_err `Internal_server_error
             ( match exn with
             | Failure s -> s
             | Invalid_argument s -> s
             | exn -> Exn.str exn
             )
    )
  in
  Lwt.return_unit

(* running the http server *)
let run_server ~ctx ~addr ~port ~handler =
  let ip = Unix.inet_addr_of_string addr in
  setup_http ~ctx ~port ~ip handler
