#!/usr/bin/env lua

pcall(function ()
    require 'luarocks.loader'
end)

if 0 ~= select(-1, arg[0]:gsub('^(.*/).*$', '')) then
    package.path = package.path .. arg[0]:gsub('^(.*/).*$', ';%1?.lua')
end

require('dna.core')()
