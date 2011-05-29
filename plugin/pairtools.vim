" pairtools.vim - PairTools plugin
" Last Changed: 2011 May 25
" Maintainer:   Martin Lafreniere <pairtools@gmail.com>
"
" Copyright (C) 2011 by Martin Lafreni�re
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

" Current version
let g:loaded_pairtools = '1.5.2'


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
        call add(argList, '"' . escape(arg, '"|') . '"')
    endfor

    exe 'inoremap <silent> <buffer> ' . a:Key . 
                \' <C-R>=' . a:FuncName . '(' . join(argList, ',') . ')<CR>' . a:Command
    
endfunction "}}}2

function! s:Configure() "{{{2

    "### Configure PairClamp ### {{{3
    if exists('g:pairtools_'.&ft.'_pairclamp') && g:pairtools_{&ft}_pairclamp
        
        " Options are turn off by default now...
        call s:SetOption('AutoClose', 0)
        call s:SetOption('ClosePairs', "[:],(:),{:}")
        call s:SetOption('ForcePairs', 0)
        call s:SetOption('SmartClose', 0)
        call s:SetOption('SmartCloseRules', '\w')
        call s:SetOption('Apostrophe', 0)
        call s:SetOption('Antimagic', 0)
        call s:SetOption('AntimagicField', "String,Comment")
        
        let uniq = pairclamp#UniquifyCloseKeys()

        " Mappings
        if b:PTAutoClose
            for key in uniq
                call s:SetIMap(pairclamp#SanitizeKey(key), 'pairclamp#Close', '', key)
            endfor
        endif

        if b:PTForcePairs 
            for key in keys(b:PTWorkPairs)
                if key != '|'
                    call s:SetIMap('<M-' . key . '>', 'pairclamp#Force', '', key) 
                else
                    call s:SetIMap('<C-L><Bar>',       'pairclamp#Force', '', key)
                endif
            endfor
        endif

        let b:LoadedPairClamp = 1

    endif " }}}3

    "### Configure TagWrench ### {{{3
    if exists('g:pairtools_'.&ft.'_tagwrench') && g:pairtools_{&ft}_tagwrench

        call s:SetOption('TagWrenchHook', 'tagwrench#BuiltinNoHook')

        call s:SetIMap('<', 'tagwrench#StartContext', '', '<')
        call s:SetIMap('>', 'tagwrench#StopContext',  '', '>')

        call s:SetIMap('<Esc>',  'tagwrench#StopContext', "<Esc>")
        call s:SetIMap('<Up>',   'tagwrench#StopContext', "<Up>")
        call s:SetIMap('<Down>', 'tagwrench#StopContext', "<Down>")
        call s:SetIMap('<Left>',  'tagwrench#StopContextIf', '<Left>',  "L", "<")
        call s:SetIMap('<Right>', 'tagwrench#StopContextIf', '<Right>', "R", ">")

        let b:LoadedTagWrench = 1

    endif "}}}3

    "### Configure Jigsaw ### {{{3
    if exists('g:pairtools_'.&ft.'_jigsaw') && g:pairtools_{&ft}_jigsaw

        call s:SetIMap('<BS>', 'jigsaw#Backspace', '')
        call s:SetIMap('<CR>', 'jigsaw#CarriageReturn', '')

		if exists('g:pairtools_'.&ft.'_pairclamp') && g:pairtools_{&ft}_pairclamp
			call s:SetOption('PCEraser',   0)
			call s:SetOption('PCExpander', 0)

			call jigsaw#AddBackspaceHook(b:PTPCEraser ? 'pairclamp#Erase' : 'jigsaw#NoErase', "\<BS>")
			call jigsaw#AddCarriageReturnHook(b:PTPCExpander ? 'pairclamp#Expand' : 'jigsaw#NoExpand', "")
		endif

		if exists('g:pairtools_'.&ft.'_tagwrench') && g:pairtools_{&ft}_tagwrench
			call s:SetOption('TWEraser',   0)
			call s:SetOption('TWExpander', 0)

			call jigsaw#AddBackspaceHook(b:PTTWEraser ? 'tagwrench#Erase' : 'jigsaw#NoErase', "\<BS>")
			call jigsaw#AddCarriageReturnHook(b:PTTWExpander ? 'tagwrench#Expand' : 'jigsaw#NoExpand', "")
		endif
        
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
    if exists('g:pairtools_'.&ft.'_pairclamp') && g:pairtools_{&ft}_pairclamp

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
    if exists('g:pairtools_'.&ft.'_tagwrench') && g:pairtools_{&ft}_tagwrench 

        if exists('b:LoadedTagWrench')

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
    if exists('g:jigsaw_'.&ft.'_enable') && g:jigsaw_{&ft}_enable 
        
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
autocmd CursorMovedI * if tagwrench#IsTagEvent() | call tagwrench#EnterTagEvent() | endif

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
                \'Apostrophe',
                \'Antimagic',
                \'PCEraser',
                \'PCExpander',
                \'TWEraser',
                \'TWExpander')

    call add(report, "PairTools Specific Options")
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

" PairTools Auto-Generate Sample File {{{1

function! s:AddSampleOption(List, FileType, Option, Value)

    call add(a:List, 'let g:pairtools_'.a:FileType.'_'.a:Option.' = '.a:Value)

endfunction

function! s:AddComment(List, Comment)

    call add(a:List, '" '.a:Comment)

endfunction

function! s:GenerateSample(FileType)

    let options = []

    call s:AddComment(options, 'File auto-generated by PairTools '.g:loaded_pairtools)
    call s:AddComment(options, 'Enable modules')
    call s:AddSampleOption(options, a:FileType, 'pairclamp', '1')
    call s:AddSampleOption(options, a:FileType, 'tagwrench', '1')
    call s:AddSampleOption(options, a:FileType, 'jigsaw',    '1')

    call s:AddComment(options, 'Configure PairClamp')
    call s:AddSampleOption(options, a:FileType, 'autoclose',  '0')
    call s:AddSampleOption(options, a:FileType, 'forcepairs', '0')
    call s:AddSampleOption(options, a:FileType, 'closepairs',      '"(:),[:],{:}"')
    call s:AddSampleOption(options, a:FileType, 'smartclose', '0')
    call s:AddSampleOption(options, a:FileType, 'smartcloserules', "'\\w'")
    call s:AddSampleOption(options, a:FileType, 'apostrophe', '0')
    call s:AddSampleOption(options, a:FileType, 'antimagic',  '0')
    call s:AddSampleOption(options, a:FileType, 'antimagicfield',  '"Comment,String"')
    call s:AddSampleOption(options, a:FileType, 'pcexpander', '0')
    call s:AddSampleOption(options, a:FileType, 'pceraser',   '0')
    
    call s:AddComment(options, 'Configure TagWrench')
    call s:AddSampleOption(options, a:FileType, 'tagwrenchhook',   "'tagwrench#BuiltinNoHook'")
    call s:AddSampleOption(options, a:FileType, 'twexpander', '0')
    call s:AddSampleOption(options, a:FileType, 'tweraser',   '0')

    if !exists('g:pairtools_samplefile_path')
        let path = split(&rtp, ',')[0] . '/'
    else
        let path = g:pairtools_samplefile_path . '/'
    endif

    call writefile(options, path.a:FileType.'.vim')

endfunction

command! -nargs=1 PairToolsSampleFile :call <SID>GenerateSample(<f-args>)
" }}}1

" vim: set fdm=marker :
