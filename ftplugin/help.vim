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
let g:pairtools_help_apostrophe = 1
let g:pairtools_help_antimagic  = 0
let g:pairtools_help_antimagicfield  = ""
let g:pairtools_help_pcexpander = 0
let g:pairtools_help_pceraser   = 1

" Configure TagWrench for things such as <CR>, <buffer>
let g:pairtools_help_tagwrenchhook = 'tagwrench#BuiltinNoHook'
let g:pairtools_help_twexpander = 0
let g:pairtools_help_tweraser   = 1

