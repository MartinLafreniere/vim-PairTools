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
let g:pairtools_vim_apostrophe = 0
let g:pairtools_vim_antimagic  = 1
let g:pairtools_vim_antimagicfield  = "Comment,String"
let g:pairtools_vim_pcexpander = 0
let g:pairtools_vim_pceraser   = 1

" Configure TagWrench
let g:pairtools_vim_tagwrenchhook = 'tagwrench#BuiltinNoHook'
let g:pairtools_vim_twexpander = 0
let g:pairtools_vim_tweraser   = 1

