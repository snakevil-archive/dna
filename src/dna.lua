#!/usr/bin/env lua

pcall(function ()
    require 'luarocks.loader'
end)

package.path = package.path .. string.gsub(arg[0], '(.*/).*', ';%1?.lua')

require('dna.core')()
