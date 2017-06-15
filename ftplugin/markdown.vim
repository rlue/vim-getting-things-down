" Folding ======================================================================
setlocal foldenable
setlocal foldlevel=g:gtdown_default_fold_level
setlocal foldmethod=expr
setlocal foldexpr=gtdown#fold_expr(v:lnum)
setlocal foldtext=gtdown#fold_text()

" Public functions -------------------------------------------------------------
" Fold Expression
function! gtdown#fold_expr(lnum)
  let s:this_hlevel = s:heading_level(a:lnum)

  if s:this_hlevel                                         " start of heading
    return '>' . s:this_hlevel
  elseif s:end_of_hsubtree(a:lnum)                         " end of heading
    return s:heading_level(a:lnum + 1)
  elseif g:gtdown_fold_lists &&
        \ s:list_type(a:lnum) || s:belongs_to_li(a:lnum)    " part of list
    return s:list_level(a:lnum)
  else
    return s:parent_heading_level(a:lnum)
  endif
endfunction

" Fold Text
function! gtdown#fold_text()
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

" Helper functions -------------------------------------------------------------
" Returns the <h1>–<h6> level for a given line, or 0 (false) if none.
function! s:heading_level(lnum)
  " GUARD CLAUSE: Return false if prev line is not a block boundary
  if !s:block_boundary(a:lnum - 1)
    return 0
  " atx-style headings
  " https://kramdown.gettalong.org/syntax.html#atx-style
  elseif getline(a:lnum) =~# '^#\{1,6\}#\@!'
    return strlen(matchstr(getline(a:lnum), '^#\+'))
  " Setext-style headings
  " https://kramdown.gettalong.org/syntax.html#setext-style
  elseif a:lnum < line('$') && getline(a:lnum) =~# '^\s\{0,3\}\S'
                          \ && getline(a:lnum + 1) =~# '\v^(\=+|-+)$'
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
  " GUARD CLAUSE: Return false if no containing header
  if !s:parent_heading_level(a:lnum)
    return 0
  elseif getline(a:lnum) !~# '\S' && s:heading_level(a:lnum + 1)
    return s:heading_level(a:lnum + 1) <= s:parent_heading_level(a:lnum)
  end
endfunction

function! s:next_nonblank_line(lnum)
  " GUARD CLAUSE: Return this line if not blank
  if getline(a:lnum) =~# '\S'
    return a:lnum
  else
    return a:lnum > line('$') ? -1 : s:next_nonblank_line(a:lnum + 1)
  endif
endfunction

" Returns the line number that starts the containing list item of a given line.
function! s:belongs_to_li(lnum, ...)
  " GUARD CLAUSE: Return -1 if block boundary reached
  if s:block_boundary(a:lnum, (a:0 && get(a:1, 'size') == 0 && get(a:1, 'type') !=# 'marker'))
    return -1
  " Primitive case
  elseif a:0 && s:list_type(a:lnum) && get(s:indent_size(a:lnum, 1), get(a:1, 'type')) <= get(a:1, 'size')
    return a:lnum
  " Subsequent calls
  elseif a:0
    let l:indent = s:new_paragraph(a:lnum) &&
          \ s:indent_size(a:lnum) <= get(a:1, 'size') ?
          \ { 'type': 'text',
          \   'size': min([get(a:1, 'size'), s:indent_size(a:lnum)]) } :
          \ a:1
  " First call
  else
    let l:ref_line = s:next_nonblank_line(a:lnum)
    let l:indent =
        \ { 'type': ((getline(a:lnum) =~# '\S' || !s:list_type(l:ref_line)) ? 'text' : 'marker'),
          \ 'size': ((s:list_type(l:ref_line) || s:new_paragraph(l:ref_line)) ? s:indent_size(l:ref_line) : 99) }

    " GUARD CLAUSE: Return -1 if this line is a heading
    if s:heading_level(l:ref_line)
      return -1
    endif
  endif

  return s:belongs_to_li(a:lnum - 1, l:indent)
endfunction

" Is a given line a block boundary?
" per https://kramdown.gettalong.org/syntax.html#block-boundaries
" Accepts an optional {cond} argument to help disambiguate, e.g.,
" new paragraphs within list items and new paragraphs at the end of a list.
function! s:block_boundary(lnum, ...)
  if a:lnum < 1 || getline(a:lnum) =~# '\(^\^$\|^\s*{:.\+}\)' ||
        \ (s:new_paragraph(a:lnum + 1) && (a:0 ? a:1 : 1))
    return 1
  endif
endfunction

" Is a given line non-blank and preceded by a blank one?
function! s:new_paragraph(lnum)
  if getline(a:lnum - 1) !~# '\S' && getline(a:lnum) =~# '\S'
    return 1
  endif
endfunction

" Returns the level of the nearest preceding heading
function! s:parent_heading_level(lnum)
  if s:heading_level(a:lnum)
    return s:heading_level(a:lnum)
  elseif a:lnum < 1
    return 0
  else
    return s:parent_heading_level(a:lnum - 1)
  endif
endfunction

" Set an explicit fold level for lines containing list items
function! s:list_level(lnum)
  " GUARD CLAUSE: Return false if line does not contain a list item
  if !(s:list_type(a:lnum) || s:belongs_to_li(a:lnum))
    return 0
  else
    let l:level = s:parent_heading_level(a:lnum) + s:count_li_ancestors(a:lnum)
    return s:belongs_to_li(a:lnum + 1) == a:lnum ? '>' . (l:level + 1) : l:level
  endif
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
