let s:save_cpo = &cpo
set cpo&vim

let s:mapped_chars = []
let s:rules = lexima#sortedlist#new([], function('lexima#cmdmode#_priority_order'))

function! lexima#cmdmode#add_rules(rule)
  call s:rules.add(a:rule)
  call s:define_map(a:rule.char)
endfunction

function! lexima#cmdmode#clear_rules()
  for c in s:mapped_chars
    execute "cunmap " . c
  endfor
  let s:mapped_chars = []
  call s:rules.clear()
endfunction

function! s:define_map(c)
  if index(s:mapped_chars, a:c) ==# -1
    execute printf("cnoremap %s \<C-\>e<SID>map_impl('%s')\<CR>", a:c, substitute(lexima#string#to_mappable(a:c), "'", "''", 'g'))
    call add(s:mapped_chars, a:c)
  endif
endfunction

function! s:map_impl(char)
  let pos = getcmdpos()
  let cmdline = getcmdline()
  let [precursor, postcursor] = lexima#string#take_many(cmdline, pos-1)
  let rule = s:find_rule(a:char)
  if rule == {}
    return precursor . lexima#string#to_inputtable(a:char) . postcursor
  else
    if has_key(rule, 'leave')
    else
      let input = rule.input
      let input_after = rule.input_after
    endif
    call setcmdpos(pos + len(input))
    return precursor . lexima#string#to_inputtable(input) . lexima#string#to_inputtable(input_after) . postcursor
  endif
endfunction

function! s:find_rule(char)
  let pos = getcmdpos()
  let cmdline = getcmdline()
  let [precursor, postcursor] = lexima#string#take_many(cmdline, pos-1)
  let cmdtype = getcmdtype()
  for rule in s:rules.as_list()
    if rule.mode =~# 'c' || rule.mode =~# cmdtype
      if rule.char ==# a:char
        let [pre_at, post_at] = map(split(rule.at, '\\%#', 1) + ['', ''], 'v:val . "$"')[0:1]
        if precursor =~# pre_at && postcursor =~# post_at
          if empty(rule.filetype) || index(rule.filetype, &filetype) >=# 0
            return rule
          endif
        endif
      endif
    endif
  endfor
  return {}
endfunction

function! lexima#cmdmode#_priority_order(rule1, rule2)
  let ft1 = !empty(a:rule1.filetype)
  let ft2 = !empty(a:rule2.filetype)
  if ft1 && !ft2
    return 1
  elseif ft2 && !ft1
    return -1
  else
    let pri1 = a:rule1.priority
    let pri2 = a:rule2.priority
    if pri1 > pri2
      return 1
    elseif pri1 < pri2
      return -1
    else
      let atlen1 = len(a:rule1.at)
      let atlen2 = len(a:rule2.at)
      if atlen1 > atlen2
        return 1
      elseif atlen1 < atlen2
        return -1
      else
        return 0
      endif
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
