" pairtools.vim - PairTools plugin
" Last Changed: 2011 May 12
" Maintainer:   Martin Lafreniere <pairtools@gmail.com>
"
" Copyright (C) 2011 by Martin Lafrenière
" 
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and permit persons to whom the Software is furnished
" to do so, subject to the following conditions:
" 
" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.
" 
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NOT EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.

if v:version < 700 || &cp
    echom "PairTools requires Vim 7.0+ to work properly."
    finish
endif

if exists('g:loaded_pairtools')
    finish
endif
let g:loaded_pairtools = '1.5'

" ## TEMP STUFF ##
let g:pairtools_pairclamp = 1
let g:pairtools_tagwrench = 1
let g:pairtools_jigsaw    = 1
" ## TEMP STUFF ##


" PairTools Configuration {{{1

function! s:SetOption(Option, Value) "{{{2

    let b:PT{a:Option} = a:Value

    " When global options exists, use it instead!
    let userOption = 'g:pairtools_' . &ft . '_' . tolower(a:Option)
    if exists(userOption)
        let b:PT{a:Option} = {userOption}
    endif
    
endfunction "}}}2

function! s:SetIMap(Key, FuncName, Command, ...) "{{{2

    " Handle variable arguments for FunName
    let argList = []
    for arg in a:000
        call add(argList, '"' . escape(arg, '"') . '"')
    endfor

    exe 'inoremap <silent> <buffer> ' . a:Key . 
                \' <C-R>=' . a:FuncName . '(' . join(argList, ',') . ')<CR>' . a:Command
    
endfunction "}}}2

function! s:Configure() "{{{2

    "### Configure PairClamp ### {{{3
    if exists('g:pairtools_pairclamp') && g:pairtools_pairclamp
        
        " Options are turn off by default now...
        call s:SetOption('AutoClose', 0)
        call s:SetOption('ClosePairs', "[:],(:),{:}")
        call s:SetOption('ForcePairs', 0)
        call s:SetOption('SmartClose', 0)
        call s:SetOption('SmartCloseRules', '\w')
        call s:SetOption('Antimagic', 0)
        call s:SetOption('AntimagicField', "String,Comment")
        
        let uniq = PairClamp#UniquifyCloseKeys()

        " Mappings
        if b:PTAutoClose
            for key in uniq
                call s:SetIMap(key, 'PairClamp#Close', '', PairClamp#SanitizeKey(key))
            endfor
        endif

        if b:PTForcePairs 
            for key in keys(b:PTWorkPairs)
                call s:SetIMap('<M-' . key . '>', 'PairClamp#Force', '', PairClamp#SanitizeKey(key)) 
            endfor
        endif

        let b:LoadedPairClamp = 1

    endif " }}}3

    "### Configure TagWrench ### {{{3
    if exists('g:pairtools_tagwrench') && g:pairtools_tagwrench

        call s:SetOption('TagWrenchHook', 'TagWrench#BuiltinNoHook')

        call s:SetIMap('<', 'TagWrench#StartContext', '', '<')
        call s:SetIMap('>', 'TagWrench#StopContext',  '', '>')

        call s:SetIMap('<Esc>',  'TagWrench#StopContext', "<Esc>")
        call s:SetIMap('<Up>',   'TagWrench#StopContext', "<Up>")
        call s:SetIMap('<Down>', 'TagWrench#StopContext', "<Down>")
        call s:SetIMap('<Left>',  'TagWrench#StopContextIf', '<Left>',  "L", "<")
        call s:SetIMap('<Right>', 'TagWrench#StopContextIf', '<Right>', "R", ">")

        let b:LoadedTagWrench = 1

    endif "}}}3

    "### Configure Jigsaw ### {{{3
    if exists('g:pairtools_jigsaw') && g:pairtools_jigsaw

        call s:SetIMap('<BS>', 'Jigsaw#Backspace', '')

        call Jigsaw#AddBackspaceHook('PairClamp#Erase', "\<BS>")
        call Jigsaw#AddBackspaceHook('TagWrench#Erase', "\<BS>")


        call s:SetIMap('<CR>', 'Jigsaw#CarriageReturn', '')

        call Jigsaw#AddCarriageReturnHook('PairClamp#Expand', "")
        call Jigsaw#AddCarriageReturnHook('TagWrench#Expand', "")
        
        let b:LoadedJigsaw = 1

    endif "}}}3

endfunction "}}}2

function! s:UnsetIMap(Key) "{{{2

    if maparg(a:Key, 'i') != ''
        exe 'iunmap <buffer> <silent> '.a:Key
    endif    

endfunction "}}}2

function! s:Destroy() "{{{2     

    " PairClamp Unset/Unlet {{{3
    if exists('g:pairtools_pairclamp') && g:pairtools_pairclamp

        if exists('b:LoadedPairClamp')

            unlet b:LoadedPairClamp

            for key in b:PTCloseKeys
                call s:UnsetIMap(key)
                call s:UnsetIMap('<M-' . key . '>')
            endfor

            unlet b:PTCloseKeys

        endif

    endif "}}}3

    " TagWrench Unset/Unlet {{{3
    if exists('g:pairtools_tagwrench') && g:pairtools_tagwrench 

        if exists('b:LoadedPairClamp')

            unlet b:LoadedTagWrench

            call s:UnsetIMap('<')
            call s:UnsetIMap('>')

            call s:UnsetIMap('<Esc>')
            call s:UnsetIMap('<Up>')
            call s:UnsetIMap('<Down>')
            call s:UnsetIMap('<Left>')
            call s:UnsetIMap('<Right>')

        endif

    endif "}}}3

    " Jigsaw Unset {{{3
    if exists('g:jigsaw_enable') && g:jigsaw_enable 
        
        if exists('b:LoadedJigsaw')
        
            call s:UnsetIMap('<BS>')

            unlet b:LoadedJigsaw

        endif

    endif
    " }}}3

endfunction "}}}2

function! s:IsNewFileType() "{{{2

    if !exists('b:PTFileType') || b:PTFileType != &ft
        let result = 1
    else
        let result = 0
    endif
    let b:PTFileType = &ft

    return result

endfunction "}}}2


autocmd FileType  * if <SID>IsNewFileType() | call <SID>Destroy() | endif 
autocmd FileType  * call <SID>Configure()


" Tag Wrench 'Potential Tag Event'
autocmd CursorMovedI * if TagWrench#IsTagEvent() | call TagWrench#EnterTagEvent() | endif

"}}}1


" PairTools Report {{{1

function! s:ReportOptions(Report, Prefix, ...)

    for name in a:000
        if exists('b:' . a:Prefix . name)
            call add(a:Report, '-  ' . a:Prefix . '|' . name . ':  ' . b:{a:Prefix}{name})
        endif
    endfor

endfunction

function! s:Report()

    let report = []

    call add(report, "PairTools Module Enable")
    call s:ReportOptions(report, 'Loaded',
                \'PairClamp',
                \'TagWrench',
                \'Jigsaw')

    call add(report, "PairTools Options Enable")
    call s:ReportOptions(report, 'PT',
                \'AutoClose', 
                \'ForcePairs', 
                \'SmartClose', 
                \'Antimagic')

    call add(report, "PairTools Other Options")
    call s:ReportOptions(report, 'PT',
                \'ClosePairs', 
                \'SmartCloseRules', 
                \'AntimagicField', 
                \'TagWrenchHook')

    echo join(report, "\n")

    unlet report

endfunction

command! PairToolsReport :call <SID>Report()

" }}}1

" vim: set fdm=marker :
