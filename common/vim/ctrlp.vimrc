
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

" file finder mapping
let g:ctrlp_map = ',of'

" tags (symbols) in current file finder mapping
nmap ,g :CtrlPBufTag<CR>
" tags (symbols) in all files finder mapping
nmap ,G :CtrlPBufTagAll<CR>
" general code finder in all files mapping
nmap ,f :CtrlPLine<CR>
" recent files finder mapping
nmap ,m :CtrlPMRUFiles<CR>

" buffer list
nmap ,bl :CtrlPBuffer<CR>

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

" don't change working directory
let g:ctrlp_working_path_mode = 0
" ignore these files and folders on file finder
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.git|\.hg|\.svn|node_modules)$',
  \ 'file': '\.pyc$\|\.pyo$',
  \ }


" yes, follow symlinks
let g:ctrlp_follow_symlinks = 1
