" A Vim colorscheme focused on handyness, usability, readability, etc,
" configured for elive
"
" HEX codes conversion in: http://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html
" thanks to a nice plugin in vim you can directly see the hex commented colors
" (thats why the comments)

" Supporting code -------------------------------------------------------------
" Preamble {{{

if !has("gui_running") && &t_Co != 256
    finish
endif

set background=dark

if exists("syntax_on")
    syntax reset
endif

let colors_name = "elive"

if !exists("g:badwolf_html_link_underline") " {{{
    let g:badwolf_html_link_underline = 1
endif " }}}

if !exists("g:badwolf_css_props_highlight") " {{{
    let g:badwolf_css_props_highlight = 0
endif " }}}

" }}}
" Palette {{{

let s:bwc = {}

" The most basic of all our colors is a slightly tweaked version of the Molokai
" Normal text.
let s:bwc.plain = ['f8f6f2', 15]  " #f8f6f2

" Pure and simple.
let s:bwc.snow = ['ffffff', 15]  " #ffffff
let s:bwc.coal = ['000000', 16]  " #000000

" All of the Gravel colors are based on a brown from Clouds Midnight.
let s:bwc.brightgravel   = ['d9cec3', 252]  " #d9cec3
let s:bwc.lightgravel    = ['998f84', 245]  " #998f84
let s:bwc.gravel         = ['857f78', 243]  " #857f78
let s:bwc.mediumgravel   = ['666462', 241]  " #666462
let s:bwc.deepgravel     = ['45413b', 238]  " #45413b
let s:bwc.deepergravel   = ['35322d', 236]  " #35322d
let s:bwc.darkgravel     = ['242321', 235]  " #242321
let s:bwc.darkergravel   = ['1c1c1c', 234]  " #1c1c1c
let s:bwc.blackgravel    = ['1c1b1a', 233]  " #1c1b1a
let s:bwc.blackestgravel = ['141413', 232]  " #141413

" A color sampled from a highlight in a photo of a glass of Dale's Pale Ale on
" my desk.
let s:bwc.dalespale = ['fade3e', 221]  " #fade3e

" A beautiful tan from Tomorrow Night.
let s:bwc.dirtyblonde = ['f4cf86', 222]  " #f4cf86

" Delicious, chewy red from Made of Code for the poppiest highlights.
let s:bwc.taffy = ['d75f00', 208]  " #d75f00
let s:bwc.red = ['d70000', 160]  " #d70000
let s:bwc.removed = ['af0000', 124]  " #af0000
let s:bwc.added = ['00ff00', 46]  " #00ff00

" Another chewy accent, but use sparingly!
let s:bwc.saltwatertaffy = ['8cffba', 121]  " #8cffba

" The star of the show comes straight from Made of Code.
let s:bwc.tardis = ['949494', 246]  " #949494

" This one's from Mustang, not Florida!
let s:bwc.orange = ['ffa724', 214]  " #ffa724

" A limier green from Getafe.
let s:bwc.lime = ['af5fff', 177]  " #af5fff
let s:bwc.green = ['5fd700', 76]  " #5fd700
let s:bwc.green2 = ['87af00', 106]  " #87af00


" Rose's dress in The Idiot's Lantern.
let s:bwc.dress = ['ff9eb8', 211]  " #ff9eb8

" Another play on the brown from Clouds Midnight.  I love that color.
let s:bwc.toffee = ['b88853', 137]  " #b88853

" Also based on that Clouds Midnight brown.
let s:bwc.coffee    = ['c7915b', 173]  " #c7915b
let s:bwc.darkroast = ['88633f', 95]  " #88633f


" Variables
let s:bwc.variable1  = ['5fafff', 39]  " #5fafff
let s:bwc.variable2  = ['87d7ff', 117]  " #87d7ff
let s:bwc.variable3  = ['00d7ff', 45]  " #00d7ff

" Misc
let s:bwc.yellow  = ['ffff00', 226]  " #ffff00
let s:bwc.yellow2  = ['ffaf00', 214]  " #ffaf00
let s:bwc.yellow3  = ['ffff87', 228]  " #ffff87
let s:bwc.strings  = ['8bc244', 148]  " #8bc244
"let s:bwc.strings2  = ['8787ff', 117]  " #8787ff
let s:bwc.strings2  = ['8787ff', 105]  " #8787ff
let s:bwc.delimiter  = ['ffafaf', 217]  " #ffafaf
let s:bwc.flow1  = ['ff8700', 208]  " #ff8700
let s:bwc.magenta  = ['8700d7', 165]  " #8700d7


" }}}
" Highlighting Function {{{
function! s:HL(group, fg, ...)
    " Arguments: group, guifg, guibg, gui, guisp

    let histring = 'hi ' . a:group . ' '

    if strlen(a:fg)
        if a:fg == 'fg'
            let histring .= 'guifg=fg ctermfg=fg '
        else
            let c = get(s:bwc, a:fg)
            let histring .= 'guifg=#' . c[0] . ' ctermfg=' . c[1] . ' '
        endif
    endif

    if a:0 >= 1 && strlen(a:1)
        if a:1 == 'bg'
            let histring .= 'guibg=bg ctermbg=bg '
        else
            let c = get(s:bwc, a:1)
            let histring .= 'guibg=#' . c[0] . ' ctermbg=' . c[1] . ' '
        endif
    endif

    if a:0 >= 2 && strlen(a:2)
        let histring .= 'gui=' . a:2 . ' cterm=' . a:2 . ' '
    endif

    if a:0 >= 3 && strlen(a:3)
        let c = get(s:bwc, a:3)
        let histring .= 'guisp=#' . c[0] . ' '
    endif

    " echom histring

    execute histring
endfunction
" }}}
" Configuration Options {{{

if exists('g:badwolf_darkgutter') && g:badwolf_darkgutter
    let s:gutter = 'blackestgravel'
else
    let s:gutter = 'blackgravel'
endif

if exists('g:badwolf_tabline')
    if g:badwolf_tabline == 0
        let s:tabline = 'blackestgravel'
    elseif  g:badwolf_tabline == 1
        let s:tabline = 'blackgravel'
    elseif  g:badwolf_tabline == 2
        let s:tabline = 'darkgravel'
    elseif  g:badwolf_tabline == 3
        let s:tabline = 'deepgravel'
    else
        let s:tabline = 'blackestgravel'
    endif
else
    let s:tabline = 'blackgravel'
endif

" }}}

" Actual colorscheme ----------------------------------------------------------
" Vanilla Vim {{{

" General/UI {{{

" user defined background
" TODO : all the grayscale values can be affected by this parameter, make a
" 'shift' system of grayscale tones depending of our selected bg
if exists('g:badwolf_background')
    if g:badwolf_background == 0
        call s:HL('Normal', 'plain', '')
        let bg_c = ''
    elseif  g:badwolf_background == 1
        call s:HL('Normal', 'plain', 'coal')
        let bg_c = 'coal'
    elseif  g:badwolf_background == 2
        call s:HL('Normal', 'plain', 'blackestgravel')
        let bg_c = 'blackestgravel'
    elseif  g:badwolf_background == 3
        call s:HL('Normal', 'plain', 'blackgravel')
        let bg_c = 'blackgravel'
    elseif  g:badwolf_background == 4
        call s:HL('Normal', 'plain', 'darkergravel')
        let bg_c = 'darkergravel'
    elseif  g:badwolf_background == 5
        call s:HL('Normal', 'plain', 'darkgravel')
        let bg_c = 'darkgravel'
    else
        call s:HL('Normal', 'plain', 'deepergravel')
        let bg_c = 'deepergravel'
    endif
else
    call s:HL('Normal', 'plain', 'blackestgravel')
    let bg_c = 'blackestgravel'
endif

"call s:HL('Normal', 'plain', 'coal')

call s:HL('Folded', 'magenta', bg_c, 'none')

call s:HL('VertSplit', 'lightgravel', '', 'none')

call s:HL('CursorLine',   '', '', 'bold')
call s:HL('CursorColumn', '', 'darkgravel')
call s:HL('ColorColumn',  '', 'darkgravel')

call s:HL('TabLine', 'plain', bg_c, 'none')
call s:HL('TabLineFill', 'plain', bg_c, 'none')
call s:HL('TabLineSel', bg_c, 'tardis', 'none')

call s:HL('MatchParen', 'dalespale', 'darkgravel', 'bold')

call s:HL('NonText',    'deepgravel', '')
call s:HL('SpecialKey', 'deepgravel', '')

call s:HL('Visual',    '',  'deepgravel')
call s:HL('VisualNOS', '',  'deepgravel')

call s:HL('Search',    'coal', 'yellow2', 'bold')
call s:HL('IncSearch', 'coal', 'yellow3',    'bold')

call s:HL('Underlined', 'fg', '', 'underline')

call s:HL('StatusLine',   'coal', 'tardis',     'bold')
call s:HL('StatusLineNC', 'snow', 'deepergravel', 'bold')

call s:HL('Directory', 'dirtyblonde', '', 'bold')

call s:HL('Title', 'lime')

call s:HL('ErrorMsg',   'snow',       '', 'bold')
call s:HL('MoreMsg',    'dalespale',   '',   'bold')
call s:HL('ModeMsg',    'dirtyblonde', '',   'bold')
call s:HL('Question',   'dirtyblonde', '',   'bold')
call s:HL('WarningMsg', 'dress',       '',   'bold')

" This is a ctags tag, not an HTML one.  'Something you can use c-] on'.
call s:HL('Tag', '', '', 'bold')

" hi IndentGuides                  guibg=#373737
" hi WildMenu        guifg=#66D9EF guibg=#000000

" }}}
" Gutter {{{

call s:HL('LineNr',     'deepgravel', bg_c)
call s:HL('SignColumn', 'magenta', bg_c)
call s:HL('FoldColumn', 'mediumgravel', bg_c)

" }}}
" Cursor {{{

call s:HL('Cursor',  'coal', 'tardis', 'bold')
call s:HL('vCursor', 'coal', 'tardis', 'bold')
call s:HL('iCursor', 'coal', 'tardis', 'none')

" }}}
" Syntax highlighting {{{

" Start with a simple base.
call s:HL('Special', 'delimiter')

" Comments are slightly brighter than folds, to make 'headers' easier to see.
call s:HL('Comment',        'lightgravel')
call s:HL('Todo',           'coal', 'magenta', 'bold')
call s:HL('SpecialComment', 'snow', '', 'bold')

" Strings are a nice, pale straw color.  Nothing too fancy.
call s:HL('String', 'strings')

" Control flow stuff is taffy.
call s:HL('Statement',   'taffy', '', 'bold')
call s:HL('Keyword',     'taffy', '', 'bold')
call s:HL('Conditional', 'flow1', '', 'bold')
call s:HL('Operator',    'lime', '', 'none')
call s:HL('Label',       'taffy', '', 'none')
call s:HL('Repeat',      'taffy', '', 'none')

" Functions and variable declarations are orange, because plain looks weird.
call s:HL('Identifier', 'variable1', '', 'none')
call s:HL('Function',   'yellow', '', 'none')

" Preprocessor stuff is lime, to make it pop.
"
" This includes imports in any given language, because they should usually be
" grouped together at the beginning of a file.  If they're in the middle of some
" other code they should stand out, because something tricky is
" probably going on.
call s:HL('PreProc',   'variable2', '', 'none')
call s:HL('Macro',     'variable2', '', 'none')
call s:HL('Define',    'variable2', '', 'none')
call s:HL('PreCondit', 'variable2', '', 'bold')

" Constants of all kinds are colored together.
" I'm not really happy with the color yet...
call s:HL('Constant',  'toffee', '', 'bold')
call s:HL('Character', 'toffee', '', 'bold')
call s:HL('Boolean',   'toffee', '', 'bold')

call s:HL('Number', 'strings2', '', 'bold')
call s:HL('Float',  'strings2', '', 'bold')

" Not sure what 'special character in a constant' means, but let's make it pop.
call s:HL('SpecialChar', 'dress', '', 'bold')

call s:HL('Type', 'dress', '', 'none')
call s:HL('StorageClass', 'taffy', '', 'none')
call s:HL('Structure', 'taffy', '', 'none')
call s:HL('Typedef', 'taffy', '', 'bold')

" Make try/catch blocks stand out.
call s:HL('Exception', 'lime', '', 'bold')

" Misc
call s:HL('Error',  'red',   'blackgravel', 'bold')
call s:HL('localWhitespaceError',  '',   'deepergravel', 'bold')
call s:HL('ExtraWhitespace',  '',   'lightgravel', 'bold')
call s:HL('Debug',  'snow',   '',      'bold')
call s:HL('Ignore', 'gravel', '',      '')

" }}}
" Completion Menu {{{

call s:HL('Pmenu', 'plain', 'deepergravel')
call s:HL('PmenuSel', bg_c, 'tardis', 'bold')
call s:HL('PmenuSbar', '', 'deepergravel')
call s:HL('PmenuThumb', 'brightgravel')

" }}}
" Spelling {{{

if has("spell")
    call s:HL('SpellCap', 'dalespale', '', 'undercurl,bold', 'dalespale')
    call s:HL('SpellBad', '', '', 'undercurl', 'dalespale')
    call s:HL('SpellLocal', '', '', 'undercurl', 'dalespale')
    call s:HL('SpellRare', '', '', 'undercurl', 'dalespale')
endif

" }}}

" }}}
" Plugins {{{

" CtrlP {{{

    " the message when no match is found
    call s:HL('CtrlPNoEntries', 'snow', 'taffy', 'bold')

    " the matched pattern
    call s:HL('CtrlPMatch', 'orange', '', 'none')

    " the line prefix '>' in the match window
    call s:HL('CtrlPLinePre', 'deepgravel', '', 'none')

    " the prompt’s base
    call s:HL('CtrlPPrtBase', 'deepgravel', '', 'none')

    " the prompt’s text
    call s:HL('CtrlPPrtText', 'plain', '', 'none')

    " the prompt’s cursor when moving over the text
    call s:HL('CtrlPPrtCursor', 'coal', 'tardis', 'bold')

    " 'prt' or 'win', also for 'regex'
    call s:HL('CtrlPMode1', 'coal', 'tardis', 'bold')

    " 'file' or 'path', also for the local working dir
    call s:HL('CtrlPMode2', 'coal', 'tardis', 'bold')

    " the scanning status
    call s:HL('CtrlPStats', 'coal', 'tardis', 'bold')

    " TODO: CtrlP extensions.
    " CtrlPTabExtra  : the part of each line that’s not matched against (Comment)
    " CtrlPqfLineCol : the line and column numbers in quickfix mode (|s:HL-Search|)
    " CtrlPUndoT     : the elapsed time in undo mode (|s:HL-Directory|)
    " CtrlPUndoBr    : the square brackets [] in undo mode (Comment)
    " CtrlPUndoNr    : the undo number inside [] in undo mode (String)

" }}}
" EasyMotion {{{

call s:HL('EasyMotionTarget', 'red',     '', 'bold')
call s:HL('EasyMotionShade',  'deepgravel', '')

" }}}
" Interesting Words {{{

" These are only used if you're me or have copied the <leader>hNUM mappings
" from my Vimrc.
call s:HL('InterestingWord1', 'coal', 'orange')
call s:HL('InterestingWord2', 'coal', 'lime')
call s:HL('InterestingWord3', 'coal', 'saltwatertaffy')
call s:HL('InterestingWord4', 'coal', 'toffee')
call s:HL('InterestingWord5', 'coal', 'dress')
call s:HL('InterestingWord6', 'coal', 'taffy')


" }}}
" Makegreen {{{

" hi GreenBar term=reverse ctermfg=white ctermbg=green guifg=coal guibg=#9edf1c
" hi RedBar   term=reverse ctermfg=white ctermbg=red guifg=white guibg=#C50048

" }}}
" ShowMarks {{{

call s:HL('ShowMarksHLl', 'magenta', bg_c)
call s:HL('ShowMarksHLu', 'magenta', bg_c)
call s:HL('ShowMarksHLo', 'variable2', bg_c)
call s:HL('ShowMarksHLm', 'yellow', 'magenta')

" }}}

" }}}
" Filetype-specific {{{

" Clojure {{{

call s:HL('clojureSpecial',  'taffy', '', '')
call s:HL('clojureDefn',     'taffy', '', '')
call s:HL('clojureDefMacro', 'taffy', '', '')
call s:HL('clojureDefine',   'taffy', '', '')
call s:HL('clojureMacro',    'taffy', '', '')
call s:HL('clojureCond',     'taffy', '', '')

call s:HL('clojureKeyword', 'orange', '', 'none')

call s:HL('clojureFunc',   'dress', '', 'none')
call s:HL('clojureRepeat', 'dress', '', 'none')

call s:HL('clojureParen0', 'lightgravel', '', 'none')

call s:HL('clojureAnonArg', 'snow', '', 'bold')

" }}}
" CSS {{{

if g:badwolf_css_props_highlight
    call s:HL('cssColorProp', 'dirtyblonde', '', 'none')
    call s:HL('cssBoxProp', 'dirtyblonde', '', 'none')
    call s:HL('cssTextProp', 'dirtyblonde', '', 'none')
    call s:HL('cssRenderProp', 'dirtyblonde', '', 'none')
    call s:HL('cssGeneratedContentProp', 'dirtyblonde', '', 'none')
else
    call s:HL('cssColorProp', 'fg', '', 'none')
    call s:HL('cssBoxProp', 'fg', '', 'none')
    call s:HL('cssTextProp', 'fg', '', 'none')
    call s:HL('cssRenderProp', 'fg', '', 'none')
    call s:HL('cssGeneratedContentProp', 'fg', '', 'none')
end

call s:HL('cssValueLength', 'toffee', '', 'bold')
call s:HL('cssColor', 'toffee', '', 'bold')
call s:HL('cssBraces', 'lightgravel', '', 'none')
call s:HL('cssIdentifier', 'orange', '', 'bold')
call s:HL('cssClassName', 'orange', '', 'none')

" }}}
" Diff {{{

call s:HL('gitDiff', 'lightgravel', '',)

call s:HL('diffRemoved', 'magenta', '',)
call s:HL('diffAdded', 'variable1', '',)
call s:HL('diffFile', 'green2', '', 'bold')
call s:HL('diffNewFile', 'green', '', 'bold')

call s:HL('diffLine', 'coal', 'yellow2', '')
call s:HL('diffSubname', 'orange', '', 'none')


" }}}
" Django Templates {{{

call s:HL('djangoArgument', 'dirtyblonde', '',)
call s:HL('djangoTagBlock', 'orange', '')
call s:HL('djangoVarBlock', 'orange', '')
" hi djangoStatement guifg=#ff3853 gui=bold
" hi djangoVarBlock guifg=#f4cf86

" }}}
" HTML {{{

" Punctuation
call s:HL('htmlTag',    'darkroast', '', 'none')
call s:HL('htmlEndTag', 'darkroast', '', 'none')

" Tag names
call s:HL('htmlTagName',        'coffee', '', 'bold')
call s:HL('htmlSpecialTagName', 'coffee', '', 'bold')
call s:HL('htmlSpecialChar',    'lime',   '', 'none')

" Attributes
call s:HL('htmlArg', 'coffee', '', 'none')

" Stuff inside an <a> tag

if g:badwolf_html_link_underline
    call s:HL('htmlLink', 'strings2', '', 'underline')
else
    call s:HL('htmlLink', 'strings2', '', 'none')
endif

" }}}
" Java {{{

call s:HL('javaClassDecl', 'taffy', '', 'bold')
call s:HL('javaScopeDecl', 'taffy', '', 'bold')
call s:HL('javaCommentTitle', 'gravel', '')
call s:HL('javaDocTags', 'snow', '', 'none')
call s:HL('javaDocParam', 'dalespale', '', '')

" }}}
" LaTeX {{{

call s:HL('texStatement', 'tardis', '', 'none')
call s:HL('texMathZoneX', 'orange', '', 'none')
call s:HL('texMathZoneA', 'orange', '', 'none')
call s:HL('texMathZoneB', 'orange', '', 'none')
call s:HL('texMathZoneC', 'orange', '', 'none')
call s:HL('texMathZoneD', 'orange', '', 'none')
call s:HL('texMathZoneE', 'orange', '', 'none')
call s:HL('texMathZoneV', 'orange', '', 'none')
call s:HL('texMathZoneX', 'orange', '', 'none')
call s:HL('texMath', 'orange', '', 'none')
call s:HL('texMathMatcher', 'orange', '', 'none')
call s:HL('texRefLabel', 'dirtyblonde', '', 'none')
call s:HL('texRefZone', 'lime', '', 'none')
call s:HL('texComment', 'darkroast', '', 'none')
call s:HL('texDelimiter', 'orange', '', 'none')
call s:HL('texZone', 'brightgravel', '', 'none')

augroup badwolf_tex
    au!

    au BufRead,BufNewFile *.tex syn region texMathZoneV start="\\(" end="\\)\|%stopzone\>" keepend contains=@texMathZoneGroup
    au BufRead,BufNewFile *.tex syn region texMathZoneX start="\$" skip="\\\\\|\\\$" end="\$\|%stopzone\>" keepend contains=@texMathZoneGroup
augroup END

" }}}
" LessCSS {{{

call s:HL('lessVariable', 'lime', '', 'none')

" }}}
" Lispyscript {{{

call s:HL('lispyscriptDefMacro', 'lime', '', '')
call s:HL('lispyscriptRepeat', 'dress', '', 'none')

" }}}
" Mail {{{

call s:HL('mailSubject', 'orange', '', 'bold')
call s:HL('mailHeader', 'lightgravel', '', '')
call s:HL('mailHeaderKey', 'lightgravel', '', '')
call s:HL('mailHeaderEmail', 'snow', '', '')
call s:HL('mailURL', 'toffee', '', 'underline')
call s:HL('mailSignature', 'gravel', '', 'none')

call s:HL('mailQuoted1', 'gravel', '', 'none')
call s:HL('mailQuoted2', 'dress', '', 'none')
call s:HL('mailQuoted3', 'dirtyblonde', '', 'none')
call s:HL('mailQuoted4', 'orange', '', 'none')
call s:HL('mailQuoted5', 'lime', '', 'none')

" }}}
" Markdown {{{

call s:HL('markdownHeadingRule', 'lightgravel', '', 'bold')
call s:HL('markdownHeadingDelimiter', 'lightgravel', '', 'bold')
call s:HL('markdownOrderedListMarker', 'lightgravel', '', 'bold')
call s:HL('markdownListMarker', 'lightgravel', '', 'bold')
call s:HL('markdownItalic', 'snow', '', 'bold')
call s:HL('markdownBold', 'snow', '', 'bold')
call s:HL('markdownH1', 'orange', '', 'bold')
call s:HL('markdownH2', 'lime', '', 'bold')
call s:HL('markdownH3', 'lime', '', 'none')
call s:HL('markdownH4', 'lime', '', 'none')
call s:HL('markdownH5', 'lime', '', 'none')
call s:HL('markdownH6', 'lime', '', 'none')
call s:HL('markdownLinkText', 'toffee', '', 'underline')
call s:HL('markdownIdDeclaration', 'toffee')
call s:HL('markdownAutomaticLink', 'toffee', '', 'bold')
call s:HL('markdownUrl', 'toffee', '', 'bold')
call s:HL('markdownUrldelimiter', 'lightgravel', '', 'bold')
call s:HL('markdownLinkDelimiter', 'lightgravel', '', 'bold')
call s:HL('markdownLinkTextDelimiter', 'lightgravel', '', 'bold')
call s:HL('markdownCodeDelimiter', 'dirtyblonde', '', 'bold')
call s:HL('markdownCode', 'dirtyblonde', '', 'none')
call s:HL('markdownCodeBlock', 'dirtyblonde', '', 'none')

" }}}
" MySQL {{{

call s:HL('mysqlSpecial', 'dress', '', 'bold')

" }}}
" Python {{{

hi def link pythonOperator Operator
call s:HL('pythonBuiltin',     'dress')
call s:HL('pythonBuiltinObj',  'dress')
call s:HL('pythonBuiltinFunc', 'dress')
call s:HL('pythonEscape',      'dress')
call s:HL('pythonException',   'lime', '', 'bold')
call s:HL('pythonExceptions',  'lime', '', 'none')
call s:HL('pythonPrecondit',   'lime', '', 'none')
call s:HL('pythonDecorator',   'taffy', '', 'none')
call s:HL('pythonRun',         'gravel', '', 'bold')
call s:HL('pythonCoding',      'gravel', '', 'bold')

" }}}
" SLIMV {{{

" Rainbow parentheses
call s:HL('hlLevel0', 'gravel')
call s:HL('hlLevel1', 'orange')
call s:HL('hlLevel2', 'saltwatertaffy')
call s:HL('hlLevel3', 'dress')
call s:HL('hlLevel4', 'coffee')
call s:HL('hlLevel5', 'dirtyblonde')
call s:HL('hlLevel6', 'orange')
call s:HL('hlLevel7', 'saltwatertaffy')
call s:HL('hlLevel8', 'dress')
call s:HL('hlLevel9', 'coffee')

" }}}
" Vim {{{

call s:HL('VimCommentTitle', 'lightgravel', '', 'bold')

call s:HL('VimMapMod',    'dress', '', 'none')
call s:HL('VimMapModKey', 'dress', '', 'none')
call s:HL('VimNotation', 'dress', '', 'none')
call s:HL('VimBracket', 'dress', '', 'none')

" }}}
" Plugin: Signify {{{
call s:HL('SignifySignAdd',   'green2', '', 'bold')
call s:HL('SignifySignDelete',   'toffee', '', 'bold')
call s:HL('SignifySignChange',   'strings2', '', 'bold')

" Plugin: https://github.com/justinmk/vim-syntax-extra
call s:HL('CUserFunction',   'strings2', '', 'bold')
" }}}
" Shell {{{
"call s:HL('shDeref', 'variable2', '', 'none')
"call s:HL('Delimiter', 'delimiter', '', 'none')
"call s:HL('shTestOpr', 'flow1', '', 'none')

" }}}
" }}}

