let () = print_string (Cmarkit.Doc.of_string ~strict:false (In_channel.input_all stdin) |> Slack_lib.Mrkdwn.of_doc)
