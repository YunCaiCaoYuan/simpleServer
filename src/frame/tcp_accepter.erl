%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Ê®Ò»ÔÂ 2016 19:40
%%%-------------------------------------------------------------------
-module(tcp_accepter).
-author("Administrator").

-behaviour(gen_server).

%% API
-export([start_link/0, start_link/1]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {sock, ref, index=0}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

start_link(Socket) ->
  gen_server:start_link(?MODULE, [Socket], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([Socket]) ->
  process_flag(trap_exit, true),

  gen_server:cast(self(), accept),

  {ok, #state{sock = Socket}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
  {reply, Reply :: term(), NewState :: #state{}} |
  {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).


handle_info({inet_async, LSock, Ref, {ok, Sock}}, State = #state{sock=LSock, ref=Ref,index=Index}) ->
  case set_sockopt(LSock, Sock) of
    ok -> ok;
    {error, Reason} ->
      exit({set_sockopt, Reason})
  end,
  start_tcp_reader(Sock,Index),
  NewState = State#state{index=Index+1},
  accept(NewState);

handle_info({inet_async, LSock, Ref, {error, closed}}, State=#state{sock=LSock, ref=Ref}) ->
  {stop, normal, State};

handle_info({inet_async, _LSock, _Ref, {error,system_limit}}, State) ->
  timer:send_after(10*1000, tcp_listener, {tcp_accept_terminate}),
  {noreply, State};

handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
  {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% This function is taken from prim_inet
set_sockopt(LSock, Sock) ->
  true = inet_db:register_socket(Sock, inet_tcp),
  case prim_inet:getopts(LSock, [active, nodelay, keepalive, delay_send, exit_on_close, priority, tos]) of
    {ok, Opts1} ->
      Opts = [{send_timeout, 10000}|Opts1],
      case prim_inet:setopts(Sock, Opts) of
        ok -> ok;
        Error ->
          gen_tcp:close(Sock),
          Error
      end;
    Error ->
      gen_tcp:close(Sock),
      Error
  end.

start_tcp_reader(Sock,Index) ->
  %% tcp_reader_sup
  Cores   = common:core(),
  CoreIndex = (Index rem Cores) + 1,
  {ok, Reader} = supervisor:start_child(tcp_reader_sup, [CoreIndex]),
  case inet:peername(Sock) of
    {ok, {IP, Port}} -> io:format(start_tcp_reader, "client address:~p, port:~p", [IP, Port]);
    _ -> ignore
  end,
  ok = gen_tcp:controlling_process(Sock, Reader),
  Reader ! {go, Sock}.

%%receive gen_tcp:connect asynchronously
%%{inet_async, ListSock, Ref, {ok, CliSocket}} handle_info
accept(State = #state{sock = Socket}) ->
  case prim_inet:async_accept(Socket, -1) of
    {ok, Ref} -> {noreply, State#state{ref = Ref}};
    Error     -> {stop, {cannot_accept, Error}, State}
  end.
