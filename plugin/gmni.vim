function! Gmni()
	lua for k in pairs(package.loaded) do if k:match("^gmni") then package.loaded[k] = nil end end

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
	autocmd BufReadCmd gemini://* lua (R or require)("gmni").load(vim.fn.expand("<amatch>"))
	autocmd BufWritePost gmni.vim source %
augroup END
