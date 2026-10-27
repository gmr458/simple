" Vim filetype plugin
" Language: Caddyfile
" Maintainer: gmr458
" Last Change: 2026 Oct 26

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

setlocal commentstring=#\ %s
setlocal comments=:#
setlocal formatoptions-=t

let b:undo_ftplugin = 'setlocal commentstring< comments< formatoptions<'

let &cpo = s:cpo_save
unlet s:cpo_save
