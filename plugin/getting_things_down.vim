" Settings =====================================================================
if !exists('g:gtdown_cycle_states')
  let g:gtdown_cycle_states = ['TODO', 'WIP ', 'DONE']
endif

if !exists('g:gtdown_default_fold_level')
  let g:gtdown_default_fold_level = 2
endif

if !exists('g:gtdown_fold_lists')
  let g:gtdown_fold_lists = 1
endif

if !exists('g:gtdown_show_progress')
  let g:gtdown_show_progress = 1
endif

" Mappings =====================================================================
" Quick-switch between current file and `TODO.md` of project root
nnoremap <LocalLeader><LocalLeader> :call gtdown#show_todo()<CR>

" Quick-switch between current file and `TODO.md` of project root
nnoremap <LocalLeader>m :call gtdown#cycle_status()<CR>

" Public functions =============================================================

" for mappings -----------------------------------------------------------------
function! gtdown#show_todo()
  if empty(finddir($HOME, expand('%')))
    return 0
  else
    if expand('%:t:r') ==# 'TODO'
      if exists('b:from_file')
        let l:from_file = b:from_file
        unlet b:from_file
        execute 'edit ' . l:from_file
      else
        echohl WarningMsg | echo 'No previous file.' | echohl None
      endif
    else
      let l:project_root = fnameescape(expand('%:p:h'))
      let l:todo_file = glob(l:project_root . '/**/TODO.*')
      while empty(l:todo_file)
        let l:project_root = fnamemodify(l:project_root, ':h')
        if fnamemodify(l:project_root, ':h') == $HOME
          echohl WarningMsg | echo 'TODO file not found.' | echohl None
          return 0
        endif
        let l:todo_file = get(glob(l:project_root . '/**/TODO.*', 0, 1), 0)
      endwhile
      execute 'edit ' . l:todo_file
      let b:from_file = fnameescape(expand('#'))
   endif
 endif
endfunction

function! gtdown#cycle_status()
  let l:status = matchstr(getline('.'), '\v(^#{1,6}\s*|^\s*([\*\+\-]|\d\+\.)\s+)@<=(' . join(g:gtdown_cycle_states, '|') .')')
  for i in range(0, len(g:gtdown_cycle_states) - 1)
    if l:status ==# get(g:gtdown_cycle_states, i)
      execute line('.') . 'substitute/' . get(g:gtdown_cycle_states, i) . '/' . get(g:gtdown_cycle_states, ((i + 1) % 3))
    endif
  endfor
endfunction
