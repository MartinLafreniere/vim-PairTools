" Jigsaw.vim - PairTools module handling various keys with side-effects
" Last Changed: 2011 May 18
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
 
" Backspace Hook API {{{1

function! jigsaw#Backspace()

    let line   = getline('.')
    let column = col('.') - 1

    " Try each registered hook until one is actually executed
    for [hook, value] in items(b:PTBackspaceHookTable)        
        
        exe 'let result = ' . hook . '()'
        if result 
            return value
        endif

    endfor 

    return "\<BS>"

endfunction

" Public function provided to the user to add custom hooks
"   A hook must 0 if not executing in its context, else 1
"
function! jigsaw#AddBackspaceHook(HookFullName, HookReturnValue)

    if !exists('b:PTBackspaceHookTable')
        let b:PTBackspaceHookTable = {}
    endif

    if !has_key(b:PTBackspaceHookTable, a:HookFullName)
        let b:PTBackspaceHookTable[a:HookFullName] = a:HookReturnValue
    endif

endfunction

function! jigsaw#NoErase()
    return 0
endfunction

"}}}1

" Carriage Return Hook API {{{1

function! jigsaw#CarriageReturn()

    let line   = getline('.')
    let column = col('.') - 1

    " Try each registered hook until one is actually executed
    for [hook, value] in items(b:PTCarriageReturnHookTable)        
        
        exe 'let result = ' . hook . '()'
        if result 
            return value
        endif

    endfor 

    return "\<CR>"

endfunction

"
" Public function provided to the user to add custom hooks
"   A hook must 0 if not executing in its context, else 1
"
function! jigsaw#AddCarriageReturnHook(HookFullName, HookReturnValue)

    if !exists('b:PTCarriageReturnHookTable')
        let b:PTCarriageReturnHookTable = {}
    endif

    if !has_key(b:PTCarriageReturnHookTable, a:HookFullName)
        let b:PTCarriageReturnHookTable[a:HookFullName] = a:HookReturnValue
    endif

endfunction

function! jigsaw#NoExpand()
    return 0
endfunction

"}}}1

" vim: set fdm=marker :
