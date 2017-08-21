
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Enable the list of buffers
let g:airline#extensions#tabline#enabled = 0
let g:airline#extensions#tabline#tab_nr_type = 1
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#whitespace#enabled = 0

" " Show just the filename
 let g:airline#extensions#tabline#fnamemod = ':t'

" Set airline theme
"let g:airline_theme='sol'
"let g:airline_theme = 'bubblegum'
let g:airline_theme = 'badwolf'
"let g:airline_theme = 'papercolor'



let g:airline_left_sep = ''
let g:airline_right_sep = ''
let g:airline_branch_prefix = ''
" to use fancy symbols for airline, uncomment the following lines and use a
" patched font (more info on the README.rst)
if !exists('g:airline_symbols')
   let g:airline_symbols = {}
endif
"let g:airline_left_sep = '⮀'
"let g:airline_left_alt_sep = '⮁'
"let g:airline_right_sep = '⮂'
"let g:airline_right_alt_sep = '⮃'
"let g:airline_symbols.branch = '⭠'
"let g:airline_symbols.readonly = '⭤'
"let g:airline_symbols.linenr = '⭡'
