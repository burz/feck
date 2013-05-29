if exists("b:current_syntax")
  finish
endif

syn keyword feckControlFlow if elif else end while
syn keyword feckKernelFunc print puts
syn keyword feckValue true false nil
syn keyword feckOp or and not is

syn match feckInt /[0-9]*/
syn match feckFloat /[0-9][0-9]*[.][0-9][0-9]*/
syn match feckGlobalVar /[$][A-Za-z][A-Za-z0-9_]*/
syn match feckString /["]([^"] | [\\]["])*["]/
syn match feckComment /[#].*/

hi def link feckControlFlow Keyword
hi def link feckKernelFunc Function
hi def link feckValue Special
hi def link feckInt Number
hi def link feckFloat Number
hi def link feckString Number
hi def link feckGlobalVar NonText
hi def link feckComment Comment
hi def link feckOp Keyword

