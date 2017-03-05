Plug 'Valloric/YouCompleteMe'

let g:ycm_python_binary_path = 'python'

" Disable TAB as it clashes with utilsnips
let g:ycm_key_list_select_completion=[]
let g:ycm_key_list_previous_completion=[]


if ! filereadable(expand("~/.vim/plugged/YouCompleteMe/.done"))
  !cd ~/.vim/plugged/YouCompleteMe && ./install.py --all && touch ~/.vim/plugged/YouCompleteMe/.done
endif

