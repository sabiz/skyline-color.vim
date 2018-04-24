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

function! s:getColorStopsFromTime(timeFrom, timeTo) abort
    return [
        \ [a:timeFrom - 2.0, '#111111'],
        \ [a:timeFrom - 1.5, '#4d548a'],
        \ [a:timeFrom - 1.0, '#c486b1'],
        \ [a:timeFrom - 0.5, '#ee88a0'],
        \ [a:timeFrom, '#ff7d75'],
        \ [a:timeFrom + 0.5, '#f4eeef'],
        \ [(a:timeTo + a:timeFrom) / 2, '#5dc9f1'],
        \ [a:timeTo - 1.5, '#9eefe0'],
        \ [a:timeTo - 1.0, '#f1e17c'],
        \ [a:timeTo - 0.5, '#f86b10'],
        \ [a:timeTo, '#100028'],
        \ [a:timeTo + 0.5, '#111111'],
    \ ]
endfunction

function! s:hexColor2DecColor(rgb) abort
    let dRgb = str2nr(strpart(a:rgb, 1), 16)
    return [
    \   and(dRgb, 0xFF0000) / 0x00FFFF,
    \   and(dRgb, 0x00FF00) / 0x0000FF,
    \   and(dRgb, 0x0000FF)
    \   ]
endfunction

function! s:decColor2HexColor(r, g, b) abort
    return printf('#%02x%02x%02x', a:r, a:g, a:b)
endfunction

function! s:getGradient(a, b, x) abort
    let [aR, aG, aB] = s:hexColor2DecColor(a:a)
    let [bR, bG, bB] = s:hexColor2DecColor(a:b)

    let gR = float2nr(ceil((bR - aR) * a:x + aR))
    let gG = float2nr(ceil((bG - aG) * a:x + aG))
    let gB = float2nr(ceil((bB - aB) * a:x + aB))

    return s:decColor2HexColor(gR, gG, gB)
endfunction

function! s:getColorFromTime(colorStops, time) abort
    if a:time <= a:colorStops[0][0]
        return a:colorStops[0][1]
    endif

    if a:time >= a:colorStops[len(a:colorStops) -1][0]
        return a:colorStops[len(a:colorStops) -1][1]
    endif

    let i = 0
    let pickedIndex = 0
    while i < len(a:colorStops)
        if a:time >= a:colorStops[i][0]
            let pickedIndex = i
        endif
        let i +=1
    endwhile
    let x = (a:time - a:colorStops[pickedIndex][0]) / (a:colorStops[pickedIndex +1][0] - a:colorStops[pickedIndex][0])
    return s:getGradient(a:colorStops[pickedIndex][1], a:colorStops[pickedIndex +1][1], x)
endfunction

function! s:getTimeFloatFromHMS(time) abort
    let [h, m, s] = split(a:time, ':')
    return ((s / 60.0) +
            \ m) / 60.0 + h " Not work syntax highlight...
endfunction

function! s:rgb2Ansi(rgb) abort
    let [r, g, b] = s:hexColor2DecColor(a:rgb)

    " https://github.com/Qix-/color-convert/blob/1df58eff59b30d075513860cf69f8aec4620140d/conversions.js#L567
    " Gray scale color
    if r == g && g == b
        if r < 8
            return 16
        endif

        if r > 248
            return 231
        endif

        return round(((r - 8) / 247.0) * 24) + 232
    endif

    let ansi = round(16
    \   + (36 * round(r / 255.0 * 5))
    \   + (6 * round(g / 255.0 * 5))
    \   + round(b / 255.0 * 5))
    return ansi
endfunction

function! s:rgb2Hsv(rgb) abort
    let [r, g, b] = s:hexColor2DecColor(a:rgb)
    let max = max([r, g, b])
    let min = min([r, g, b])
    let gap = (max - min) * 1.0
    let h = 0.0
    let s = gap / max * 255
    let v = max * 1.0
    if max == min
        let h = 0.0
    elseif max == r
        let h = 60 * ((g - b) / gap)
    elseif max == g
        let h = 60 * ((b - r) / gap) + 120
    elseif max == b
        let h = 60 * ((r - g) / gap) + 240
    endif
    if h < 0
        let h += 360
    endif

    return [float2nr(round(h)), float2nr(round(s)), float2nr(v)]
endfunction

function! s:hsv2Rgb(h, s, v) abort
    let max = a:v
    let min = max - ((a:s / 255.0) * max)
    let r = 0
    let g = 0
    let b = 0
    if a:h <= 60
        let r =  max
        let g = (a:h / 60.0) * (max - min) + min
        let b = min
    elseif a:h <= 120
        let r = ((120 - a:h) / 60.0) * (max - min) + min
        let g = max
        let b = min
    elseif a:h <= 180
        let r = min
        let g = max
        let b = ((a:h - 120) / 60.0) * (max - min) + min
    elseif a:h <= 240
        let r =  min
        let g = ((240 - a:h) / 60.0) * (max - min) + min
        let b =  max
    elseif a:h <= 300
        let r = ((a:h - 240) / 60.0) * (max - min) + min
        let g = min
        let b = max
    else
        let r = max
        let g = min
        let b = ((360 - a:h) / 60.0) * (max - min) + min
    endif
    return s:decColor2HexColor(float2nr(round(r)), float2nr(round(g)), float2nr(round(b)))
endfunction

function! s:getComplementaryColor(rgb) abort
    let [h, s, v] = s:rgb2Hsv(a:rgb)
    let v = abs(255 - v)
    if abs(127 - v) < 48
        let v = 255
    endif
    return s:hsv2Rgb(h, s, v)
endfunction

function! SkylineColor#display() abort
    let dayOfYear = strftime('%j')
    if empty(s:SunsetTimeCache) || s:SunsetTimeCache['dayOfYear'] != dayOfYear
        let sunsetTime = s:getSunsetTime(str2nr(dayOfYear), g:SkylineColor_Latitude)
        let sunrise = 12 - sunsetTime
        let sunset = 12 + sunsetTime
        let colorStops = s:getColorStopsFromTime(sunrise, sunset)
        let s:SunsetTimeCache = {
        \   'timeCache': sunsetTime,
        \   'dayOfYear': dayOfYear,
        \   'sunrise': sunrise,
        \   'sunset': sunset,
        \   'colorStops': colorStops
        \ }
    endif
    let BgRgb = s:getColorFromTime(s:SunsetTimeCache['colorStops'], s:getTimeFloatFromHMS(strftime('%H:%M:%S')))
    let BgAnsi = s:rgb2Ansi(BgRgb)
    let FgRgb = s:getComplementaryColor(BgRgb)
    let FgAnsi = s:rgb2Ansi(FgRgb)
    exec printf('hi SkylineColor ctermfg=%s ctermbg=%s guifg=%s guibg=%s', FgAnsi, BgAnsi, FgRgb, BgRgb)
    return strftime(g:SkylineColor_TimeFormat)
endfunction


function! SkylineColor#load()
" let g:SkylineColor_TimeFormat="%j"
" Setup configurations ----------
let g:SkylineColor_TimeFormat = get(g:, 'SkylineColor_TimeFormat', '%H:%M')
let g:SkylineColor_Latitude = get(g:, 'SkylineColor_Latitude', 35.4052) " Tokyo station of japan

endfunction

function! SkylineColor#preview()
    let midnight = 60 * 60 * 15 " from a.m. 9:00
    let i = midnight
    let line = ''
    while i < (60 * 60 * 24) + midnight
        let txt = strftime('%H:%M:%S',i)
        let gn = printf('SkylineColor_test_%d', i)
        let BgRgb = s:getColorFromTime(s:SunsetTimeCache['colorStops'], s:getTimeFloatFromHMS(txt))
        let BgAnsi = s:rgb2Ansi(BgRgb)
        let FgRgb = s:getComplementaryColor(BgRgb)
        let FgAnsi = s:rgb2Ansi(FgRgb)
        exec printf('hi %s ctermfg=%s ctermbg=%s guifg=%s guibg=%s',gn , FgAnsi, BgAnsi, FgRgb, BgRgb)
        exec printf('syntax keyword %s %s', gn, escape(txt, ' '))
        exec printf('syntax match %s /%s/', gn, escape(txt, ' '))
        let line = line.txt
        if i % 600 == 0
            call append(line('$'), line)
            let line = ''
        else
            let line = line.'|'
        endif
        let i += 60
    endwhile
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
