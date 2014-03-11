" Vim syntax file
" FileType: Access log of IIS
" Author:   John Kugelman <jkugelman@progeny.net>
" Version:  0.5
" ---------------------------------------------------------------------

" For version 5.x: Clear all syntax items.
" For version 6.x: Quit when a syntax file was already loaded.
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syntax case match

" We need nocompatible mode in order to continue lines with backslashes.
" Original setting will be restored.
let s:cpo_save = &cpo
set cpo&vim

syn region  iislogComment         start='#' end='$' keepend contains=iislogHeader
syn region  iislogHeader          start='(Software|Version|Date|Fields): ' end='$' contained

syn match   iislogScStatus        '\v<\d{3}>'
syn match   iislogScStatus1xx     '\v<10[0-1]>'
syn match   iislogScStatus2xx     '\v<20[0-6]>'
syn match   iislogScStatus3xx     '\v<30[0-7]>'
syn match   iislogScStatus4xx     '\v<(40[0-9]|41[0-7])>'
syn match   iislogScStatus5xx     '\v<50[0-5]>'

syn match   iislogDate            '\v<\d{4}-\d{2}-\d{2}>'
syn match   iislogTime            '\v<\d{2}:\d{2}:\d{2}>'
syn keyword iislogCsMethod        GET POST HEAD PUT DELETE CONNECT OPTIONS PATCH TRACE
syn match   iislogCsUriStem       '\v/\S+' contains=iislogCsUriStemStatic
syn match   iislogCsUriStemStatic '\v\S+\.(html?|js|css|png|gif|jpe?g|swf|ico|xml|pdf|txt|docx?|xlsx?|pptx?)'
syn match   iislogCsUriQuery      '\v([?&;]?(\w|[\-._~+]|\%[[:xdigit:]]{2})+\=(\w|[\-._~+]|\%[[:xdigit:]]{2})*)+'
"syn match   iislogCsUsername      '\v\S+'
syn match   iislogCIp             '\v\d{1,3}(\.\d{1,3}){3}'                     contains=iislogCIpLocal,iislogCIpLan,iislogCIpHacker
syn match   iislogCIpLan          '\v<192\.168\.\d+\.\d+>'                      contained
syn match   iislogCIpLan          '\v<172\.(1[6-9]|2[0-9]|3[01])\.\d+\.\d+>'    contained
syn match   iislogCIpLan          '\v<10\.\d+\.\d+\.\d+>'                       contained
syn match   iislogCIpLocal        '\V\<127.0.0.1\>'                             contained
syn match   iislogCIpLocal        '\V::1\>'                                     contained
syn match   iislogCIpHacker       '\V\<171.217.31.48\>'                         contained
syn match   iislogCIpHacker       '\V\<174.120.168.130\>'                       contained
syn match   iislogCIpHacker       '\V\<204.11.212.144\>'                        contained
syn match   iislogCIpHacker       '\V\<204.11.212.145\>'                        contained
syn match   iislogCIpHacker       '\V\<208.106.153.54\>'                        contained
syn match   iislogCIpHacker       '\V\<208.106.153.55\>'                        contained
syn match   iislogCIpHacker       '\V\<208.106.153.58\>'                        contained
syn match   iislogCIpHacker       '\V\<27.115.121.40\>'                         contained
syn match   iislogCIpHacker       '\V\<60.2.93.68\>'                            contained
syn match   iislogCIpHacker       '\V\<64.238.147.58\>'                         contained
syn match   iislogCIpHacker       '\V\<66.63.181.96\>'                          contained
syn match   iislogCIpHacker       '\V\<74.3.208.34\>'                           contained
syn match   iislogCIpHacker       '\V\<76.74.255.174\>'                         contained
syn match   iislogCIpHacker       '\V\<97.74.193.235\>'                         contained
syn match   iislogCsVersion       '\vHTTP/\S+'
syn match   iislogCsUserAgent     '\v<Mozilla/\S*' contains=iislogCsBrowser
syn match   iislogCsBrowser       '\v<(MSIE|Firefox|Chrome|Safari|Google Web Preview|Feedfetcher-Google|bingbot|Sogou web spider|UCWEB\d)>([+/](\d+\.\d))?' contained
syn match   iislogCsReferer       '\v<(https?|ftp)://\S+'
syn match   iislogScBytes         '\v<\d+>$'

hi link iislogComment         Comment
hi link iislogHeaderSoftware  Identifier
hi link iislogHeaderVersion   Identifier
hi link iislogHeaderDate      Identifier
hi link iislogHeaderFields    Identifier
hi link iislogDate            Number
hi link iislogTime            Number
hi link iislogCsMethod        Keyword
hi link iislogCsUriStem       Identifier
hi link iislogCsUriStemStatic Normal
hi link iislogCsUriQuery      Type
hi link iislogCsUsername      Normal
hi link iislogCIp             Number
hi link iislogCIpLan          PreProc
hi link iislogCIpLocal        PreProc
hi link iislogCIpHacker       Error
hi link iislogCsVersion       Normal
hi link iislogCsUserAgent     Normal
hi link iislogCsBrowser       Statement
hi link iislogCsReferer       Type
hi link iislogScStatus        Error
hi link iislogScStatus1xx     Number
hi link iislogScStatus2xx     Number
hi link iislogScStatus3xx     Number
hi link iislogScStatus4xx     Todo
hi link iislogScStatus5xx     Error
hi link iislogScBytes         Number

let b:current_syntax = "iislog"

let &cpo = s:cpo_save
unlet s:cpo_save
