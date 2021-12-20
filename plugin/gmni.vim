function! Gmni()
	lua require('plenary.reload').reload_module("gmni")
	tabnew gemini://gemini.circumlunar.space/
endfun

function! GmniNextLink()
	/^=>
	norm 0w
endfun

function! GmniPrevLink()
	?^=>
	norm 0w
endfun

command! Gmni call Gmni()

augroup Gmni
	au!
	autocmd BufReadCmd gemini://* lua (R or require)("gmni").request(vim.fn.expand("<amatch>"))
	autocmd BufWritePost gmni.vim source %
augroup END
