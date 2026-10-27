" Vim indent file
" Language: Caddyfile
" Maintainer: gmr458
" Last Change: 2026 Oct 26

" Only load this indent file when no other was loaded.
if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetCaddyfileIndent()
setlocal indentkeys=0{,0},0#,!^F,o,O
setlocal nolisp
setlocal nosmartindent

let b:undo_indent = 'setlocal indentexpr< indentkeys< lisp< smartindent<'

" Only define the functions once.
if exists('*GetCaddyfileIndent')
  finish
endif

" Return the previous line that is not blank, a comment, or part of a heredoc.
function s:PrevCodeLine(lnum) abort
  let lnum = prevnonblank(a:lnum)
  while lnum > 0
    let line = getline(lnum)
    if line !~# '^\s*#' && !s:IsHeredocLine(lnum)
      break
    endif
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
endfunction

" Remove a trailing comment from {line}.
function s:StripComment(line) abort
  return substitute(a:line, '\%(^\|\s\)\zs#.*$', '', '')
endfunction

" Check whether {line} ends with {pat}, ignoring a trailing comment.
function s:EndsWith(line, pat) abort
  return a:line =~# a:pat . '\s*\%(#.*\)\?$'
endfunction

" Return the line number of the block opener matching the closing brace on
" {lnum}, or 0 if there is none.
function s:BlockOpen(lnum) abort
  let stack = []
  let marker = ''
  let closed = 0
  let lnum = 1

  while lnum <= a:lnum
    let line = getline(lnum)

    " Skip heredoc contents and closing markers.
    if marker != ''
      if line =~# '^\s*' . escape(marker, '\.*$^~[]') . '\s*$'
        let marker = ''
      endif
      let lnum += 1
      continue
    endif

    let code = s:StripComment(line)

    " A heredoc opener ends the line, so anything after it is literal.
    let m = matchlist(code, '\%(^\|\s\)<<\([A-Za-z0-9_-]\+\)\s*$')
    if !empty(m)
      let marker = m[1]
      let lnum += 1
      continue
    endif

    if code =~# '^\s*}'
      if !empty(stack)
        let closed = remove(stack, -1)
      endif
    endif
    if code =~# '{\s*$'
      call add(stack, lnum)
    endif

    if lnum == a:lnum
      return code =~# '^\s*}' ? closed : (empty(stack) ? 0 : stack[-1])
    endif

    let lnum += 1
  endwhile

  return 0
endfunction

" Return the indentation level a block is based at.  When {lnum} opens a block
" that is part of a comma-separated list (site addresses), the block is based
" at the first line of the list rather than at the continued line.
function s:BlockBase(lnum) abort
  let lnum = a:lnum
  let plnum = s:PrevCodeLine(lnum - 1)

  while plnum > 0 && s:EndsWith(getline(plnum), ',')
    let lnum = plnum
    let plnum = s:PrevCodeLine(lnum - 1)
  endwhile

  return indent(lnum)
endfunction

" Return information about the heredoc containing {lnum}.
"
" The result is [inside, opener, marker, closing]:
"   inside  - {lnum} is a heredoc content line
"   opener  - line number of the heredoc's opening line (0 if none)
"   marker  - the heredoc marker
"   closing - {lnum} is the heredoc's closing marker line
function s:HeredocInfo(lnum) abort
  let opener = 0
  let marker = ''
  let lnum = 1

  while lnum < a:lnum
    let line = getline(lnum)
    if marker != ''
      if line =~# '^\s*' . escape(marker, '\.*$^~[]') . '\s*$'
        let marker = ''
        let opener = 0
      endif
    else
      " Ignore comments when looking for a heredoc opener.
      let code = s:StripComment(line)
      let m = matchlist(code, '\%(^\|\s\)<<\([A-Za-z0-9_-]\+\)\s*$')
      if !empty(m)
        let marker = m[1]
        let opener = lnum
      endif
    endif
    let lnum += 1
  endwhile

  if marker == ''
    return [0, 0, '', 0]
  endif

  let closing = getline(a:lnum) =~# '^\s*' . escape(marker, '\.*$^~[]') . '\s*$'
  return [!closing, opener, marker, closing]
endfunction

" Check whether {lnum} is a heredoc content line or closing marker.
function s:IsHeredocLine(lnum) abort
  let info = s:HeredocInfo(a:lnum)
  return info[0] || info[3]
endfunction

function GetCaddyfileIndent() abort
  let lnum = v:lnum
  let line = getline(lnum)

  " Do not reindent heredoc contents or the closing marker. They are literal
  " text and their indentation determines what Caddy strips from the content.
  let heredoc = s:HeredocInfo(lnum)
  if heredoc[0] || heredoc[3]
    return -1
  endif

  let plnum = s:PrevCodeLine(lnum - 1)

  " Hit the start of the file, use zero indent.
  if plnum == 0
    return 0
  endif

  let ind = indent(plnum)
  let prev = getline(plnum)
  let pplnum = s:PrevCodeLine(plnum - 1)
  let pprev = pplnum > 0 ? getline(pplnum) : ''
  let sw = shiftwidth()

  " Align a closing brace with the line that opened its block.
  if line =~# '^\s*}'
    let opener = s:BlockOpen(lnum)
    return opener > 0 ? s:BlockBase(opener) : (ind >= sw ? ind - sw : 0)
  endif

  if prev =~# '^\s*}'
    " Continue at the level the closed block was based at.
    let opener = s:BlockOpen(plnum)
    if opener > 0
      let ind = s:BlockBase(opener)
    endif
  " Add a shiftwidth after an opening brace.
  elseif s:EndsWith(prev, '{')
    let ind += sw
  " Continue a list of site addresses over multiple lines.
  elseif s:EndsWith(prev, ',')
    if !s:EndsWith(pprev, ',')
      let ind += sw
    endif
  " Continue an escaped (backslash) line.
  elseif s:EndsWith(prev, '\\')
    if !s:EndsWith(pprev, '\\')
      let ind += sw
    endif
  " Return from an escaped line continuation.
  elseif s:EndsWith(pprev, '\\')
    let ind -= sw
  endif

  return ind < 0 ? 0 : ind
endfunction
