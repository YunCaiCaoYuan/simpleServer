%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Ê®Ò»ÔÂ 2016 18:04
%%%-------------------------------------------------------------------
-module(server).
-author("Administrator").

-define(SERVER_APPS, [server, sasl]).

%% API
-export([start/0, stop/0]).

start() ->
  try
      application:start(sasl, permanent),
      application:start(server, permanent)
  catch
      _E : _T  ->
        ok
      after
        timer:sleep(100)
  end.

%%stop game server
stop() ->
  stop_applications(?SERVER_APPS),
  timer:sleep(1000), %% ms
  erlang:halt(0, [{flush, false}]).

%%
%% Local Functions
%%
stop_applications(Apps) ->
  MyFunc = fun( App )->
    case application:stop(App) of
      ok -> ok;
      Msg -> io:format( "stop_application ~p fail,reason: ~p ~n", [App,Msg])
    end
  end,

  try
    lists:foreach(MyFunc, Apps)
  catch
    Type:Error -> io:format( "Error Type:~p,Reason:~p", [Type,Error])
  end.