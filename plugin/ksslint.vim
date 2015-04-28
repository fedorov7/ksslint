" ksslint.vim - A KSS code lint and fix
" Maintainer:   Alexander Fedorov fedorov7@gmail.com
" Version:      0.1

if exists('g:loaded_ksslint') || &cp
  finish
endif
let g:loaded_ksslint = 1

function! s:OkMessage(message)
""  :echohl Special
""  :echo a:message
""  :echohl None
endfun

function s:Substitution(bad, good) range "Step through each line in the range...
  " echo "pattern: ".a:bad." replacement: ".a:good
  for linenum in range(a:firstline, a:lastline)
    let curr_line   = getline(linenum)
    let replacement = substitute(curr_line, a:bad, a:good,'gc')
    call setline(linenum, replacement)
  endfor
endfunction

function! s:ReplaceIfReturnStatus()
  let retval = 0
  try
    :%s/if\s*\((\p\+)\)\s*{\n\s*return\s*\(\p\+\);\n\s*}/RETURN_IF\ (\1,\ \2);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    let retval = 1
  endtry
  return retval
endfunction

function! s:ReplaceReturnStatus()
  let statuses = ['Status', 'EFI_SUCCESS', 'EFI_LOAD_ERROR', 'EFI_INVALID_PARAMETER', 'EFI_UNSUPPORTED', 'EFI_BAD_BUFFER_SIZE', 'EFI_BUFFER_TOO_SMALL', 'EFI_NOT_READY', 'EFI_DEVICE_ERROR', 'EFI_WRITE_PROTECTED', 'EFI_OUT_OF_RESOURCES', 'EFI_VOLUME_CORRUPTED', 'EFI_VOLUME_FULL', 'EFI_NO_MEDIA', 'EFI_MEDIA_CHANGED', 'EFI_NOT_FOUND', 'EFI_ACCESS_DENIED', 'EFI_NO_RESPONSE', 'EFI_NO_MAPPING', 'EFI_TIMEOUT', 'EFI_NOT_STARTED', 'EFI_ALREADY_STARTED', 'EFI_ABORTED', 'EFI_ICMP_ERROR', 'EFI_TFTP_ERROR', 'EFI_PROTOCOL_ERROR', 'EFI_INCOMPATIBLE_VERSION', 'EFI_SECURITY_VIOLATION', 'EFI_CRC_ERROR', 'EFI_END_OF_MEDIA', 'EFI_END_OF_FILE', 'EFI_INVALID_LANGUAGE', 'EFI_COMPROMISED_DATA', 'EFI_WARN_UNKNOWN_GLYPH', 'EFI_WARN_DELETE_FAILURE', 'EFI_WARN_WRITE_FAILURE', 'EFI_WARN_BUFFER_TOO_SMALL', 'EFI_WARN_STALE_DATA']
  for status in statuses
    :%call s:Substitution('return\s*(*\('.status.'\))*;', 'RETURN_EFI_STATUS\ (\1);')
  endfor
endfunction

function! s:ReplaceFreePool()
  :%call s:Substitution('FreePool\ (\(\p\+\));', 'FREE_MEM_POINTER\ (\1);')
endfunction

function! s:ReplaceEfiError()
  :%call s:Substitution('RETURN_IF\s*((\=EFI_ERROR\s*(Status))\=,\s*Status);', 'RETURN_IF_EFI_ERROR\ (Status);')
endfunction

function! KssMacroReplace()
  call s:ReplaceIfReturnStatus()
  call s:ReplaceReturnStatus()
  call s:ReplaceFreePool()
  call s:ReplaceEfiError()
  echohl Special
  echo "Done"
  echohl None
endfunction

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
    :%s/(\s\+\(\S\+\)/(\1/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Left Bracer is OK")
  endtry

  try
    :%s/\(\S\+\)\s\+)/\1)/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Rigth Bracer is OK")
  endtry

  try
    :%s/\[\s\+\(\S\+\)/\[\1/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Left Bracket is OK")
  endtry

  try
    :%s/\(\S\+\)\s\+\]/\1\]/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Rigth Bracket is OK")
  endtry

  try
    :%s/\(\s*\)\(if\s*(\p\+)\)\s*\n\([^{]\+;\)\n/\1\2\ \{\r\3\r\1\}\r/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("if bracket is OK")
  endtry

  try
    :%s/\(}\)\s*\n\s*else/\1\ else/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("if .. else bracket is OK")
  endtry

  try
    :%s/\(\s*\)\(\}\s\+else\)\n\([^{]\+;\)/\1\2\ \{\r\3\r\1\}\r/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("else bracket is OK")
  endtry

  try
    :%s/\(#define\s\+\w\+\)\s\+\((\(\w\|,\|\s\)\+)\)\(\s\+\S\)/\1\2\4/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("#define macros OK")
  endtry

  try
    :%s/DBG_EXIT_STATUS.*\n.*return\s*(\=\(\p\+\))\=;/RETURN_EFI_STATUS\ (\1);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("DBG_EXIT_STATUS macros not found")
  endtry

  try
    :%s/if\s*\((\p\+)\)\s*{\n\s*RETURN_EFI_STATUS\s*\(\p\+\);\n\s*}/RETURN_IF\ (\1,\ \2);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("RETURN_EFI_STATUS macros not found")
  endtry

  try
    :%s/DBG_EXIT_DEC.*\n.*return\s*(\=\(\p\+\))\=;/RETURN_NUMBER\ (\1);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("DBG_EXIT_DEC macros not found")
  endtry

  try
    :%s/if\s*\((\p\+)\)\s*{\n\s*RETURN_NUMBER\s*\(\p\+\);\n\s*}/RETURN_NUMBER_IF\ (\1,\ \2);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("RETURN_NUMBER macros not found")
  endtry

  try
    :%s/DBG_EXIT_HEX.*\n.*return\s*(\=\(\p\+\))\=;/RETURN_HEX\ (\1);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("DBG_EXIT_HEX macros not found")
  endtry

  try
    :%s/if\s*\((\p\+)\)\s*{\n\s*RETURN_HEX\s*\(\p\+\);\n\s*}/RETURN_HEX_IF\ (\1,\ \2);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("RETURN_HEX macros not found")
  endtry

  try
    :%s/DBG_EXIT_STRING.*\n.*return\s*(\=\(\p\+\))\=;/RETURN_EFI_STRING\ (\1);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("DBG_EXIT_STRING macros not found")
  endtry

  try
    :%s/if\s*\((\p\+)\)\s*{\n\s*RETURN_EFI_STRING\s*\(\p\+\);\n\s*}/RETURN_EFI_STRING_IF\ (\1,\ \2);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("RETURN_EFI_STRING macros not found")
  endtry

  try
    :%s/DBG_EXIT_TF.*\n.*return\s*(\=\(\p\+\))\=;/RETURN_BOOLEAN\ (\1);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("DBG_EXIT_TF macros not found")
  endtry

  try
    :%s/if\s*\((\p\+)\)\s*{\n\s*RETURN_BOOLEAN\s*\(\p\+\);\n\s*}/RETURN_BOOLEAN_IF\ (\1,\ \2);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("RETURN_BOOLEAN macros not found")
  endtry

  try
    :%s/DBG_EXIT_POINTER.*\n.*return\s*(\=\(\p\+\))\=;/RETURN_POINTER\ (\1);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("DBG_EXIT_POINTER macros not found")
  endtry

  try
    :%s/if\s*\((\p\+)\)\s*{\n\s*RETURN_POINTER\s*\(\p\+\);\n\s*}/RETURN_POINTER_IF\ (\1,\ \2);/gc
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("RETURN_POINTER macros not found")
  endtry

  echohl Special
  echo "Done"
  echohl None

endfun

nnoremap <F4> :call KssLint()<CR>
nnoremap <F5> :call KssMacroReplace()<CR>
