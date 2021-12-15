function! Gmni()
	lua for k in pairs(package.loaded) do if k:match("^gmni") then package.loaded[k] = nil end end
	lua require("gmni").get("gemini://gemini.circumlunar.space/")
endfun

augroup Gmni
	autocmd!
augroup END
