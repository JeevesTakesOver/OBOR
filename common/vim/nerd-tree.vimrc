
" NERDTree ----------------------------- 

Plug 'scrooloose/nerdtree'

" open nerdtree with the current file selected
" nmap ,t :NERDTreeFind<CR>

" toggle nerdtree display
map ,nt :NERDTreeToggle<CR>:vertical resize 40<CR>

let g:NERDTreeDirArrows=1
let g:EasyMotion_leader_key = '<Leader>'
let g:NERDTreeWinPos = "left"
let g:nerdtree_tabs_open_on_console_startup=0
let g:NERDTreeWinSize = 40
let g:nerdtree_tabs_smart_startup_focus=1
let NERDTreeQuitOnOpen = 1

" don;t show these file types
let NERDTreeIgnore = ['\.pyc$', '\.pyo$']

" Disable the scrollbars (NERDTree)
set guioptions-=r
set guioptions-=L
" Keep NERDTree window fixed between multiple toggles
set winfixwidth
" }}}
