vim.notify(
  "[luxmotion] nvim-luxmotion has been renamed to whisk.nvim. "
    .. 'Update your config to require("whisk"). '
    .. "This shim will be removed in a future release.",
  vim.log.levels.WARN
)

return require("whisk")
