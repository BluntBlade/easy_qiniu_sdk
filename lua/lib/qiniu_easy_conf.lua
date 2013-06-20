#!/usr/bin/env lua

--[[
Easy Qiniu Lua SDK

Module: qiniu_easy_conf.lua

Author: LIANG Tao
Weibo:  @无锋之刃
Email:  amethyst.black@gmail.com
        liangtao@qiniu.com
--]]

qiniu_easy_conf = {
    -- Qiniu hosts' domain names may be changed in the future.
    UP_HOST = 'http://up.qbox.me',
    RS_HOST = 'http://rs.qbox.me',

    -- Don't initialize the following constants on client sides.
    ACCESS_KEY = '<Put your ACCESS KEY here>',
    SECRET_KEY = '<Put your SECRET KEY here>'
} -- qiniu_easy_conf
