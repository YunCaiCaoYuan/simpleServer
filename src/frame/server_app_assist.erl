%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Ê®Ò»ÔÂ 2016 15:17
%%%-------------------------------------------------------------------
-module(server_app_assist).
-author("Administrator").

%% API
-export([start/0]).


start() ->
  %% tcp_reader_sup
  case start_tcp_reader_sup() of
    {error, ReasonForReaderSup}->
      throw({tcp_reader_sup,ReasonForReaderSup});
    _->ok
  end,

  %% tcp_listener_sup
  case start_tcp_listener_sup() of
    {error, ReasonForListenerSup}->
      throw({tcp_listener_sup,ReasonForListenerSup});
    _->ok
  end,
  ok.

%% Æô¶¯tcp_reader¼à¿ØÊ÷
start_tcp_reader_sup() ->
  supervisor:start_child(
    sup,
    {tcp_reader_sup,
      {tcp_reader_sup, start_link, []},
      transient,
      infinity,
      supervisor,
      [tcp_reader_sup]}
  ).

%% Æô¶¯tcp_listener¼à¿ØÊ÷
start_tcp_listener_sup() ->
  supervisor:start_child(
    sup,
    {tcp_listener_sup,
      {tcp_listener_sup, start_link, []},
      transient,
      infinity,
      supervisor,
      [tcp_listener_sup]}
  ).