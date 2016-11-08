%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 十一月 2016 19:50
%%%-------------------------------------------------------------------
-module(common).
-author("Administrator").

%% API
-export([core/0]).

%% 得到主机核数Cores
core() ->
  case get(schedulers) of
    undefined  ->
      Cores   = erlang:system_info(schedulers),
      put(schedulers,Cores),
      Cores;
    Cores       ->
      Cores
  end.
