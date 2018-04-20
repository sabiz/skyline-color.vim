" =============================================================================
" Filename: autoload/SkylineColor.vim
" Author: sabiz
" License: MIT License
" =============================================================================

scriptencoding utf-8
if !exists('g:loaded_skyline_color')
    finish
endif
let g:loaded_skyline_color = 1

let s:save_cpo = &cpo
set cpo&vim

let s:PI = 3.14159265359
let s:SunsetTimeCache = {}

function! s:r2d(r)
    return a:r * 180.0 / s:PI
endfunction

function! s:d2r(d)
    return a:d * s:PI / 180.0
endfunction

function! s:getSunAngle(dayOfYear) abort
    return -23.44 * cos(s:d2r(360.0 / 365.0 * (a:dayOfYear + 10)))
endfunction

function! s:getSunsetAngle(dayOfYear, lat) abort
    return s:r2d(acos(-1 * tan(s:d2r(a:lat) * tan(s:d2r(s:getSunAngle(a:dayOfYear))))))
endfunction

function! s:getSunsetTime(dayOfYear, lat) abort
    return 24.0 * (s:getSunsetAngle(a:dayOfYear, a:lat) / 360.0)
endfunction


function! SkylineColor#display() abort
    let dayOfYear = strftime('%j')
    if empty(s:SunsetTimeCache) || s:SunsetTimeCache['dayOfYear'] != dayOfYear
        let s:SunsetTimeCache = { 'timeCache': s:getSunsetTime(str2nr(dayOfYear), g:SkylineColor_Latitude), 'dayOfYear': dayOfYear }
    endif
    hi SkylineColor term=bold cterm=bold ctermfg=22 ctermbg=148 gui=bold guifg=#005f00 guibg=#afdf00
    return strftime(g:SkylineColor_TimeFormat)
endfunction



function! s:setGlobalValueIfNotExist(var, value)
    if !exists(a:var)
        let fmt = 'let %s = "%s"'
        if type(a:value) == 5 " Float
            let fmt = 'let %s = %f'
        endif
        exec printf(fmt, a:var, a:value)
        return
    endif
endfunction

function! SkylineColor#load()
" let g:SkylineColor_TimeFormat="%j"
" Setup configurations ----------
call s:setGlobalValueIfNotExist('g:SkylineColor_TimeFormat', '%H:%M')
call s:setGlobalValueIfNotExist('g:SkylineColor_Latitude', 35.4052) " Tokyo station of japan


endfunction









let &cpo = s:save_cpo
unlet s:save_cpo
