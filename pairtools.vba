" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
autoload/jigsaw.vim	[[[1
110
" jigsaw.vim - PairTools module handling various keys with side-effects
" Last Changed: 2011 May 17
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

function! Jigsaw#Backspace()

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
function! Jigsaw#AddBackspaceHook(HookFullName, HookReturnValue)

    if !exists('b:PTBackspaceHookTable')
        let b:PTBackspaceHookTable = {}
    endif

    if !has_key(b:PTBackspaceHookTable, a:HookFullName)
        let b:PTBackspaceHookTable[a:HookFullName] = a:HookReturnValue
    endif

endfunction

function! Jigsaw#NoErase()
    return 0
endfunction

"}}}1

" Carriage Return Hook API {{{1

function! Jigsaw#CarriageReturn()

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
function! Jigsaw#AddCarriageReturnHook(HookFullName, HookReturnValue)

    if !exists('b:PTCarriageReturnHookTable')
        let b:PTCarriageReturnHookTable = {}
    endif

    if !has_key(b:PTCarriageReturnHookTable, a:HookFullName)
        let b:PTCarriageReturnHookTable[a:HookFullName] = a:HookReturnValue
    endif

endfunction

function! Jigsaw#NoExpand()
    return 0
endfunction

"}}}1

" vim: set fdm=marker :
autoload/pairclamp.vim	[[[1
448
" pairclamp.vim - PairTools module handling single character pairs
" Last Changed: 2011 May 17
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


function! PairClamp#Close(Key)

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

    if b:PTSmartClose && line[column + 1] =~ s:SmartRegex()
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

function! PairClamp#Force(Key)

    if b:PTForcePairs
        call s:InsertClosing(a:Key)
    endif
    return a:Key    

endfunction

"}}}1

" PairClamp Erase {{{1

function! PairClamp#Erase()

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

function! PairClamp#Expand()

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


function! PairClamp#UniquifyCloseKeys(...)

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

function! PairClamp#SanitizeKey(Key)

    let specialKeys  = {'|': '<Bar>'}
    
    return (has_key(specialKeys, a:Key) ? specialKeys[a:Key] : a:Key)

endfunction


" }}}1

" vim: set fdm=marker :
autoload/tagwrench.vim	[[[1
506
" tagwrench.vim - PairTools module handling angle brackets pair and XML/HTML tags
" Last Changed: 2011 May 17
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

" Angle Brackets Auto-Close Event/Context {{{1

function! TagWrench#StartContext(Value)

    " Make sure no context was previously started to fire a Tag Event
    if !exists('b:TWContext') || !b:TWContext
        let b:TWTagEvent = 1
    endif
    let b:TWContext  = 1

    return a:Value

endfunction


function! TagWrench#StopContext(...)

    let value = (a:0 > 0 ? a:000[0] : '')

    let line   = getline('.')
    let cursor = col('.') - 1

    if exists('b:TWContext') && b:TWContext
        
        " Make sure the > wasn't pressed inside an attribute field
        if s:IsAttributeContext() && value == '>'
            return value
        endif

        " Pressed either '>' or 'Esc' left of '>'
        if line[cursor] == '>'
            " Call a hook for further processing...
            call s:TagHook(b:TWContextBegin, cursor+1)
            call cursor(line('.'), cursor+2)
            let value = ''
        endif

    endif

    if exists('b:TWContextBegin')
        unlet b:TWContextBegin
    endif
    let b:TWContext  = 0
    let b:TWTagEvent = 0
    
    return value

endfunction


function! s:IsAttributeContext()

    let line   = getline('.')
    let column = col('.') - 1

    let start = 0

    let attr  = 0
    while start < column

        if line[start] =~ '[''"]'
            let attr = !attr
        endif

        let start += 1

    endwhile

    return attr

endfunction


function! TagWrench#StopContextIf(Direction, Value)

    let line   = getline('.')
    let cursor = col('.') - 1

    let position = (a:Direction == 'L' ? cursor - 1 : cursor)

    " Stop only when getting out of < ... >
    if exists('b:TWContext') && b:TWContext 
        
        if !s:IsAttributeContext() && line[position] == a:Value
            if exists('b:TWContextBegin')
                unlet b:TWContextBegin
            endif
            let b:TWContext  = 0
            let b:TWTagEvent = 0
        endif

    endif

    return ""

endfunction


function! s:FindContextBegin(Delimit)

    let line   = getline('.')
    let start  = col('.') - 2

    while line[start] != a:Delimit
        let start -= 1
    endwhile

    return start

endfunction


function! s:IsContextUnclosed()

    let line = split(getline('.'), '\zs')

    let openings = count(line, '<')
    let closings = count(line, '>')

    return openings - closings

endfunction


function! TagWrench#EnterTagEvent()

    if !exists('b:TWContextBegin')
        let b:TWContextBegin = s:FindContextBegin('<')
    endif

    let line   = getline('.')
    let cursor = col('.') - 1

    " Wait for first character typed
    if line[cursor-1] == '<'
        return
    endif

    let symbol = ''
    if line[b:TWContextBegin + 1] =~ '[?%]'
        let symbol = line[b:TWContextBegin + 1]
    endif

    " Check for legal context: |word|, !, %, ?, /
    if line[b:TWContextBegin + 1] !~ '[[:alnum:]_!/]' && symbol == ''
        unlet b:TWContextBegin
        let   b:TWContext = 0
    else
        if s:IsContextUnclosed() > 0
            call setline('.', line[:(cursor-1)].symbol.'>'.line[(cursor):])
        endif
    endif

    " Delimiters such as <%,%> and <?,?> do not trigger a context
    if symbol != ''
        unlet b:TWContextBegin
        let   b:TWContext = 0
    endif

    let b:TWTagEvent = 0

endfunction


function! TagWrench#IsTagEvent()

    if !exists('b:TWTagEvent')
        let b:TWContext  = 0
        let b:TWTagEvent = 0
    endif

    return b:TWTagEvent
        
endfunction

" }}}1

" Angle Brackets Erase {{{1

function! TagWrench#Erase()

    let line   = getline('.')
    let column = col('.') - 1

    " Easiest case is <|>
    if line[(column - 1):(column)] == '<>'
        return s:RemoveDelimiters(1)
    endif
    
    " Case <%|%> and <?|?>
    if line[(column - 2):(column + 1)] =~ '<[%?][%?]>'
        return s:RemoveDelimiters(2)
    endif

    " Next is <tag>|</tag>
    if line[(column - 1):(column)] == '><' 
        if s:RemoveMatchedTags()
            return 1
        endif
    endif
    
    " Finally, it can be <tag>|, <tag/>|, <!tag>|, <!tag/>, </tag>
    if line[column - 1] == '>'
        return s:RemoveVoidTag()
    endif
    
    return 0

endfunction


function! s:RemoveDelimiters(Length)

    let column = col('.') - 1

    call s:RemoveRange(column - a:Length + 1, column - a:Length + 1, column + a:Length - 1)
    return 1

endfunction


function! s:RemoveMatchedTags()

    let result = 0
    let line   = getline('.')
    let column = col('.') - 1
     
    if line[column + 1] != '/'
        return result
    endif

    " Get closing tag name (remove starting </)
    let closingName = matchstr(line[(column + 2):], '^\w\+')
    
    let closingLength = strlen(closingName)

    let end = column + closingLength + 2

    " Reverse look for <tagname because muliples tag with the same
    " name on one line is possible
    let start = column - 1
    
    let skip = 0
    while (skip || line[start] != '<') && start > -1
        if line[start] =~ '["'']' && line[start - 1] != '\'
            let skip = !skip
        endif
        let start -= 1
    endwhile

    if start > - 1 && line[(start + 1):(start + closingLength)] == closingName
        " Compensate begin by one for <BS>
        call s:RemoveRange(start+1, start + 1, end)
        call cursor(line('.'), start + 2)
        let result = 1
    endif

    return result

endfunction


function! s:RemoveVoidTag()

    let result = 0
    let line   = getline('.')
    let column = col('.') - 1

    " Reverse look for the start of the void tag
    let start = column - 1

    let skip = 0
    while (skip || line[(start):] !~ '^<[!/]\?\w\+') && start > -1
        if line[start] =~ '["'']' && line[start - 1] != '\'
            let skip = !skip
        endif
        let start -= 1
    endwhile

    if start > -1
        call s:RemoveRange(start+1, start+1, column - 1)
        call cursor(line('.'), start + 2)
        let result = 1
    endif

    return result

endfunction
    

function! s:RemoveRange(Current, Begin, End)

    let line = getline('.')

    if a:Current > 0
        call setline('.', line[:(a:Begin - 1)] . line[(a:End + 1):])
    else
        call setline('.', line[(a:End + 1):])
    endif

endfunction
"}}}1

" Angle Brackets Expansion {{{1

function! TagWrench#Expand()

    let line   = getline('.')
    let column = col('.') - 1
    
    " Cases <%|%> and <?|?> / <tag>|</tag>
    if (line[(column - 2):(column + 1)] =~ '<[%?][%?]>') || 
                \(line[(column - 1):(column)] == '><')
        return s:ExpandCR()
    endif

    return 0

endfunction

function! s:ExpandCR()

    let line   = getline('.')
    let column = col('.') - 1
    let row    = line('.')

    let startSpace = match(line, '\S\+')

    " Do expansion
    call setline('.', line[:(column - 1)])
    call append(row,     repeat(' ', startSpace + &l:shiftwidth))
    call append(row + 1, repeat(' ', startSpace) . line[(column):])

    call cursor(row + 1, startSpace + &l:shiftwidth + 1)

    return 1

endfunction

"}}}1

" TagWrench Hook Public API {{{1

function! s:TagHook(ContextBegin, ContextEnd)

    " Add built in hook if not already done
    call TagWrench#AddHook('TagWrench#BuiltinNoHook')
    call TagWrench#AddHook('TagWrench#BuiltinBasicTagHook')
    call TagWrench#AddHook('TagWrench#BuiltinHTML5Hook')

    if index(g:PTTagWrenchHookTable, b:PTTagWrenchHook) > -1
        exe 'call ' . b:PTTagWrenchHook . '(' .a:ContextBegin . ',' . a:ContextEnd . ')'
    endif
     
endfunction


" Public function provided to the user to add custom hooks
"   A Hook is passed two arguments
"   1. Context Begin: this is the position of the < character
"   2. Context End:   this is the position after the > character
"   See BuiltinBasicTagHook for an example.
function! TagWrench#AddHook(HookFullName)

    if !exists('g:PTTagWrenchHookTable')
        let g:PTTagWrenchHookTable = []
    endif

    if index(g:PTTagWrenchHookTable, a:HookFullName) == -1
        call add(g:PTTagWrenchHookTable, a:HookFullName)
    endif

endfunction


function! TagWrench#BuiltinNoHook(ContextBegin, ContextEnd)
    " Do nothing
    return
endfunction


" Simple tag handling: complement starting <tag> with ending </tag>
" Arguments: Receives the context begin (tag <) and context end (tag >)
function! TagWrench#BuiltinBasicTagHook(ContextBegin, ContextEnd, ...)

    let line = getline('.')
    
    let startTag = line[(a:ContextBegin):(a:ContextEnd-1)]
    let tagName  = matchstr(startTag, '^<\zs!\?\w\+')
    
    let voids = (a:0 > 0 ? a:000[0] : '')
    if index(split(voids, ','), tolower(tagName)) == -1 && startTag !~ '/>$' && startTag !~ '^<[!/]'

        let closingPos = s:SurroundClosingTag(a:ContextEnd)
        if closingPos > 0
            call setline('.', line[:(closingPos-1)] . '</' . tagName . '>' . line[(closingPos):])
        endif

    endif

endfunction


function! TagWrench#BuiltinHTML5Hook(ContextBegin, ContextEnd)

    " Define HTML5 void elements
    let voids = "area,base,br,col,command,embed,hr,img,input,keygen,link,meta,param,source,track,wbr"

    call TagWrench#BuiltinBasicTagHook(a:ContextBegin, a:ContextEnd, voids)

endfunction


function! s:SurroundClosingTag(OpeningEnd)

    let line = getline('.')

    " Be somewhat smart when invoking tag surround
    if line[(a:OpeningEnd+1):] =~ '^\s*$'
        return a:OpeningEnd
    endif

    let offset = 0
    
    " Get input and find motion delimiter
    let tagCmd  = input('')
    let delimit = match(tagCmd, '\a')

    let index  = delimit > 0 ? tagCmd[:(delimit - 1)] : 1
    let motion = tagCmd[(delimit):]

    " For now it supports: char, word, WORD, EOL or CR
    if motion == '$'

        let offset = strlen(line[(a:OpeningEnd):])
   
    elseif motion ==# 'l'

        let offset = index
  
    elseif motion ==# 'w'
        
        while index > 0
            let offset += matchend(line[(a:OpeningEnd + offset):], '\%(\w\+\|$\)')
            let index -= 1
        endwhile
 
    elseif motion ==# 'W'
            
        while index > 0
            let offset += matchend(line[(a:OpeningEnd + offset):], '\%(\S\+\|$\)')
            let index -=1
        endwhile

    elseif motion ==# 't'

        let tagName = input('Tag Name: ')

        let offset = matchend(line[(a:OpeningEnd):], '</'.tagName.'>')
        
        "Couldn't find ending tag, look for void
        if offset == -1 
            let offset = matchend(line[(a:OpeningEnd):], '<'.tagName.'[^>]*>')
        endif

        let offset = offset == -1 ? 0 : offset

    elseif motion == '/'

        let offset = -1 * a:OpeningEnd

    else 
        let offset = 0
    endif 

    return a:OpeningEnd + offset

endfunction

" }}}1

" vim: set fdm=marker :
plugin/pairtools.vim	[[[1
286
" pairtools.vim - PairTools plugin
" Last Changed: 2011 May 17
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

" Current version
let g:loaded_pairtools = '1.5'


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
        call s:SetOption('Antimagic', 0)
        call s:SetOption('AntimagicField', "String,Comment")
        
        let uniq = PairClamp#UniquifyCloseKeys()

        " Mappings
        if b:PTAutoClose
            for key in uniq
                call s:SetIMap(PairClamp#SanitizeKey(key), 'PairClamp#Close', '', key)
            endfor
        endif

        if b:PTForcePairs 
            for key in keys(b:PTWorkPairs)
                if key != '|'
                    call s:SetIMap('<M-' . key . '>', 'PairClamp#Force', '', key) 
                else
                    call s:SetIMap('<C-L><Bar>',       'PairClamp#Force', '', key)
                endif
            endfor
        endif

        let b:LoadedPairClamp = 1

    endif " }}}3

    "### Configure TagWrench ### {{{3
    if exists('g:pairtools_'.&ft.'_tagwrench') && g:pairtools_{&ft}_tagwrench

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
    if exists('g:pairtools_'.&ft.'_jigsaw') && g:pairtools_{&ft}_jigsaw

        call s:SetIMap('<BS>', 'Jigsaw#Backspace', '')
        call s:SetIMap('<CR>', 'Jigsaw#CarriageReturn', '')

		if exists('g:pairtools_'.&ft.'_pairclamp') && g:pairtools_{&ft}_pairclamp
			call s:SetOption('PCEraser',   0)
			call s:SetOption('PCExpander', 0)

			call Jigsaw#AddBackspaceHook(b:PTPCEraser ? 'PairClamp#Erase' : 'Jigsaw#NoErase', "\<BS>")
			call Jigsaw#AddCarriageReturnHook(b:PTPCExpander ? 'PairClamp#Expand' : 'Jigsaw#NoExpand', "")
		endif

		if exists('g:pairtools_'.&ft.'_tagwrench') && g:pairtools_{&ft}_tagwrench
			call s:SetOption('TWEraser',   0)
			call s:SetOption('TWExpander', 0)

			call Jigsaw#AddBackspaceHook(b:PTTWEraser ? 'TagWrench#Erase' : 'Jigsaw#NoErase', "\<BS>")
			call Jigsaw#AddCarriageReturnHook(b:PTTWExpander ? 'TagWrench#Expand' : 'Jigsaw#NoExpand', "")
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
                \'Antimagic',
                \'PCEraser',
                \'PCExpander',
                \'TWEraser',
                \'TWExpander')

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
doc/pairtools.txt	[[[1
551
*pairtools.txt*  For Vim version 7.3.  Last change: 2011 March 29


	    PAIRTOOLS 1.5 PLUGIN FOR VIM	by Martin Lafreniere


Help on PairTools                                     *pairtools-help*

|1.| Introduction					|pairtools-intro|
|2.| PairClamp						|pairtools-pairclamp|
  |2.1| Auto-Close						|pairclamp-autoclose|
  |2.2| Force Pairs						|pairclamp-forcepairs|
  |2.3| Smart Close						|pairclamp-smartclose|
  |2.4| Antimagic						|pairclamp-antimagic|
  |2.5| Eraser							|pairclamp-eraser|
  |2.6| Expander						|pairclamp-expander|
|3.| TagWrench						|pairtools-tagwrench|
  |3.1| Hooks							|tagwrench-hooks|
  |3.2| Eraser							|tagwrench-eraser|
  |3.3| Expander						|tagwrench-expander|
|4.| Jigsaw							|pairtools-jigsaw|
|5.| Installation                   |pairtools-install|
|6.| Filetype Files Examples		|pairtools-examples|
|7.| Few Thoughts					|pairtools-thoughts|
|8.| License                        |pairtools-license|
|9.| Credits                        |pairtools-credits|

 
==============================================================================
*1.* Introduction										*pairtools-intro*

The PairTools plugin can be seen as a "bundle" of tools to handle various
"pair" operations. It also offers a flexible way to set pairs and options per
filetypes. Therefore, it is possible to have pairs and options set for editing 
C++ files while also editing XML files with other pairs and options inside the
same window.

The plugin is modular, i.e. related features are grouped inside a module, and 
other related features inside others groups. In the current version, there are 
three modules: pairclamp.vim, tagwrench.vim and jigsaw.vim.

The PairClamp module works with single characters pairs such as (,). The
TagWrench module works with angle brackets <,> and tags <tagname>. The Jigsaw
module coordinates some key maps between PairClamp and TagWrench, such as when
pressing backspace and calling the right hook function. The pairtools.vim file 
defines autocmds, mappings and options to make all the modules work.

Filetypes

The plugin work with {filetype}.vim files inside the user ftplugin/ directory
to setup itself inside the current buffers. For example, the user needs to
specify all the options he wants to enable for HTML editing; he must do so 
inside his ftplugin/html.vim. If that user also edits PHP file then he must
also specify a ftplugin/php.vim file with his options set for PHP.

Report

The plugin feature a simple "report" command. Type :PairToolsReport and it
will show all option values.


Note: Version 1.0 included a surround feature now removed. The user is 
      encouraged to use the surround plugin for vim instead.

==============================================================================
*2.* PairClamp											*pairtools-pairclamp*

The PairClamp module handle all operations involving single character pairs.
This include auto-closing a pair, stepping out from a pair, forcing a pair,
defining when a pair should not auto-close, erasing them with one key and
expanding then with carriage return.

To enable PairClamp, the user must provide inside his ftplugin/{filetype}.vim
the following: >
	
	let g:pairtools_{filetype}_pairclamp = 1
<

*2.1* Auto-Close										*pairclamp-autoclose*

In order to use that feature, the user must enable it and specify which pairs
he wants to work with. To do so he must set these options into his filetype
file. For example, to set these options for Python the user needs to add this
into his ftplugin/python.vim: >

	let g:pairtools_python_autoclose  = 1
    let g:pairtools_python_closepairs = '(:),[:],":"'

This will enable the auto-closing feature and set the pairs (),{},[],''. Now
the user only need to have a file with filetype set to python and when he will
type the opening character of the pairs, that is a ( for a () pairs, then the
plugin will automatically add a closing character, thus ) in the forementioned
example. Basically the steps go like this (the | denotes the cursor):

	Type opening char:		(|
	Plugin adds closing:	(|)

Thus, the pair is automatically closed, AND the cursor is kept right after the
opening character. Now let's write something inside these parens:

	Type Hello World:		(Hello World|)
    Press ) next to the ):  (Hello World)|

Now when the user press the closing character when next to (and left of) the
closing character, it will automatically push the cursor on the right of it.

*2.2* Force Pairs										*pairclamp-forcepairs*

Sometimes, it is useful to be able to force a pair to automatically close. For
example, the antimagic feature will prevent auto-closing inside some syntax
area. If the users really needs to add a pair and start editing in-between
them, this will allow the user to do so. This is really useful to add Python
DOCSTRING and immediatly start writing inside the DOCSTRING.

For example, to enable the force pairs for python, the user must add this to 
his python.vim file: >

	let g:pairtools_python_forcepairs = 1
<
Continuing on this example, the feature will use all the pairs set inside the
g:pairtools_python_closepairs and will map them with the META key (ALT key).
So for example, the double quote defined inside ftplugin/python.vim will have a
corresponding force pairs map at <M-">.

There is one notable exception to this and this is the bar |, which cannot be
mapping to the META key and instead uses <C-L>|.

The following example shows how this can be applied to python DOCSTRING:

	Type opening char ":		"|"

Typing " would only get the user out! Thus using force pairs by pressing <M-">
will yield to:

	Type <M-">:                 ""|""
    Type <M-"> again:		    """|"""

Then the user can type his text and then pressing " three times will get him
out.

*2.3* Smart Close										*pairclamp-smartclose*

This feature can prevent auto-closing in some situations. These situations are
specified using a list of regex-like expressions. The user has to enable the
feature and specify in which condition to prevent auto-closing. For example,
let's say the user wants to prevents auto-closing when left of a word
character and opening parens inside his ftplugin/python.vim: >

	let g:pairtools_python_smartclose = 1
	let g:pairtools_python_smartcloserules = '\w,('
<
In smartcloserules, the \w represent any word character.

There is also the special character ^ which means all opening character
defined inside g:pairtools_{filetype}_closepairs. So, if there user has the
following closepairs set in his python.vim: >

	let g:pairtools_python_closepairs = '(:),[:],":"'
	let g:pairtools_python_smartcloserule = '\w,^'
<
Then the smartcloserule list can be considered to be '\w,(,[,"'. As rules are
are using as regex-like expression, it is important to escape the following 
characters: \*, \., \$ and \^.

*2.4* Antimagic											*pairclamp-antimagic*

The antimagic feature allows to define syntax areas as antimagic fields, where
pairclamp auto-closing "magic" is prevented. To enable antimagic and set
syntax areas to prevent the magic the user need, for example in his python
file, add the following: >

	let g:pairtools_python_antimagic = 1
	let g:pairtools_python_antimagicfield = "Comment,String,Special"

This will prevent auto-close inside comments, strings and special areas.

*2.5* Eraser											*pairclamp-eraser*

This feature allows to erase a whole pair using the backspace key. Using the
python example, the user can enable it using: >

	let g:pairtools_python_pceraser = 1
<
Then when the cursor is immediatly between the opening and closing character,
pressing backspace will automatically erase the closing character as well.
Example:

	We have this:			(Hello World|)
    Backspacing till (:		(|)
    One more backspace:		|

*2.6* Expander											*pairclamp-expander*

The expander work when the carriage return key is hit when in-between
characters forming a pair. Using the python filetype as earlier, one can
enable this feature as follow: >

	let g:pairtools_python_pcexpander = 1
<
This will produce the following action:

	Let say you have this:		def somefunction(|)

	Pressing enter:				def somefunction(
                                    |
                                )

The user can see this action as follow: it presses enter, then tab for
indentation, then a second enter and finally put back the cursor on the
indentation.

==============================================================================
*3.* TagWrench											*pairtools-tagwrench*

This module is dedicated to the angle brackets <,> and tags formed by them.
Using the angle brackets pair inside PairClamp can lead to very confusing
situations and lot's of deletes. After all, these are used as lesser-something
and greater-something operators in many languages. And it's even more worse
when the user must used them inside html with for example php code embedded.

TagWrench resolve this by creating a "tag context" to avoid closing an opening
angle bracket when it is not necessary. Furthermore, the addition of hooks
allows to automatically add a closing tag when the first tag made with the 
angle brackets is a starting tag. More details will follow about this feature
later.

It is easier to grasp these features using VIM code and HTML code examples.
For now we will not use any hook, i.e. the options to set the TagWrench hook
will be set to a void hook. Here is an example of VIM script options the user 
can set to enable tagwrench with a void hook: >

	let g:pairtools_vim_tagwrench = 1
	let g:pairtools_vim_tagwrenchhook = 'TagWrench#BuiltinNoHook'
<
The TagWrench#BuiltinNoHook is a hook function defined inside the TagWrench
module that does nothing. It is useful when the user does not want to use any
of the provided hooks.

In Vim, when the user wants to map a key to do something special for the 
current buffer, he must use the "tag" <buffer>. Here is how it is constructed 
with the angle brackets:

	Type opening bracket:		<|
    Then type 'b':              <b|>

After the b appeared, the closing brackets is inserted. It will do so when the
first character is: a-z, A-Z, 0-9, _, ! and /. There are two other characters 
as well but we will talk about them later.

	Type the remaining letter:  <buffer|>
    Press >:                    <buffer>|

The cursor stepped out like it is doing in PairClamp. It is that simple. But
much more can be done when using TagWrench to write HTML tags for example.
There are a few thing to consider while typing and moving the cursor in insert
mode. This requires an explanation on how it internally works, the big 
picture.

When the user type < for the first time, it starts a tag context and will
listen for a tag event. The following character typed will determine if we 
stay in the tag context or if we leave it. The context will automatically 
close when pressing > to step out of the "tag". But what happens when ESC, UP, 
DOWN, LEFT, RIGHT keys are pressed? 

ESC, UP an DOWN automatically leave the context leaving the tag as is. This is 
very important when using a hook along this feature because if the cursor is 
moved back left of the > in insert move, the context does not exist anymore. 
It will not step out of the tag and it will not call the hook function for 
futher processing anymore. And it is also true for LEFT and RIGHT keys,
but under some condition the context will not be left by pressing them.

The LEFT and RIGHT key are somewhat special. They don't automatically close 
the context, unless pressing RIGHT moved the cursor pass the > or pressing 
LEFT moved the cursor pass the <. This is an example of how LEFT, RIGHT works 
inside a tag context:

	Starting with:              <buffer|>
    Move with LEFT key:			<buffe|r>

In that case the context is kept since the cursor is still inside the pair.

   Starting with:               <buffer|>
   Move with RIGHT key:         <buffer>|

There the context is lost, no hook is called and putting the cursor left of
the > will not allow step out/hook call. Is is also valid for the <.

For now, we will come back to the two special characters we have mentioned
before. These two are the % and ? used to embed another language code inside
an html document, such as PHP code.

	Type the opening <:		    <|
	Type ?:                     <?|?>

And the context immediatly ends.

*3.1* Hooks												*tagwrench-hooks*

The power of this module resides in the hook functions. When pressing the 
closing angle bracket to step out, the specified hook function is called for 
further processing. As we saw earlier a hook can be set as follow. The example
show how it can be set for an html filetype: >

	let g:pairtools_html_tagwrenchhook = 'TagWrench#BuiltinBasicTagHook'
<
Currently there are three builtin hooks:

TagWrench#BuiltinNoHook: 

This is the void hook, which does nothing and returns.

TagWrench#BuiltinBasicTagHook:

This is a basic tag builder that automatically add an ending tag when the 
starting tag does not end with />, i.e. it ends with a single >. Also, tags 
starting with a bang (!) or slash (/) never generate closing tags.

Here is an example using the <html> tag:

	We have:                   <html|>
    Pressing > produces:       <html>|</html>

	We have:                   <html /|>
	Pressing > produces:       <html />|

	We have:				   </html|>
	Pressing > produces:       </html>|

There is also another nice feature built inside the basic tag hook. It is a
kind of surrounding. For example, the user has the following line inside a
file, and wants to add tags around it:

	We have:                   Hello World
	We want:                   <h1>Hello World</h1>

This is quite simple, start adding the starting tag at the beginning of the
line, and an input will automatically show up in the command line when
pressing > because something is present right of the >:

	We type:                  <h1|>Hello World

The command line shows up, and a few things can be set:

	- $				At end of line
	- {count}l		{count} character(s) on the right
	- {count}w		{count} word(s) on the right (match end of words)
	- {count}W		{count} WORD(s) one the right (match end of WORDs)
	- t             Around tag name, second input shows up for tag name
	- /             Prevent closing tag
	- Nothing		That is, just pressing enter, right after starting tag

For simplicity, we will add the closing tags on the end of line:

	We have:                 <h1|>Hello World
	Pressing >, $, Enter:    <h1>|Hello World</h1>

Then, we want to add a span element to Hello:

	Adding span to Hello:    <h1><span|>Hello World</h1>
	Pressing >, w, Enter:    <h1><span>|Hello</span> World</h1>

* Note: current this feature only work inside a single line.

TagWrench#BuiltinHTML5Hook:

It calls the BuiltinBasicTagHook, passing it a list of tags to do not insert 
an ending tag. It follows all the rules from the basic tag hook plus it looks 
to prevent the closing tags for HTML5 void tags.

For example:

	We have:                   <img src="image.png"|>
	Pressing > produces:       <img src="image.png">|

	We have:                   <div id="main"|>
    Pressing > produces:	   <div id="main">|</div>

TagWrench Hook Public API							*tagwrench-hookapi*

It is possible for the user to make its own hook function and set it as the
current filetype TagWrench hook using the TagWrench Hook Public API.

Remember that while in a tag context, pressing > left of the tag ending > will
automatically call the specified hook for further processing. The user can use
the public function TagWrench#AddHook() to insert another hook. This function
needs an arguments: the full name of the hook function.

The hook function must take at least two arguments:

	1. Context Begin: this is the position of the opening < on the line.
    2. Context End: this is the position after the closing > on the line.

The hook function returns nothing. For examples, the user is refered to the
TagWrench Hook Public API fold in autoload/tagwrench.vim for few examples.

The BuiltinBasicTagHook is the corner stone of the BuiltinHTML5Hook and can be
used by the user. The BuiltinBasicTagHook take the two arguments specified
earlier plus an optional arguments to specify which tag names do no trigger
any closing tags. The tag names are specified in a commas separated string
list. Example: "img,link,meta".

*3.2* Eraser											*tagwrench-eraser*

The TagWrench eraser can delete either a single tag or a pair of starting and
ending tags, by pressing backspace. We will illustrate how it works with an
example:

	We have:                   <img src="blah.png">|
	Pressing backspace:        |

	We have:	               <div id="main">|</div>
    Pressing backspace:        |

	We have:                   <div id="main"></div>|
    Pressing backspace:        <div id="main">|
    Pressing backspace again:  |

*3.3* Expander											*tagwrench-expander*

The TagWrench expander expand a starting and ending tag and the special <%,%> 
and <?,?> much the same way the PairClamp expander expands brackets. The
simple <,> is not expanded on carriage return.

For example:

	We have:                   <|>
	Pressing <CR>:             <
                               |>

	We have:                   <div></div>
    Pressing <CR>:             <div>
                                   |
                               </div>

	We have:                   <?|?>
	Pressing <CR>:             <?
                                   |
		                       ?>


==============================================================================
*4.* Jigsaw												*pairtools-jigsaw*

The Jigsaw module is the central part to make then erasers and expanders of
both PairClamp and TagWrench work altogether. Here, we use hook functions to 
tell these when a given key is pressed, such as <BS> and <CR>.

Jigsaw current defines two functions:

	1. Jigsaw#Backspace: mapped to <BS>
	2. Jigsaw#CarriageReturn: mapped to <CR>

When one of these function is called by pressing a key, it will look execute
the hook functions until one has executed. Then, the return value associated
with this hook is returned.

When no hook is executed, the function return its default key, that is <BS>
for Backspace and <CR> for CarriageReturn.

It is possible to add more function using their public hook API:

	1. Jigsaw#AddBackspaceHook
	2. Jigsaw#AddCarriageReturnHook

These functions need two arguments:
	
	1. The hook function name
	2. The hook return value

Right now, the hook functions do not take any argument, but that could change
later on.

For the PairClamp and TagWrench modules, for example, the eraser functions are
hook for Jigsaw#Backspace.

==============================================================================
*5.* Installation										*pairtools-install*

There are a few ways to install the plugin:

1. Using `git clone` manually copy all files
2. Using `git clone` launch `vim pairtools.vba` followed by `:so %` and 
   `:quit`.
3. Download the vimball at www.vim.org/scripts/script.php?script_id=3560 and
   follow 2.

==============================================================================
*6.* Filetype Files Examples							*pairtools-examples*

See the ftplugin/ files included in the github repository:
	
	https://github.com/MartinLafreniere/vim-PairTools/tree/master/ftplugin


==============================================================================
*7.* Few Thoughts                                       *pairtools-thoughts*

- Using the repeat command '.' with |auto-close| doesn't work as expected by a 
  user. The closing character will not appear even though the user type the
  ending character to step out of the pair.

- When including the double quotes in the closepairs option, starting a
  comment in VIM language file will result in an auto-closed pair.

==============================================================================
*8.* License                                            *pairtools-license*

The PairTools plugin and this help file are licensed under the MIT license.

Copyright (C) 2011 by Martin Lafrenière

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

==============================================================================
*9.* Credits                                            *pairtools-credits*

The author of this plugin is Martin Lafrenière <pairtools@gmail.com>.

==============================================================================
*10.* Changes

Version 1.5
- Major rework of the plugin architure, now subdivided into modules. PairTools
  version 1.0 is now inside a module named PairClamp.
- Removed the surround feature.
- Add new TagWrench module to handle angle brackets and tags.
- Add new Jigsaw module to handle backspace and carriage return for both
  PairClamp and TagWrench.
- New help file

Version 1.0
- Initial version


 vim: set tw=78 noet ts=4 ft=help ff=unix:
ftplugin/cpp.vim	[[[1
31
" vim.vim - PairTools Configuration
" Maintainer: Martin Lafreniere <pairtools@gmail.com>
" Last Change: 2011 May 18
"
" This is my own configuration file for C++.
" It is free to use, modify and distribute. It is provided "AS IS" with no 
" warranty.

" Enable/Disable modules to use. For C++, I don't need the Tag Wrench
" module at all.
let g:pairtools_cpp_pairclamp = 1
let g:pairtools_cpp_tagwrench = 0
let g:pairtools_cpp_jigsaw    = 1

" Configure PairClamp
let g:pairtools_cpp_autoclose  = 1
let g:pairtools_cpp_forcepairs = 0
let g:pairtools_cpp_closepairs = "(:),[:],{:},':'"
let g:pairtools_cpp_smartclose = 1
let g:pairtools_cpp_smartcloserules = '\w,(,&,\*'
let g:pairtools_cpp_antimagic  = 1
let g:pairtools_cpp_antimagicfield  = "Comment,String,Special"
let g:pairtools_cpp_pcexpander = 1
let g:pairtools_cpp_pceraser   = 1

" Configure TagWrench
let g:pairtools_cpp_tagwrenchhook = 'TagWrench#BuiltinNoHook'
let g:pairtools_cpp_twexpander = 0
let g:pairtools_cpp_tweraser   = 0


ftplugin/help.vim	[[[1
30
" vim.vim - PairTools Configuration
" Maintainer: Martin Lafreniere <pairtools@gmail.com>
" Last Change: 2011 May 18
"
" This is my own configuration file for VIM Help files.
" It is free to use, modify and distribute. It is provided "AS IS" with no 
" warranty.

" Enable/Disable modules to use. For VIM help, all modules
" are useful
let g:pairtools_help_pairclamp = 1
let g:pairtools_help_tagwrench = 1
let g:pairtools_help_jigsaw    = 1

" Configure PairClamp
let g:pairtools_help_autoclose  = 1
let g:pairtools_help_forcepairs = 0
let g:pairtools_help_closepairs = "*:*,|:|,':'"
let g:pairtools_help_smartclose = 1
let g:pairtools_help_smartcloserules = '\w'
let g:pairtools_help_antimagic  = 0
let g:pairtools_help_antimagicfield  = ""
let g:pairtools_help_pcexpander = 0
let g:pairtools_help_pceraser   = 1

" Configure TagWrench for things such as <CR>, <buffer>
let g:pairtools_help_tagwrenchhook = 'TagWrench#BuiltinNoHook'
let g:pairtools_help_twexpander = 0
let g:pairtools_help_tweraser   = 1

ftplugin/html.vim	[[[1
30
" html.vim - PairTools Configuration
" Maintainer: Martin Lafreniere <pairtools@gmail.com>
" Last Change: 2011 May 18
"
" This is my own configuration file for HTML.
" It is free to use, modify and distribute. It is provided "AS IS" with no 
" warranty.

" Enable/Disable modules to use. For HTML, I like to
" use all modules but restricting few capabilities
let g:pairtools_html_pairclamp = 1
let g:pairtools_html_tagwrench = 1
let g:pairtools_html_jigsaw    = 1

" Configure PairClamp
let g:pairtools_html_autoclose  = 1
let g:pairtools_html_forcepairs = 0
let g:pairtools_html_closepairs = "':'" . ',":"'
let g:pairtools_html_smartclose = 1
let g:pairtools_html_smartcloserules = '\w'
let g:pairtools_html_antimagic  = 1
let g:pairtools_html_antimagicfield  = "Comment,String"
let g:pairtools_html_pcexpander = 0
let g:pairtools_html_pceraser   = 1

" Configure TagWrench
let g:pairtools_html_tagwrenchhook = 'TagWrench#BuiltinHTML5Hook'
let g:pairtools_html_twexpander = 1
let g:pairtools_html_tweraser   = 1

ftplugin/vim.vim	[[[1
30
" vim.vim - PairTools Configuration
" Maintainer: Martin Lafreniere <pairtools@gmail.com>
" Last Change: 2011 May 18
"
" This is my own configuration file for the VIM Language.
" It is free to use, modify and distribute. It is provided "AS IS" with no 
" warranty.

" Enable/Disable modules to use. For the VIM language, I like to
" use all modules but restricting few capabilities
let g:pairtools_vim_pairclamp = 1
let g:pairtools_vim_tagwrench = 1
let g:pairtools_vim_jigsaw    = 1

" Configure PairClamp
let g:pairtools_vim_autoclose  = 1
let g:pairtools_vim_forcepairs = 0
let g:pairtools_vim_closepairs = "(:),[:],{:},':'"
let g:pairtools_vim_smartclose = 1
let g:pairtools_vim_smartcloserules = '\w,('
let g:pairtools_vim_antimagic  = 1
let g:pairtools_vim_antimagicfield  = "Comment,String"
let g:pairtools_vim_pcexpander = 0
let g:pairtools_vim_pceraser   = 1

" Configure TagWrench
let g:pairtools_vim_tagwrenchhook = 'TagWrench#BuiltinNoHook'
let g:pairtools_vim_twexpander = 0
let g:pairtools_vim_tweraser   = 1

