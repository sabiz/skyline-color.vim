" =============================================================================
" Filename: plugin/SkylineColor.vim
" Author: sabiz
" License: MIT License
" =============================================================================
scriptencoding utf-8

if exists('g:loaded_skyline_color')
    finish
endif

let g:loaded_skyline_color = 1

let s:save_cpo = &cpo
set cpo&vim

call SkylineColor#load()

let &cpo = s:save_cpo
unlet s:save_cpo
