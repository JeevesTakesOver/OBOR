
Plug 'scrooloose/syntastic'

let g:syntastic_python_checkers = ['pylint', 'flake8']

let g:syntastic_aggregate_errors = 1

let g:syntastic_enable_signs=1
" custom icons (enable them if you use a patched font, and enable the previous
" setting)
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '⚠'
let g:syntastic_style_error_symbol = '✗'
let g:syntastic_style_warning_symbol = '⚠'

let g:syntastic_auto_loc_list=1
" let g:syntastic_mode_map = { 'mode': 'active', 'active_filetypes': ['ruby', 'python'], 'passive_filetypes': ['html', 'css', 'slim'] }


"disable syntastic for rextex files
let g:syntastic_ignore_files = ['.*\.rst']

"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
" check also when just opened the file
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1

"  ingore module level import not at top of file
let g:syntastic_python_flake8_args='--ignore=E402,W292 --max-complexity 10'
