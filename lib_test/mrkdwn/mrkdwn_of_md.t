bold
  $ mrkdwn_of_md << "MD"
  > **bold**
  > __bold__
  > MD
  *bold*
  *bold*

italic
  $ mrkdwn_of_md << "MD"
  > *italic*
  > _italic_
  > MD
  _italic_
  _italic_


strikethrough
  $ mrkdwn_of_md << "MD"
  > ~~strike~~
  > ~strike~
  > MD
  ~strike~
  ~strike~

link
  $ mrkdwn_of_md << "MD"
  > [hello](https://google.be)
  > MD
  <https://google.be|hello>
