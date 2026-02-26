if exists('g:luxmotion_auto_setup')
  if !exists('g:whisk_auto_setup')
    let g:whisk_auto_setup = g:luxmotion_auto_setup
  endif
endif

command! LuxMotionEnable WhiskEnable
command! LuxMotionDisable WhiskDisable
command! LuxMotionToggle WhiskToggle
command! LuxMotionEnableCursor WhiskEnableCursor
command! LuxMotionDisableCursor WhiskDisableCursor
command! LuxMotionEnableScroll WhiskEnableScroll
command! LuxMotionDisableScroll WhiskDisableScroll
command! LuxMotionPerformanceEnable WhiskPerformanceEnable
command! LuxMotionPerformanceDisable WhiskPerformanceDisable
command! LuxMotionPerformanceToggle WhiskPerformanceToggle
