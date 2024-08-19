This project suffers from severe performance issues and has been abandoned.
===================

![](https://raw.githubusercontent.com/rlue/i/master/vim-getting-things-down/demo.gif)

Get Things Done in plain ol’ Markdown.

_Getting Things Down_ provides smart folding and TODO keyword highlighting for Markdown files, taking advantage of the heading outline structure inherent to Markdown (via HTML). Collapse/expand headings and list items, view overall progress, and jump to your project’s TODO file with a single mapping.

Installation
------------

There are lots of vim plugin managers out there. I like [vim-plug](https://github.com/junegunn/vim-plug).

Usage
-----

Most of _Getting Things Down’s_ functionality comes automatically in the form of folding and syntax highlighting. If you can write documents in Markdown, you’re already 90% of the way there.

### Folding

To take full advantage of its capabilities, simply make thoughtful use of headings when structuring your document, and pepper it with TODO annotations in list items and/or headings. 

For instance, a document like the one below

```markdown
-     Jake’s Bar Mitzvah
|     ================================================================================
|     
|-    ## Supplies
||    
||-   ### Food & Drink
|||   
|||     * DONE catering (Szechwan Palace)
|||     * TODO buy grape juice
|||   
||-   ### Equipment
|||   
|||-    * WAIT folding chairs & tables
||||
||||      may be provided by venue?
||||
|||     * DONE PA system
||    
|-    ## People
||    
||      * WIP  practice group dance routine
||-     * HELP hire a DJ
||| 
|||       NO rap music
||    
|-    ## Resources
||    
||      * http://chabad.org/library/article_cdo/aid/136670/jewish/Jewish-Prayers.htm
||      * http://szechwanpalace.com
|
-     Jewish Movie Night
|     ================================================================================
|     ...
```

can be collapsed like so:

```markdown
-     Jake’s Bar Mitzvah
|     ================================================================================
|     
|-    ## Supplies
||    
||+   --- # Food & Drink -------------------------------- 50% [##########..........] -
||+   --- # Equipment ----------------------------------- 50% [##########..........] -
||    
|-    ## People
||    
||      * WIP  practice group dance routine
||+   - * HELP hire a DJ ------------------------------------------------------- [1] -
||    
|-    ## Resources
||    
||      * http://chabad.org/library/article_cdo/aid/136670/jewish/Jewish-Prayers.htm
||      * http://szechwanpalace.com
|
-     Jewish Movie Night
|     ================================================================================
|     ...
```

Note how the collapsed “Food & Drink” and “Equipment” lines display a progress bar on the right. This is automatically generated according to what portion of the tasks within the fold are marked DONE. Note also that the “HELP Hire a DJ” foldtext does not display a progress bar. Since there are no tasks inside of that fold, it reports the number of non-blank lines, instead.

As you continue to collapse the folds, the progress bars are recalculated to reflect the overall progress of all tasks they contain:

```markdown
-     Jake’s Bar Mitzvah
|     ================================================================================
|     
|+    - # Supplies -------------------------------------- 50% [##########..........] -
|+    - # People ----------------------------------------- 0% [....................] -
|+    - # Resources ------------------------------------------------------------ [2] -
|
-     Jewish Movie Night
|     ================================================================================
|     ...
```

_Getting Things Down_ follows [kramdown syntax][kram] definitions for headings and list items.

If you’re not familiar with folding, check out the help docs:

```viml
:h Folding
```

### `TODO` keywords

_Getting Things Down_ recognizes five TODO keywords:

  * `TODO`
  * `WIP ` (work-in-progress)
  * `DONE`
  * `HELP` (for when I’m stuck and need to study/analyze/ask for help)
  * `WAIT` (requires someone else’s approval/contribution)

TODO keywords must be placed at the start of list items and hashmark-style (_i.e.,_ ATX) headings. You can toggle the presence of a TODO keyword with `<LocalLeader>t`, or cycle between select keywords with `<LocalLeader>c`. The cursor does not have to be on the TODO keyword itself, only on the same line.

### Jumping to `TODO`

`<LocalLeader><LocalLeader>` switches between the current file and its project-wide TODO file. This works for any file in any project, as long as there is a `TODO.md` file located somewhere within the project root.

_Getting Things Down_ attempts to find the project-wide TODO file by walking up the current file’s path and recursively searching each directory along the way.

Configuration
-------------

### Variables

To change the default behavior of _Getting Things Down_, modify the lines below and add them to your `.vimrc`. (For booleans, `0` is falsy; any other number is truthy.)

```viml
" Defines the TODO keywords that `<LocalLeader>m` will cycle through.
let g:gtdown_cycle_states = ['DONE', 'WIP ', 'WAIT', 'HELP', 'TODO']

" Default fold level for new Markdown buffers (see `:h 'foldlevel'`).
let g:gtdown_default_fold_level = 2

" Should multi-line list items collapse too, or only headings?
let g:gtdown_fold_list_items = 1

" Display progress bar for folded headings/list items?
let g:gtdown_show_progress = 1
```

A buffer-local `b:gtdown_show_progress` value will override the global setting. For instance, the following autocommand will enable progress previews _only_ for files named `TODO.md`:

```viml
let g:gtdown_show_progress = 0
augroup gtDown
  autocmd!
  autocmd BufReadPre TODO.md let b:gtdown_show_progress = 1
augroup END
```

### Mappings

The lines below set mappings for _Getting Things Down’s_ major shortcuts.

```viml
" Quick-switch between current file and `TODO.md` of project root
nnoremap <LocalLeader><LocalLeader> :call getting_things_down#show_todo()<CR>

" Cycle through TODO keywords
nnoremap <silent> <LocalLeader>c :call getting_things_down#cycle_status()<CR>

" Toggle TODO tasks
nnoremap <silent> <LocalLeader>t :call getting_things_down#toggle_task()<CR>
vnoremap <silent> <LocalLeader>t :call getting_things_down#toggle_task()<CR>
```

I use `<Leader><Leader>`, `<Leader>c`, and `<Leader>t`, but it’d probably clobber someone else’s settings if those were the default.

License
-------

The MIT License (MIT)

Copyright © 2017 Ryan Lue

[kram]: https://kramdown.gettalong.org/syntax.html
