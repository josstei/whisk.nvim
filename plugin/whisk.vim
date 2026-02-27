if exists('g:loaded_whisk')
  finish
endif
let g:loaded_whisk = 1

command! WhiskEnable lua require('whisk').enable()
command! WhiskDisable lua require('whisk').disable()
command! WhiskToggle lua require('whisk').toggle()

command! WhiskEnableCursor lua require('whisk').enable_cursor()
command! WhiskDisableCursor lua require('whisk').disable_cursor()
command! WhiskEnableScroll lua require('whisk').enable_scroll()
command! WhiskDisableScroll lua require('whisk').disable_scroll()

command! WhiskPerformanceEnable lua require('whisk.performance').enable()
command! WhiskPerformanceDisable lua require('whisk.performance').disable()
command! WhiskPerformanceToggle lua require('whisk').toggle_performance()

if !exists('g:whisk_auto_setup')
  let g:whisk_auto_setup = 1
endif

if g:whisk_auto_setup
  lua require('whisk').setup()
endif
