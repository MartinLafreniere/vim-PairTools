" PairClamp.vim - PairTools module handling single character pairs
" Last Changed: 2011 May 25
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

" PairClamp Auto-Close {{{1


function! pairclamp#Close(Key)

    if !b:PTAutoClose
        return a:Key
    endif

    echom a:Key

    let line   = getline('.')
    let column = col('.') - 1
    
    if (!has_key(b:PTWorkPairs, a:Key) || s:IsQuotes(a:Key)) && line[column] == a:Key
       
        " Prevent step out on certain syntax fields unless the cursor is on
        " the closing delimiter
        if !s:IsAntimagic(a:Key, 1)
            call cursor(line('.'), column + 2)
            let value = ""
        else
            let value = a:Key
        endif

    else

        " Prevent auto close on certain syntax fields
        if !s:IsAntimagic(a:Key, 0) && s:IsAllowClose(a:Key)
            call s:InsertClosing(a:Key) 
        endif
        let value = a:Key

    endif
 
    return value

endfunction


function! s:IsQuotes(Key)

    return has_key(b:PTWorkPairs, a:Key) && b:PTWorkPairs[a:Key] == a:Key

endfunction


function! s:IsAllowClose(Key)

    let line   = getline('.')
    let column = col('.') - 1

    if !has_key(b:PTWorkPairs, a:Key)
        return 0
    endif

    if b:PTSmartClose && line[column] =~ s:SmartRegex()
        return 0
    endif

    if b:PTApostrophe && line[column - 1] =~ '\a'
        return 0
    endif

    if a:Key == b:PTWorkPairs[a:Key]
        let isAllowed = s:CountPairs(a:Key) % 2 == 0
    else
        let isAllowed = s:CountPairs(a:Key) > -1
    endif

    return isAllowed

endfunction


function! s:CountPairs(Key)

    if a:Key == b:PTWorkPairs[a:Key]

        let unpaired = count(split(s:RemoveMatchedPairs(), '\zs'), a:Key)

    else

        let singles  = split(getline('.'), '\zs')
        let unpaired = count(singles, a:Key) - count(singles, b:PTWorkPairs[a:Key])

    endif

    return unpaired

endfunction


function! s:InsertClosing(Key)

    let line   = getline('.')
    let column = col('.') - 1

    if column > 0
        call setline('.', line[:(column-1)] . b:PTWorkPairs[a:Key] . line[(column):])
    else
        call setline('.', b:PTWorkPairs[a:Key] . line[(column):])
    endif

endfunction


function! s:RemoveMatchedPairs()

    let line = getline('.')

    " Setup regexes and check if cache need to be updated
    if !exists('b:PTReQuoteCache') || b:PTReQuoteCache.pairs != b:PTClosePairs
        let b:PTReQuoteCache = {}
        let b:PTReQuoteCache.pairs   = b:PTClosePairs
        let b:PTReQuoteCache.regex = '\%(' . join(s:BuildRegex(), '\|') . '\)'
    endif
    
    " Remove apostrophe
    if b:PTApostrophe
        let line = substitute(line, '\a\zs''', '', 'g')
    endif

    " Remove matched pairs
    let index = match(line, b:PTReQuoteCache.regex)

    while index > -1

        let match = matchstr(line, b:PTReQuoteCache.regex)
        
        if index > 0
            let line = line[:(index - 1)] . line[(strlen(match) + index):]
        else
            let line = line[strlen(match):]
        endif

        let index = match(line, b:PTReQuoteCache.regex)

    endwhile

    return line

endfunction


function! s:BuildRegex()

    let regexes = []
    
    for [key, value] in items(b:PTWorkPairs)

        if key == value
            
            let quote = s:EscapeSpecialValue(key)
            
            " Double quotes string uses escaped characters!
            if key == '"'
                call add(regexes, quote . '[^\\' . quote . ']*\%(\\.[^\\' .quote . ']*\)*' . quote )
            else
                call add(regexes, quote.'[^'.quote.']*'.quote )
            endif

        endif

    endfor

    return regexes

endfunction


function! s:EscapeSpecialValue(Value) 
     
    let specialValues = {'*': '', '.': '', '$': ''}

    if has_key(specialValues, a:Value)
        let value = escape(a:Value, a:Value)
    else
        let value = a:Value
    endif

    return value

endfunction


function! s:SmartRegex()

    " Cache regex to avoid recomputing everyting...
    if !exists('b:PTReSmartCache') || 
                \b:PTReSmartCache.pairs != b:PTClosePairs ||
                \b:PTReSmartCache.rules != b:PTSmartCloseRules

        let b:PTReSmartCache = {}
        let b:PTReSmartCache.pairs = b:PTClosePairs
        let b:PTReSmartCache.rules = b:PTSmartCloseRules

        let rules = split(b:PTSmartCloseRules, ',')
        " Replace ^ by all Work Pairs
        let uparrow = index(rules, '^')
        
        if uparrow > -1

            call remove(rules, uparrow)

            for key in keys(b:PTWorkPairs)
                call add(rules, key)
            endfor

        endif

        let b:PTReSmartCache.regex = '\%(' . join(rules, '\|') . '\)'

    endif

    return b:PTReSmartCache.regex

endfunction

"}}}1

" PairClamp Force Pair {{{1

function! pairclamp#Force(Key)

    if b:PTForcePairs
        call s:InsertClosing(a:Key)
    endif
    return a:Key    

endfunction

"}}}1

" PairClamp Erase {{{1

function! pairclamp#Erase()

    " This function only remove the closing key
    let result = 0
    let line   = getline('.')
    let column = col('.') - 1

    let opening = line[column - 1]
    let closing = line[column]
    
    if has_key(b:PTWorkPairs, opening) && b:PTWorkPairs[opening] == closing

        if column > 0
            call setline('.', line[:(column - 1)] . line[(column + 1):])
        else
            call setline('.', line[(column + 1):])
        endif
        let result = 1

    endif

    return result

endfunction
"}}}1

" PairClamp Expansion {{{1

function! pairclamp#Expand()

    let line   = getline('.')
    let column = col('.') - 1
    let row    = line('.')

    for [key, value] in items(b:PTWorkPairs)

        if line[(column-1):(column)] == key.value
            " Keep indentation clean
            let startSpace = match(line, '\S\+')

            " Do actual expansion equivalent to <CR><CR><UP><TAB>
            call setline('.', line[:(column-1)])
            call append(row,     repeat(' ', startSpace + &l:shiftwidth))
            call append(row + 1, repeat(' ', startSpace) . line[(column):])
            
            " Place the cursor as though the user pressed tab for indentation
            call cursor(row + 1, startSpace + &l:shiftwidth + 1)
            
            return 1

        endif

    endfor

    return 0
    

endfunction

"}}}1

" Antimagic {{{1

function! s:IsAntimagic(Key, IsClosing)

    if !b:PTAntimagic
        return 0
    endif
    
    let currentSyntax = s:GetCurrentSyntax() 

    let stringSyntax = "None"
    if b:PTAntimagicField =~? "String" && a:Key == '"'
        let stringSyntax  = s:IsString(a:Key)
        if currentSyntax != "String" && stringSyntax == "String"
            return 1
        endif
    endif

    let constantSyntax = "None"
    if b:PTAntimagicField =~? "Constant"
        let constantSyntax = s:IsConstant(a:Key)
        if currentSyntax != "Constant" && constantSyntax == "Constant"
            return 1 
        endif
    endif
    
    return b:PTAntimagicField =~? currentSyntax && !a:IsClosing

endfunction


function! s:GetCurrentSyntax()
    
    let column = col('.')
    let cursor = (column == col('$') ? column-1 : column)

    let syntaxName = synIDattr(synIDtrans(synID(line('.'), cursor, 1)), 'name')

    return empty(syntaxName) ? "None" : syntaxName

endfunction


function! s:IsString(Key)

    let line   = getline('.')
    let column = col('.')-1

    let newline = s:RemoveMatchedPairs()

    " Check syntax after removing backslash on left, because
    " it could be the start of an escaped character
    if line[column-1] == '\' && newline =~ '\'
        call setline('.', line[:(column-2)].line[(column):])
        call cursor(line('.'), column)
    endif

    let syntax = s:GetCurrentSyntax() 

    call cursor(line('.'), column + 1)
    call setline('.', line)

    return syntax

endfunction


function! s:IsConstant(Key)

    let line   = getline('.')
    let column = col('.')-1

    let prefix = (column == 0 ? "" : line[:(column-1)])
    call setline('.', prefix . a:Key . line[(column):])
    
    let syntax = s:GetCurrentSyntax()

    call setline('.', line)

    return syntax

endfunction


"}}}1

" Mapping Utilities {{{1

function! s:ToWorkPairs(String)

    " Only convert the following format: "<o0>:<c0>,<o1>:<c1>,..."
    let work = {}

    for pair in split(a:String, ',')
       let [key, value] = split(pair, ':')
       let work[key]    = value 
    endfor

    return work

endfunction


function! pairclamp#UniquifyCloseKeys(...)

    " Use provided pairs as working pairs if passed to function
    let b:PTWorkPairs = s:ToWorkPairs(a:0 > 0 ? a:000[0] : b:PTClosePairs)

    " Here, we basically filter all keys that can be pressed to start
    " and end a pair, making sure that it only appears once inside the
    " list.
    let b:PTCloseKeys = keys(b:PTWorkPairs) + values(b:PTWorkPairs)

    let list  = []
    for key in b:PTCloseKeys
        if index(list, key) == -1
            call add(list, key)
        endif
    endfor

    return list

endfunction

function! pairclamp#SanitizeKey(Key)

    let specialKeys  = {'|': '<Bar>'}
    
    return (has_key(specialKeys, a:Key) ? specialKeys[a:Key] : a:Key)

endfunction


" }}}1

" vim: set fdm=marker :
