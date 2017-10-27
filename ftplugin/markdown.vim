" Folding ======================================================================
setlocal foldenable
exec 'setlocal foldlevel=' . g:gtdown_default_fold_level
setlocal foldmethod=expr
setlocal foldexpr=getting_things_down#fold_expr(v:lnum)
setlocal foldtext=getting_things_down#fold_text()

" Mappings =====================================================================
" Cycle through TODO keywords
nnoremap <buffer> <silent> <LocalLeader>c :call getting_things_down#cycle_status()<CR>

" Toggle TODO tasks
nnoremap <buffer> <silent> <LocalLeader>t :call getting_things_down#toggle_task()<CR>
vnoremap <buffer> <silent> <LocalLeader>t :call getting_things_down#toggle_task()<CR>
