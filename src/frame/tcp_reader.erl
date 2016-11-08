%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Ê®Ò»ÔÂ 2016 17:36
%%%-------------------------------------------------------------------
-module(tcp_reader).
-author("Administrator").

%% API
-export([start_link/1, init/1]).


start_link(CoreIndex) ->
  {ok, proc_lib:spawn_opt(?MODULE, init, [CoreIndex], [link, {scheduler, CoreIndex}])}.

%% todo
init(CoreIndex) ->
  process_flag(trap_exit, true),

  receive
    {go, Socket} ->
      ok;
    {reconnected, Socket, PlayerPid, PlayerID, UserID} ->
      ok;
    Other ->
      ok
  end.