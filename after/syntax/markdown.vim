" Syntax settings ==============================================================
" (for TODO keyword highlighting)

" Syntax groups ending in ‘N’ (as in `nextgroup`) appear after list items
" ------------------------------------------------------------------------------
syntax match markdownListMarker "\%(\t\| \{0,4\}\)[-*+]\%(\s\+\S\)\@=" contained nextgroup=markdownTodoDoneN,markdownTodoReadyN,markdownTodoWaitingN skipwhite
syntax match markdownOrderedListMarker "\%(\t\| \{0,4}\)\<\d\+\.\%(\s\+\S\)\@=" contained nextgroup=markdownTodoDoneN,markdownTodoReadyN,markdownTodoWaitingN skipwhite

syntax keyword markdownTodoDoneN DONE contained
syntax keyword markdownTodoReadyN TODO WIP contained
syntax keyword markdownTodoWaitingN HELP WAIT contained

highlight link markdownTodoDoneN DiffAdd
highlight link markdownTodoReadyN DiffChange
highlight link markdownTodoWaitingN DiffDelete

" Syntax groups ending in ‘C’ (as in `contained`) appear within headings
" ------------------------------------------------------------------------------
syntax region markdownH1 matchgroup=markdownHeadingDelimiter start="##\@!"      end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink,markdownTodoDoneC,markdownTodoReadyC,markdownTodoWaitingC contained
syntax region markdownH2 matchgroup=markdownHeadingDelimiter start="###\@!"     end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink,markdownTodoDoneC,markdownTodoReadyC,markdownTodoWaitingC contained
syntax region markdownH4 matchgroup=markdownHeadingDelimiter start="####\@!"    end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink,markdownTodoDoneC,markdownTodoReadyC,markdownTodoWaitingC contained
syntax region markdownH4 matchgroup=markdownHeadingDelimiter start="#####\@!"   end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink,markdownTodoDoneC,markdownTodoReadyC,markdownTodoWaitingC contained
syntax region markdownH5 matchgroup=markdownHeadingDelimiter start="######\@!"  end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink,markdownTodoDoneC,markdownTodoReadyC,markdownTodoWaitingC contained
syntax region markdownH6 matchgroup=markdownHeadingDelimiter start="#######\@!" end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink,markdownTodoDoneC,markdownTodoReadyC,markdownTodoWaitingC contained

syntax match markdownTodoDoneC /\C\(^#\{1,6\}\s*\)\@<=DONE\s\@=/ contained
syntax match markdownTodoReadyC /\C\(^#\{1,6\}\s*\)\@<=\(TODO\|WIP\)\s\@=/ contained
syntax match markdownTodoWaitingC /\C\(^#\{1,6\}\s*\)\@<=\(HELP\|WAIT\)\s\@=/ contained

highlight link markdownTodoDoneC DiffAdd
highlight link markdownTodoReadyC DiffChange
highlight link markdownTodoWaitingC DiffDelete
