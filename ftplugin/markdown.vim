" Folding ======================================================================
setlocal foldenable
exec 'setlocal foldlevel=' . g:gtdown_default_fold_level
setlocal foldmethod=expr
setlocal foldexpr=getting_things_down#fold_expr(v:lnum)
setlocal foldtext=getting_things_down#fold_text()
