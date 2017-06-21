" Public functions =============================================================

" for mappings -----------------------------------------------------------------
function! getting_things_down#show_todo()
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

function! getting_things_down#cycle_status()
  let l:curpos = getcurpos()

  let l:status = matchstr(getline('.'), '\v(^#{1,6}\s*|^\s*([\*\+\-]|\d\+\.)\s+)@<=(' . join(g:gtdown_cycle_states, '|') .')\s@=')

  " GUARD CLAUSE: fail silently if not on TODO task
  if empty(l:status)
    if exists('b:gtdown_cycle_timeout') | unlet b:gtdown_cycle_timeout | endif
    return 0
  " Repeat invocation AND timeout alive
  elseif exists('b:gtdown_cycle_timeout') &&
              \ get(b:gtdown_cycle_timeout, 'line') == get(l:curpos, 1) &&
              \ (localtime() - get(b:gtdown_cycle_timeout, 'time')) < 5
    execute line('.') . 'substitute/' . l:status . '/' .
                \ s:gtdown_next_status(l:status)
  " First invocation OR timeout expired
  else
    let b:gtdown_cycle_timeout = { 'line': line('.'), 'time': localtime() }
    execute line('.') . 'substitute/' . l:status . '/' .
                \ (l:status !=# 'DONE' ? 'DONE' :
                \ s:gtdown_next_status(l:status))
  endif

  call setpos('.', l:curpos)
endfunction

function! getting_things_down#toggle_task()
  let l:curpos = getcurpos()
  let l:status = matchstr(getline('.'), '\v(^#{1,6}\s*|^\s*([\*\+\-]|\d\+\.)\s+)@<=(' . join(g:gtdown_cycle_states, '|') .')\s@=')
  let l:is_task = !empty(l:status)

  if l:is_task
    execute line('.') . 'substitute/' . l:status . '\s\+//'
  else
    execute 'substitute/\v(^#{1,6}\s*|^\s*([\*\+\-]|\d\+\.)\s+)@<=/TODO /'
  endif

  call setpos('.', l:curpos)
endfunction

" for folding ------------------------------------------------------------------
function! getting_things_down#fold_expr(lnum)
  if !nextnonblank(a:lnum)
    return s:doc_root_hlevel()
  elseif s:heading_level(a:lnum)                           " start of heading
    return '>' . s:heading_level(a:lnum)
  elseif s:end_of_hsubtree(a:lnum)                         " end of heading
    return s:heading_level(a:lnum + 1)
  elseif g:gtdown_fold_list_items &&
        \ s:list_type(a:lnum) || s:belongs_to_li(a:lnum)   " part of list
    return s:list_level(a:lnum)
  else
    return s:prev_heading_level(a:lnum)
  endif
endfunction

function! getting_things_down#fold_text()
  if s:heading_level(v:foldstart)
    let s:heading = '# ' . substitute(getline(v:foldstart), '^#\+ ', '', '')
    let s:indent  = substitute(repeat('--', v:foldlevel - 1), '-$', ' ', '')
    let s:head_limit = 76 - s:indent
  else
    let s:heading = substitute(getline(v:foldstart), '^\s\+', '', '')
    let s:indent  = substitute(repeat('-', matchend(getline(v:foldstart), '^\s\+')), '-$', ' ', '')
    let s:head_limit = 78
  endif

  let s:fold_stats = s:compute_fold_stats(v:foldstart, v:foldend)
  let s:head_limit = s:head_limit - len(s:fold_stats) - 1

  if len(s:heading) > s:head_limit
    let s:heading = s:heading[:(s:head_limit - 2)] . '…'
  endif

  let s:filler  = substitute(repeat('-', 78 - strchars(s:indent . s:heading .
        \ s:fold_stats)), '\(^.\|.$\)', ' ', 'g')
  return s:indent . s:heading . s:filler . s:fold_stats . ' '
endfunction

" Helper functions =============================================================

" for mappings -----------------------------------------------------------------
" Given a value in g:gtdown_cycle_states, returns the following index
function! s:gtdown_next_status(status)
  return get(g:gtdown_cycle_states,
              \ ((index(g:gtdown_cycle_states, a:status) + 1) %
              \  len(g:gtdown_cycle_states)))
endfunction

" for folding ------------------------------------------------------------------
" Returns the <h1>–<h6> level for a given line, or 0 (false) if none.
function! s:heading_level(lnum)
  " GUARD CLAUSE: Return false if prev line is not a block boundary
  if !s:block_boundary(a:lnum - 1)
    return 0
  " atx headings (https://kramdown.gettalong.org/syntax.html#atx-style)
  elseif getline(a:lnum) =~# '^#\{1,6\}\s*\S'
    return strlen(matchstr(getline(a:lnum), '^#\+'))
  " Setext headings (https://kramdown.gettalong.org/syntax.html#setext-style)
  elseif getline(a:lnum + 1) =~# '\v^(\=+|-+)$' && getline(a:lnum) =~# '^\s\{0,3\}\S'
    return getline(a:lnum + 1) =~# '^=' ? 1 : 2
  endif
endfunction

" Returns 1 for <ul> list items and 2 for <ol> list items
function! s:list_type(lnum)
  if getline(a:lnum) =~# '^\s*[\*+\-]\s'
    return 1
  elseif getline(a:lnum) =~# '^\s*\d\+\.\s'
    return 2
  endif
endfunction

" Returns true if a given line is blank and terminates its heading subtree.
" (I.e., it is followed by an <h1>–<h6> header of higher rank than its own.)
function! s:end_of_hsubtree(lnum)
  if s:heading_level(a:lnum + 1) && s:prev_heading_level(a:lnum)
    return s:heading_level(a:lnum + 1) <= s:prev_heading_level(a:lnum)
  end
endfunction

" Returns the line number that starts the containing list item of a given line.
function! s:belongs_to_li(lnum, ...)
  " GUARD CLAUSE: Return -1 if block boundary reached
  if a:0 && s:block_boundary(a:lnum, (get(a:1, 'size') == 0 &&
              \                       get(a:1, 'type') ==# 'text'))
    return -1
  " Primitive case
  elseif a:0 && s:list_type(a:lnum) &&
              \ get(s:indent_size(a:lnum, 1), get(a:1, 'type')) <= get(a:1, 'size')
    return a:lnum
  " Subsequent calls
  elseif a:0
    return s:belongs_to_li(a:lnum - 1,
                \          s:new_paragraph(a:lnum) &&
                \            s:indent_size(a:lnum) <= get(a:1, 'size') ?
                \            { 'type': 'text',
                \              'size': min([get(a:1, 'size'),
                \                           s:indent_size(a:lnum)]) } :
                \            a:1)
  " First call
  else
    let l:ref_line = nextnonblank(a:lnum)
    return s:belongs_to_li(a:lnum - 1, 
                \          { 'type': ((l:ref_line == a:lnum ||
                \                      !s:list_type(l:ref_line)) ?
                \                        'text' : 'marker'),
                \            'size': ((s:list_type(l:ref_line) ||
                \                      s:new_paragraph(l:ref_line)) ?
                \                        s:indent_size(l:ref_line) : 99) })
  endif
endfunction

" Is a given line a block boundary?
" per https://kramdown.gettalong.org/syntax.html#block-boundaries
" Accepts an optional {cond} argument to help disambiguate, e.g.,
" new paragraphs within list items and new paragraphs at the end of a list.
function! s:block_boundary(lnum, ...)
  return a:lnum < 1 || (s:new_paragraph(a:lnum + 1) && (a:0 ? a:1 : 1)) ||
        \ getline(a:lnum) =~# '\(^\^$\|^\s*{:.\+}\)'
endfunction

" Is a given line non-blank and preceded by a blank one?
function! s:new_paragraph(lnum)
  return nextnonblank(a:lnum - 1) == a:lnum
endfunction

" Returns the level of the nearest preceding heading
function! s:prev_heading_level(lnum)
  if s:heading_level(a:lnum)
    return s:heading_level(a:lnum)
  elseif a:lnum < 1
    return 0
  else
    return s:prev_heading_level(a:lnum - 1)
  endif
endfunction

" Returns the highest-order (lowest number) heading level in the document
" (or 0 if no headings found).
function! s:doc_root_hlevel(...)
  if a:0 && a:1 <= line('$') && a:2 != 1
    return s:doc_root_hlevel(a:1 + 1,
                \ min(filter([a:2, s:heading_level(a:1)], 'v:val > 0')))
  elseif a:0
    return a:2
  else
    return s:doc_root_hlevel(1, 0)
  endif
endfunction

" Set an explicit fold level for lines containing list items
" CAUTION: guard clause removed for performance issues; do not pass invalid input
function! s:list_level(lnum)
  " GUARD CLAUSE: Return false if line does not contain a list item
  " if !(s:list_type(a:lnum) || s:belongs_to_li(a:lnum))
    " return 0
  " else
    let l:level = s:prev_heading_level(a:lnum) + s:count_li_ancestors(a:lnum)
    return s:belongs_to_li(a:lnum + 1) == a:lnum ? '>' . (l:level + 1) : l:level
  " endif
endfunction

" Counts the nesting level of a given list item.
" First lines of list items do not count themselves; subsequent lines do.
function! s:count_li_ancestors(lnum)
  return a:lnum > 0 ? s:count_li_ancestors(s:belongs_to_li(a:lnum)) + 1 : -1
endfunction

" Returns the indentation level of a line (i.e., length of leading whitespace).
" Accepts an optional {dict} boolean flag which, if {lnum} is the start of a
" list item, returns a dict of indentation levels (of 'marker' and 'text').
function! s:indent_size(lnum, ...)
  if exists('a:1') && a:1 && s:list_type(a:lnum)
    return { 'marker': matchend(getline(a:lnum), '^\s*\(\d\. \|[+\-\*] \)\@='),
           \ 'text':   matchend(getline(a:lnum), '^\s*\(\d\.\|[+\-\*]\)\s\+') }
  else
    return matchend(getline(a:lnum), '^\s*\S\@=')
  end
endfunction

" Returns a formatted count of non-blank lines to append to fold text (or, with
" optional flag {todo}, reports progress based on count of TODO keywords).
function! s:compute_fold_stats(start, end)
  let s:done_count = s:count_matches(
        \ '\v^(\s*([\*\+\-]|\d+\.)\s+|#{1,6}#@!\s*)(DONE)',
        \ range(a:start + 1, a:end))
  let s:total_count = s:count_matches( '\v^(\s*([\*\+\-]|\d+\.)\s+|#{1,6}#@!\s*)(TODO|HELP|DONE|WAIT|WIP)', range(a:start + 1, a:end))

  if s:show_todo_stats() && s:total_count
    let s:percent_done = float2nr(round(100.0 * s:done_count / s:total_count))
    let s:progress     = float2nr(round(str2nr(s:percent_done) / 5.0))
    let s:progress_bar = repeat('#', s:progress) . repeat('.', 20 - s:progress)
    return s:percent_done . '% [' . s:progress_bar . ']'
  else
    return '[' . s:nonblank_lines(range(v:foldstart + 1, v:foldend)) . ']'
  endif
endfunction

" Counts the number of lines in {range} that match {expr}.
function! s:count_matches(expr, range)
  return len(a:range) ?
    \ (getline(get(a:range, 0)) =~# a:expr) + s:count_matches(a:expr, a:range[1:-1]) : 0
endfunction

" Convenience method for checking buffer-local show_todo_stats setting
function! s:show_todo_stats()
  if exists('b:gtdown_show_progress') 
    return b:gtdown_show_progress
  elseif exists('g:gtdown_show_progress')
    return g:gtdown_show_progress
  endif
endfunction

" Returns a count of non-empty lines within a range
function! s:nonblank_lines(range)
  return len(filter(a:range, "getline(v:val) =~# '\\w'"))
endfunction
