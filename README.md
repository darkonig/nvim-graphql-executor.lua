Requires `norcalli/nvim-terminal.lua` if `use_colors` is set to `true`(default = `true`).

lvim.plugins:
```
{
  'norcalli/nvim-terminal.lua',
  config = function()
    require('terminal').setup()
  end
}
```
