%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Ê®Ò»ÔÂ 2016 15:12
%%%-------------------------------------------------------------------
-module(myshare).
-author("Administrator").

-include("myshare.hrl").

%% API
-export([init_env/1, get_env/1]).

%% read server config file and init ets
init_env(ConfigFilePath) ->
  ets:new(?ETS_CACHE_SERVER_ENV, [set, public, named_table, {read_concurrency, true}]),

  {ok, [ConfigList]} = file:consult(ConfigFilePath),

  Fun = fun({Key, Val}) ->
    ets:insert(?ETS_CACHE_SERVER_ENV, {Key, Val})
  end,
  lists:foreach(Fun, ConfigList).

%% get env value by key
get_env(Key) ->
  try
    ets:lookup_element(?ETS_CACHE_SERVER_ENV, Key, 2)
  catch
    error:badarg -> undefined
  end.
