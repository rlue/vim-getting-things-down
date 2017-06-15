Getting Things Down
===================

Get Things Done in plain ol’ Markdown.

_Getting Things Down_ provides smart folding and TODO keyword highlighting for Markdown files, taking advantage of the heading outline structure inherent to Markdown (via HTML). Collapse/expand headings and list items, view overall progress, and jump to your project’s TODO file with a single mapping.

Installation
------------

There are lots of vim plugin managers out there. I like [vim-plug](https://github.com/junegunn/vim-plug).

Usage
-----

### Folding & Highlighting

Most of _Getting Things Down’s_ functionality comes automatically in the form of folding and syntax highlighting. If you can write documents in Markdown, you’re already 90% of the way there.

To take full advantage of its capabilities, simply make thoughtful use of headings when structuring your document, and pepper it with TODO annotations in list items and/or headings. 
Thus, the document below

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

or, one level further, like so:

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

When there are no tasks within a subtree, the fold text displays the number of non-blank lines inside the fold. 

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

You can cycle between select keywords with `<LocalLeader>c` as long as the cursor is on the same line as the task.

### Jumping to `TODO`

`<LocalLeader><LocalLeader>` switches between the current file and its project-wide TODO file. This works for any file in any project, as long as there is a `TODO.md` file located somewhere within the project root.

_Getting Things Down_ attempts to find the project-wide TODO file by walking up the current file’s path and recursively searching each directory along the way.

Configuration
-------------

To change the default behavior of _Getting Things Down_, modify the lines below and add them to your `.vimrc`. (For booleans, `0` is falsy; any other number is truthy.)

```viml
let g:gtdown_cycle_states = ['TODO', 'WIP ', 'DONE']   " Defines the TODO keywords that `<LocalLeader>m` will cycle through.
let g:gtdown_default_fold_level = 2                    " Sets the default fold level when opening a new Markdown file
let g:gtdown_fold_lists = 1                            " Should lists be folded too, or only headings?
let g:gtdown_show_progress = 1                         " Display progress bar for folded headings/list items?
```

License
-------

The MIT License (MIT)

Copyright © 2017 Ryan Lue
