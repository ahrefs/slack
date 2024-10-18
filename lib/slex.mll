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
[@@deriving show]

exception EOF
}

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let word = [^ ' ' '\t' '\n' '\r' ]+
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
  | eof { raise EOF }
