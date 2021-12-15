function! Gmni()
	lua for k in pairs(package.loaded) do if k:match("^gmni") then package.loaded[k] = nil end end
	" lua require("gmni").get("gemini://gemini.circumlunar.space/")
	
	tabnew gemini://asdf
endfun

augroup Gmni
	au!
	autocmd BufReadCmd gemini://* lua (R or require)("gmni").edit(vim.fn.expand("<amatch>"))
augroup END
