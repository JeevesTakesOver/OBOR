Plug 'kchmck/vim-coffee-script'
" tab length exceptions on some file types
au BufNewFile,BufReadPost *.coffee setl shiftwidth=4 tabstop=4 softtabstop=4 expandtab

Plug 'alfredodeza/jacinto.vim'
" tab length exceptions on some file types
au BufNewFile,BufReadPost *.coffee setl foldmethod=indent nofoldenable
au BufNewFile,BufReadPost *.coffee setl tabstop=4 softtabstop=4 shiftwidth=4 expandtab

au FileType javascript setl shiftwidth=4 tabstop=4 softtabstop=4 expandtab
