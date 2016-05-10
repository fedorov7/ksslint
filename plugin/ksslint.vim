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

function s:Substitution(bad, good) range
  try
    execute a:firstline . "," . a:lastline . 's/' . a:bad . '/' . a:good . '/gc'
  catch /\m^Vim\%((\a\+)\)\=:E486/
    call s:OkMessage("Substitution not found")
  endtry
endfunction

function! s:ReplaceReturnStatus()
  let statuses = ['Status', 'EFI_SUCCESS', 'EFI_LOAD_ERROR', 'EFI_INVALID_PARAMETER', 'EFI_UNSUPPORTED', 'EFI_BAD_BUFFER_SIZE', 'EFI_BUFFER_TOO_SMALL', 'EFI_NOT_READY', 'EFI_DEVICE_ERROR', 'EFI_WRITE_PROTECTED', 'EFI_OUT_OF_RESOURCES', 'EFI_VOLUME_CORRUPTED', 'EFI_VOLUME_FULL', 'EFI_NO_MEDIA', 'EFI_MEDIA_CHANGED', 'EFI_NOT_FOUND', 'EFI_ACCESS_DENIED', 'EFI_NO_RESPONSE', 'EFI_NO_MAPPING', 'EFI_TIMEOUT', 'EFI_NOT_STARTED', 'EFI_ALREADY_STARTED', 'EFI_ABORTED', 'EFI_ICMP_ERROR', 'EFI_TFTP_ERROR', 'EFI_PROTOCOL_ERROR', 'EFI_INCOMPATIBLE_VERSION', 'EFI_SECURITY_VIOLATION', 'EFI_CRC_ERROR', 'EFI_END_OF_MEDIA', 'EFI_END_OF_FILE', 'EFI_INVALID_LANGUAGE', 'EFI_COMPROMISED_DATA', 'EFI_WARN_UNKNOWN_GLYPH', 'EFI_WARN_DELETE_FAILURE', 'EFI_WARN_WRITE_FAILURE', 'EFI_WARN_BUFFER_TOO_SMALL', 'EFI_WARN_STALE_DATA']
  for status in statuses
    :%call s:Substitution('return\s*(*\('.status.'\))*;', 'RETURN_EFI_STATUS\ (\1);')
  endfor
endfunction

function! s:ReplaceReturnBoolean()
  let booleans = ['TRUE', 'FALSE']
  for bool in booleans
    :%call s:Substitution('return\s*(*\('.bool.'\))*;', 'RETURN_BOOLEAN\ (\1);')
  endfor
endfunction

function! s:ReplaceReturnPointer()
  :%call s:Substitution('return\s*(*\(NULL\))*;', 'RETURN_POINTER\ (\1);')
endfunction

function! s:ReplaceReturnNumber()
  :%call s:Substitution('return\s*(*\(\d\+\))*;', 'RETURN_NUMBER\ (\1);')
endfunction

function! s:ReplaceFreePool()
  :%call s:Substitution('FreePool\ (\(\p\+\));', 'FREE_MEM_POINTER\ (\1);')
endfunction

function! s:ReplaceEfiError()
  :%call s:Substitution('RETURN_IF\s*((\=EFI_ERROR\s*(Status))\=,\s*Status);', 'RETURN_IF_EFI_ERROR\ (Status);')
endfunction

function! s:ReplaceGotoEfiError()
  :%call s:Substitution('GOTO_IF\s*((\=EFI_ERROR\s*(Status))\=\(,\s*\w\+\),\s*Status\(\p*\));', 'GOTO_IF_EFI_ERROR\ (Status\1\2);')
endfunction

function! s:ReplaceIfNull()
  :%call s:Substitution('\(\(\u\|_\)\+_IF\)\s*((\=\(\w\+\)\s*==\s*NULL)\=\(\p\+\));', '\1\_NULL (\3\4);')
  :%call s:Substitution('\(\(\u\|_\)\+_IF\)\s*((\=NULL\s*==\s*\(\w\+\))\=\(\p\+\));', '\1\_NULL (\3\4);')
endfunction

function! s:ReplaceDbgExit()
  let values = [['STATUS', 'EFI_STATUS'], ['DEC', 'NUMBER'], ['HEX', 'HEX'], ['STRING', 'EFI_STRING'], ['TF', 'BOOLEAN'], ['POINTER', 'POINTER']]
  for value in values
    :%call s:Substitution('DBG_EXIT_'.value[0].'.*\n.*return\s*(\=\(\p\+\))\=;', 'RETURN_'.value[1].'\ (\1);')
  endfor
endfunction

function! KssMacroReplace()
  call s:ReplaceReturnStatus()
  call s:ReplaceReturnBoolean()
  call s:ReplaceReturnPointer()
  call s:ReplaceReturnNumber()
  call s:ReplaceFreePool()
  call s:ReplaceEfiError()
  call s:ReplaceGotoEfiError()
  call s:ReplaceIfNull()
  call s:ReplaceDbgExit()
  echohl Special
  echo "Done"
  echohl None
endfunction

function! KssLint()
  " DEBUG macros
  :%call s:Substitution('DEBUG\s*((\_.\=\s*EFI_D_\(\w\+\),\s\=\("\p\+"\),\s\=\(\p\+\)))', 'DBG_\1\ (\2,\ \3)')

  " DEBUG short macros
  :%call s:Substitution('\(DEBUG\s*((\_.\=\s*EFI_D_\)\(\w\+\),\s\=\("\p\+"\)))', 'DBG_\2\ (\3)')

  " DBG short macros
  :%call s:Substitution('\(DBG_\w\+\)1', '\1')

  " Trailing characters
  :%call s:Substitution('\s\+$', '')

  " Tabular characters
  :%call s:Substitution('\t', '\ \ ')

  " Function-Bracer spaces
  :%call s:Substitution('\(\w\)(', '\1\ (')

  " Blank strings
  :%call s:Substitution('\n\n\n', '\r\r')

"  " Empty comments
"  :%call s:Substitution('\n\s*\/\/\s*$', '')
"
"  " Macros-Bracer spaces
"  :%call s:Substitution('\(\u\)\s\+(', '\1(')

  " for Bracer
  :%call s:Substitution('\(for\s*(\p\+)\)\s*\n\s*{\s*$', '\1\ {')

  " while Bracer
  :%call s:Substitution('\(while\s*(\p\+)\)\s*\n\s*{\s*$', '\1\ {')

  " if Bracer
  :%call s:Substitution('\(if\s*(\p\+)\)\s*\n\s*{\s*$', '\1\ {')

  " Left Bracer
  :%call s:Substitution('(\s\+\(\S\+\)', '(\1')

  " Rigth Bracer
  :%call s:Substitution('\(\S\+\)\s\+)', '\1)')

  " Left Bracket
  :%call s:Substitution('\[\s\+\(\S\+\)', '\[\1')

  " Rigth Bracket
  :%call s:Substitution('\(\S\+\)\s\+\]', '\1\]')

  " if bracket
  :%call s:Substitution('\(\s*\)\(if\s*(\p\+)\)\s*\n\([^{]\+;\)\n', '\1\2\ \{\r\3\r\1\}\r')

  " if .. else bracket
  :%call s:Substitution('\(}\)\s*\n\s*else', '\1\ else')

  " else bracket
  :%call s:Substitution('\(\s*\)\(\}\s\+else\)\(\n\|\s*\)\([^{]\+;\)', '\1\2\ \{\r\4\r\1\}\r')

  " #define macros
  :%call s:Substitution('\(#define\s\+\w\+\)\s\+\((\(\w\|,\|\s\)\+)\)\(\s\+\S\)', '\1\2\4')

  " RETURN_EFI_STATUS macros
  :%call s:Substitution('if\s*\((\p\+)\)\s*{\n\s*RETURN_EFI_STATUS\s*(\(\p\+\));\n\s*}', 'RETURN_IF\ (\1,\ \2);')

  " RETURN_NUMBER macros
  :%call s:Substitution('if\s*\((\p\+)\)\s*{\n\s*RETURN_NUMBER\s*(\(\p\+\));\n\s*}', 'RETURN_NUMBER_IF\ (\1,\ \2);')

  " RETURN_HEX macros
  :%call s:Substitution('if\s*\((\p\+)\)\s*{\n\s*RETURN_HEX\s*(\(\p\+\));\n\s*}', 'RETURN_HEX_IF\ (\1,\ \2);')

  " RETURN_EFI_STRING macros
  :%call s:Substitution('if\s*\((\p\+)\)\s*{\n\s*RETURN_EFI_STRING\s*(\(\p\+\));\n\s*}', 'RETURN_EFI_STRING_IF\ (\1,\ \2);')

  " RETURN_BOOLEAN macros
  :%call s:Substitution('if\s*\((\p\+)\)\s*{\n\s*RETURN_BOOLEAN\s*(\(\p\+\));\n\s*}', 'RETURN_BOOLEAN_IF\ (\1,\ \2);')

  " RETURN_POINTER macros
  :%call s:Substitution('if\s*\((\p\+)\)\s*{\n\s*RETURN_POINTER\s*(\(\p\+\));\n\s*}', 'RETURN_POINTER_IF\ (\1,\ \2);')

"  "Null value comparison
"  :%call s:Substitution('\(\(\w\|->\|\.\)\+\|[^(]\*([^(]\+)\)\s*==\s*0', '!\1')
"
"  "Not null value comparison
"  :%call s:Substitution('\(\(\w\|->\|\.\)\+\|[^(]\*([^(]\+)\)\s*!=\s*0', '\1')

  " Break if EFI_ERROR macros
  :%call s:Substitution('if\s*\((EFI_ERROR\s*\((\p\+)\))\)\s*{\n\s*break;\n\s*}', 'BREAK_IF_EFI_ERROR\ \2;')

  " Continue if EFI_ERROR macros
  :%call s:Substitution('if\s*\((EFI_ERROR\s*\((\p\+)\))\)\s*{\n\s*continue;\n\s*}', 'CONTINUE_IF_EFI_ERROR\ \2;')

  " Break if macros
  :%call s:Substitution('if\s*\((\p\+)\)\s*{\n\s*break;\n\s*}', 'BREAK_IF\ \1;')

  " Continue if macros
  :%call s:Substitution('if\s*\((\p\+)\)\s*{\n\s*continue;\n\s*}', 'CONTINUE_IF\ \1;')

  echohl Special
  echo "Done"
  echohl None

endfun

au FileType c,cpp nnoremap <F4> :call KssLint()<CR>
au FileType c,cpp nnoremap <F5> :call KssMacroReplace()<CR>
