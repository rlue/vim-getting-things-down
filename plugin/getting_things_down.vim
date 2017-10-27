" Initialization Check =========================================================
if exists('g:loaded_getting_things_down')
  finish
endif
let g:loaded_getting_things_down = 1

" Settings =====================================================================
if !exists('g:gtdown_cycle_states')
  let g:gtdown_cycle_states = ['DONE', 'WIP ', 'WAIT', 'HELP', 'TODO']
endif

if !exists('g:gtdown_default_fold_level')
  let g:gtdown_default_fold_level = 2
endif

if !exists('g:gtdown_fold_list_items')
  let g:gtdown_fold_list_items = 1
endif

if !exists('g:gtdown_show_progress')
  let g:gtdown_show_progress = 1
endif

" Mappings =====================================================================

" Quick-switch between current file and `TODO.md` of project root
nnoremap <LocalLeader><LocalLeader> :call getting_things_down#show_todo()<CR>
