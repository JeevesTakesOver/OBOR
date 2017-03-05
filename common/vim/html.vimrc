
" _. HTML {{{
Plug 'tpope/vim-haml'
Plug 'juvenn/mustache.vim'
Plug 'tpope/vim-markdown'
Plug 'digitaltoad/vim-jade'
Plug 'slim-template/vim-slim'

" tab length exceptions on some file types
au BufNewFile,BufReadPost *.jade setl shiftwidth=4 tabstop=4 softtabstop=4 expandtab
au BufNewFile,BufReadPost *.html setl shiftwidth=4 tabstop=4 softtabstop=4 expandtab
au BufNewFile,BufReadPost *.slim setl shiftwidth=4 tabstop=4 softtabstop=4 expandtab
au FileType htmldjango setl shiftwidth=4 tabstop=4 softtabstop=4
au FileType html setl shiftwidth=4 tabstop=4 softtabstop=4
