{  (* Slack markdown format lexer *)
type token =
  | Word of string
  | Emoji of string
  | ChannelLink of string * string option (* channel ID, text *)
  | UserMention of string (* user ID *)
  | UserGroupMention of string (* group ID *)
  | SpecialMention of string (* special mention like !here, !everyone, etc. *)
  | UrlLink of string * string option (* URL, label *)
  | InlineCode of string
  | CodeBlock of string (* block *)
  | Colon
[@@deriving show]

exception EOF
}

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let letter   = ['A'-'Z' 'a'-'z']
let digit    = ['0'-'9']
let id_char  = letter | digit | '_'
let word = id_char+
let emoji = ':' [^':'' ' ]+ ':'

rule read =
  parse
  | white    { read lexbuf }
  | newline  { Lexing.new_line lexbuf; read lexbuf }
  | '`' ([^'`']* as inline) '`'  { InlineCode(inline) }
  | "```" ([^'`']* ('`' [^'`']+)* as block) "```"  { CodeBlock(block) }
  | '<' ("#C" ['A'-'Z''0'-'9']+ as id) ( "|" ([^'>']+ as text) )? '>' { ChannelLink(id, text) }
  | "<@" ['U' 'W']['0'-'9''A'-'Z']+ '>' as id { UserMention id }
  | "<!subteam^" ['A'-'Z''0'-'9']+ '>' as groupid { UserGroupMention groupid }
  | "<!" ['a'-'z''A'-'Z']+ '>' as content { SpecialMention content }
  | '<' ([^'>''|']+ as link) ( "|" ([^'>']+ as text) )? '>' { UrlLink(link, text) }
  | emoji as e { Emoji e }
  | word as w  { Word w }
  | ':'        { Colon }
  | eof { raise EOF }
  | _ {read lexbuf}
