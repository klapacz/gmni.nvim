# gmni.nvim

```lua
use {
	"https://git.sr.ht/~kornellapacz/gmni.nvim",
	rocks = { "luasocket" },
	requires = { 'nvim-lua/plenary.nvim' },
	config = function ()
		require('gmni').setup {
			keymaps = {
				-- default mappings
				next_link = "<tab>",
				prev_link = "<s-tab>",
				enter_link = "<cr>",
			},
		}
	end,
}
```

