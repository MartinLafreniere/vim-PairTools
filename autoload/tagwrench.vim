" TagWrench.vim - PairTools module handling angle brackets pair and XML/HTML tags
" Last Changed: 2011 May 25
" Maintainer:   Martin Lafreniere <pairtools@gmail.com>
"
" Copyright (C) 2011 by Martin Lafrenière
" 
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, todify, merge, publish, distribute, sublicense, and/or sell
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

function! tagwrench#StartContext(Value)

    " Make sure no context was previously started to fire a Tag Event
    if !exists('b:TWContext') || !b:TWContext
        let b:TWTagEvent = 1
    endif
    let b:TWContext  = 1

    return a:Value

endfunction


function! tagwrench#StopContext(...)

    let value = (a:0 > 0 ? a:000[0] : '')

    let line   = getline('.')
    let cursor = col('.') - 1

    if exists('b:TWContext') && b:TWContext
        
        " Make sure the > wasn't pressed inside an attribute field
        if s:IsAttributeContext() && value == '>'
            return value
        endif

        " Pressed either '>' or 'Esc' left of '>'
        if line[cursor] == '>' && value == '>'
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


function! tagwrench#StopContextIf(Direction, Value)

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


function! tagwrench#EnterTagEvent()

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


function! tagwrench#IsTagEvent()

    if !exists('b:TWTagEvent')
        let b:TWContext  = 0
        let b:TWTagEvent = 0
    endif

    return b:TWTagEvent
        
endfunction

" }}}1

" Angle Brackets Erase {{{1

function! tagwrench#Erase()

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
    let closingName = matchstr(line[(column + 2):], '^[[:alnum:]_:-]\+')
    
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
    while (skip || line[(start):] !~ '^<[!/]\?\w') && start > -1
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

function! tagwrench#Expand()

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
    call tagwrench#AddHook('tagwrench#BuiltinNoHook')
    call tagwrench#AddHook('tagwrench#BuiltinBasicTagHook')
    call tagwrench#AddHook('tagwrench#BuiltinHTML5Hook')

    if index(g:PTTagWrenchHookTable, b:PTTagWrenchHook) > -1
        exe 'call ' . b:PTTagWrenchHook . '(' .a:ContextBegin . ',' . a:ContextEnd . ')'
    endif
     
endfunction


" Public function provided to the user to add custom hooks
"   A Hook is passed two arguments
"   1. Context Begin: this is the position of the < character
"   2. Context End:   this is the position after the > character
"   See BuiltinBasicTagHook for an example.
function! tagwrench#AddHook(HookFullName)

    if !exists('g:PTTagWrenchHookTable')
        let g:PTTagWrenchHookTable = []
    endif

    if index(g:PTTagWrenchHookTable, a:HookFullName) == -1
        call add(g:PTTagWrenchHookTable, a:HookFullName)
    endif

endfunction


function! tagwrench#BuiltinNoHook(ContextBegin, ContextEnd)
    " Do nothing
    return
endfunction


" Simple tag handling: complement starting <tag> with ending </tag>
" Arguments: Receives the context begin (tag <) and context end (tag >)
function! tagwrench#BuiltinBasicTagHook(ContextBegin, ContextEnd, ...)

    let line = getline('.')
    
    let startTag = line[(a:ContextBegin):(a:ContextEnd-1)]
    let tagName  = matchstr(startTag, '^<\zs!\?[[:alnum:]_:-]\+')
    
    let voids = (a:0 > 0 ? a:000[0] : '')
    if index(split(voids, ','), tolower(tagName)) == -1 && startTag !~ '/>$' && startTag !~ '^<[!/]'

        let closingPos = s:SurroundClosingTag(a:ContextEnd)
        if closingPos > 0
            call setline('.', line[:(closingPos-1)] . '</' . tagName . '>' . line[(closingPos):])
        endif

    endif

endfunction


function! tagwrench#BuiltinHTML5Hook(ContextBegin, ContextEnd)

    " Define HTML5 void elements
    let voids = "area,base,br,col,command,embed,hr,img,input,keygen,link,meta,param,source,track,wbr"

    call tagwrench#BuiltinBasicTagHook(a:ContextBegin, a:ContextEnd, voids)

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
