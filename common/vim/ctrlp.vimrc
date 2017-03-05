
Plug 'kien/ctrlp.vim'
" Extension to ctrlp, for fuzzy command finder
Plug 'fisadev/vim-ctrlp-cmdpalette'

" don't change working directory
let g:ctrlp_working_path_mode = 0

"ctrlp-modified.vim
map <Leader>m :CtrlPModified<CR>
map <Leader>M :CtrlPBranch<CR>

"ctrlp-funky
let g:ctrlp_extensions = ['funky']
nnoremap <Leader>fu :CtrlPFunky<Cr>

"narrow the list down with a word under cursor
nnoremap <Leader>fU :execute 'CtrlPFunky ' . expand('<cword>')<Cr>

"ctrl-tjump
"nnoremap <c-]> :sp<Cr>:CtrlPtjump<cr>
"vnoremap <c-]> :sp<Cr>:CtrlPtjumpVisual<cr>

"Ctrl-P in buffer-list mode
map <Leader>bl :CtrlPBuffer<CR>
map <Leader>cpb :CtrlPBuffer<CR>
map <Leader>cpm :CtrlPMixed<CR>
" recent files finder mapping
nmap <Leader>cpmruf :CtrlPMRUFiles<CR>

map <Leader>cpt :CtrlPTag<CR>
nnoremap <leader>. :CtrlPTag<cr>
" tags (symbols) in current file finder mapping
map <Leader>cpbt :CtrlPBufTag<CR>
nnoremap <leader>bt :CtrlPBufTag<cr>
" tags (symbols) in all files finder mapping
map <Leader>cpbta :CtrlPBufTagAll<CR>
" general code finder in all files mapping
nmap <Leader>cpl :CtrlPLine<CR>
" commands finder mapping
nmap <Leader>cpcp :CtrlPCmdPalette<CR>

" ignore these files and folders on file finder
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.git|\.hg|\.svn|node_modules|venv)$',
  \ 'file': '\.pyc$\|\.pyo$',
  \ }

" to be able to call CtrlP with default search text
function! CtrlPWithSearchText(search_text, ctrlp_command_end)
    execute ':CtrlP' . a:ctrlp_command_end
    call feedkeys(a:search_text)
endfunction
" same as previous mappings, but calling with current word as default text

"nmap ,wg :call CtrlPWithSearchText(expand('<cword>'), 'BufTag')<CR>
"nmap ,wG :call CtrlPWithSearchText(expand('<cword>'), 'BufTagAll')<CR>
"nmap ,wf :call CtrlPWithSearchText(expand('<cword>'), 'Line')<CR>
"nmap ,we :call CtrlPWithSearchText(expand('<cword>'), '')<CR>
"nmap ,pe :call CtrlPWithSearchText(expand('<cfile>'), '')<CR>
"nmap ,wm :call CtrlPWithSearchText(expand('<cword>'), 'MRUFiles')<CR>
"nmap ,wc :call CtrlPWithSearchText(expand('<cword>'), 'CmdPalette')<CR>
