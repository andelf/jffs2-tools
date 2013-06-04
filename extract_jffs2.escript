#!/usr/bin/env escript
%% -*- mode: Erlang; -*-

main([FileName]) ->
    {ok, Raw} = file:read_file(FileName),
    jffs2_header(Raw).



jffs2_header(<<16#19, 16#85, _/binary>> = Raw) ->
    jffs2_header_big_endian(Raw);
jffs2_header(<<16#85, 16#19, _/binary>> = Raw) ->
    jffs2_header_little_endian(Raw).




jffs2_header_big_endian(<<16#19, 16#85, NodeType:16/big-unsigned-integer, _/binary>>) ->
    io:format("0x~.16B~n", [NodeType]).


jffs2_header_little_endian(_) ->
    ok.
