local aliases = {
  Tree = "NvimTreeToggle"
}

for k, v in pairs(aliases) do
  vim.cmd('command ' .. k .. ' ' .. v)
end
