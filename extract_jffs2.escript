#!/usr/bin/env escript
%% -*- mode: Erlang; -*-


-define(COMPR_NONE        ,16#00).
-define(COMPR_ZERO        ,16#01).
-define(COMPR_RTIME       ,16#02).
-define(COMPR_RUBINMIPS   ,16#03).
-define(COMPR_COPY        ,16#04).
-define(COMPR_DYNRUBIN    ,16#05).
-define(COMPR_ZLIB        ,16#06).
-define(COMPR_LZO         ,16#07).

-define(DEBUG(MSG), io:format("debug: ~p~n", [MSG])).

main([FileName]) ->
    {ok, Raw} = file:read_file(FileName),
    jffs2_header(Raw).



jffs2_header(<<16#19, 16#85, _/binary>> = Raw) ->
    jffs2_header_big_endian(Raw);
jffs2_header(<<16#85, 16#19, _/binary>> = Raw) ->
    jffs2_header_little_endian(Raw).



%% unkown node
jffs2_header_big_endian(<<16#19, 16#85, 16#2003:16/big-unsigned-integer,
                          NodeLength:32/big-unsigned-integer,
                          CRC:32/big-unsigned-integer,
                          Rest/binary>>) ->
    ?DEBUG(cleanmarker),
    jffs2_header_big_endian(Rest);
%% DIRENT
jffs2_header_big_endian(<<16#19, 16#85, 16#E001:16/big-unsigned-integer,
                          NodeLength:32/big-unsigned-integer,
                          HdrCRC:32/big-unsigned-integer,
                          PINo:32/big-unsigned-integer,
                          Version:32/big-unsigned-integer,
                          INo:32/big-unsigned-integer,
                          Mctime:32/big-unsigned-integer,
                          NSize:8/big-unsigned-integer,
                          Type:8/big-unsigned-integer,
                          _:16,
                          NodeCRC:32/big-unsigned-integer,
                          NameCRC:32/big-unsigned-integer,
                          Name:NSize/binary,
                          NameRest/binary>>) ->
    Rest = case NSize rem 4 of
               0 ->
                   NameRest;
               NeedPad ->
                   Padding = 4 - NeedPad,
                   binary_part(NameRest, {Padding, byte_size(NameRest) - Padding})
           end,
    ?DEBUG(dirent),
    io:format("dirent type: 0x~.16B~n", [Type]),
    io:format("name: ~p inode:~p pino: ~p~n", [Name, INo, PINo]),

    jffs2_header_big_endian(Rest);
%% inode
jffs2_header_big_endian(<<16#19, 16#85, 16#E002:16/big-unsigned-integer,
                          NodeLength:32/big-unsigned-integer,
                          HdrCRC:32/big-unsigned-integer,
                          INo:32/big-unsigned-integer,
                          Version:32/big-unsigned-integer,
                          Mode:32/big-unsigned-integer,
                          Uid:16/big-unsigned-integer,
                          Gid:16/big-unsigned-integer,
                          ISize:32/big-unsigned-integer,
                          ATime:32/big-unsigned-integer,
                          MTime:32/big-unsigned-integer,
                          CTime:32/big-unsigned-integer,
                          Offset:32/big-unsigned-integer,
                          CSize:32/big-unsigned-integer, % (Compressed) data size
                          DSize:32/big-unsigned-integer, % Size of the node's data. (after decompression)
                          Compr:8, UserCompr:8,
                          Flags:16/big-unsigned-integer,
                          DataCRC:32/big-unsigned-integer,
                          NodeCRC:32/big-unsigned-integer,
                          Data:CSize/binary,
                          DataRest/binary>>) ->
    Rest = case CSize rem 4 of
               0 ->
                   DataRest;
               NeedPad ->
                   Padding = 4 - NeedPad,
                   binary_part(DataRest, {Padding, byte_size(DataRest) - Padding})
           end,
    ?DEBUG(inode),
    io:format("inode: ~p mode: ~.8B size: ~p~n", [INo, Mode, CSize]),
    io:format("decompressed size: ~p~n", [DSize]),
    io:format("compress method: ~p user compress method: ~p uid/gid: ~p/~p~n", [Compr, UserCompr, Uid, Gid]),
    io:format("data----> ~p~n", [Data]),
    jffs2_header_big_endian(Rest);

%% XREF
jffs2_header_big_endian(<<16#19, 16#85, 16#E009:16/big-unsigned-integer,
                          NodeLength:32/big-unsigned-integer,
                          HdrCRC:32/big-unsigned-integer,
                          INo:32/big-unsigned-integer,
                          XId:32/big-unsigned-integer,
                          XSeqNo:32/big-unsigned-integer,
                          NodeCRC:32/big-unsigned-integer,
                          Rest/binary>>) ->
    ?DEBUG("++++++++++++++++++++++++++++++++++++++++"),
    ?DEBUG(xref),
    io:format("CRC: ~.16B~n", [HdrCRC]),
    io:format("inode: ~p~n", [INo]),
    jffs2_header_big_endian(Rest);
jffs2_header_big_endian(<<16#19, 16#85, NodeType:16/big-unsigned-integer,
                          NodeLength:32/big-unsigned-integer,
                          HdrCRC:32/big-unsigned-integer,
                          Data:NodeLength/binary,
                          _/binary>>) ->
    ?DEBUG("----------------------------------------"),
    io:format("UNKOWN TYPE: 0x~.16B~n", [NodeType]),
    io:format("length: ~.10B~n", [NodeLength]),
    io:format("CRC: ~.16B~n", [HdrCRC]),
    io:format("data ~p~n", [Data]).



jffs2_header_little_endian(_) ->
    ok.


%% ------------------------------------------------------------
