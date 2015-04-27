" ksslint.vim - A KSS code lint and fix
" Maintainer:   Alexander Fedorov fedorov7@gmail.com
" Version:      0.1

if exists('g:loaded_ksslint') || &cp
  finish
endif
let g:loaded_ksslint = 1

function! s:OkMessage(message)
  :echohl Special
  :echo a:message
  :echohl None
endfun

function! KssLint()
  try
    :%s/DEBUG\s*((\_.\=\s*EFI_D_\(\w\+\),\s\=\("\p\+"\),\s\=\(\p\+\)))/DBG_\1\ (\2,\ \3)/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("DEBUG macros is OK")
  endtry

  try
    :%s/\(DEBUG\s*((\_.\=\s*EFI_D_\)\(\w\+\),\s\=\("\p\+"\)))/DBG_\21\ (\3)/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("DEBUG short macros is OK")
  endtry

  try
    :%s/\s\+$//gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Trailing characters not found")
  endtry

  try
    :%s/\t/\ \ /gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Tabular characters not found")
  endtry

  try
    :%s/\(\w\)(/\1\ (/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Function-Bracer spaces is OK")
  endtry

"  try
"    :%s/\(\u\)\s\+(/\1(/gc
"  catch /\m^Vim\%((\a\+)\)\=:E486/
"    call s:OkMessage("Macros-Bracer spaces is OK")
"  endtry

  try
    :%s/(\s\+\(\w\+\)/(\1/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Left Bracer is OK")
  endtry

  try
    :%s/\(\w\+\)\s\+)/\1)/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Rigth Bracer is OK")
  endtry

  try
    :%s/\[\s\+\(\w\+\)/\[\1/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Left Bracket is OK")
  endtry

  try
    :%s/\(\w\+\)\s\+\]/\1\]/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Rigth Bracket is OK")
  endtry

  try
    :%s/\(\s*\)\(if\s*(\p\+)\)\s*\n\([^{]\+\)\n/\1\2\ \{\r\3\r\1\}\r/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("if bracket is OK")
  endtry

  try
    :%s/\(}\)\s*\n\s*else/\1\ else/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("if .. else bracket is OK")
  endtry

  try
    :%s/\(\s*\)\(\}\s\+else\)\n\([^{]\+\)/\1\2\ \{\r\3\r\1\}\r/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("else bracket is OK")
  endtry

endfun

nnoremap <F4> :call KssLint()<CR>
