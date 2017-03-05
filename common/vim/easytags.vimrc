Plug 'xolox/vim-easytags'
Plug 'xolox/vim-misc'
let g:easytags_async = 1
let g:easytags_syntax_keyword = 'always'
let g:easytags_dynamic_files = 1
set tags=./tags;
let g:easytags_events = ['BufWritePost']
let g:easytags_include_members = 1