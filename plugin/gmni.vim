function! Gmni()
	lua for k in pairs(package.loaded) do if k:match("^gmni") then package.loaded[k] = nil end end

	tabnew gemini://gemini.circumlunar.space/
endfun

command! Gmni call Gmni()

augroup Gmni
	au!
	autocmd BufReadCmd gemini://* lua (R or require)("gmni").edit(vim.fn.expand("<amatch>"))
	autocmd BufWritePost gmni.vim source %
augroup END
