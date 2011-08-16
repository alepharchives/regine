%    __                        __      _
%   / /__________ __   _____  / /___  (_)___  ____ _
%  / __/ ___/ __ `/ | / / _ \/ / __ \/ / __ \/ __ `/
% / /_/ /  / /_/ /| |/ /  __/ / /_/ / / / / / /_/ /
% \__/_/   \__,_/ |___/\___/_/ .___/_/_/ /_/\__, /
%                           /_/            /____/
%
% Copyright (c) Travelping GmbH <info@travelping.com>

-module(regine_event_registry).
-behaviour(regine_server).

-export([start_link/1, publish/3, subscribe/3, get_subscribers/2, get_subscriptions/2, unsubscribe/2, unsubscribe/3]).
-export([init/1, handle_register/4, handle_unregister/2, handle_pid_remove/3, handle_death/3, terminate/2]).

%% ------------------------------------------------------------------------------------------
%% -- API
start_link(ServerName) when is_atom(ServerName) ->
    regine_server:start({local, ServerName}, ?MODULE, {ServerName}).

publish(ServerName, EventType, EventData) ->
    lists:foreach(fun ({_, Pid}) ->
                          Pid ! {'EVENT', ServerName, EventType, EventData}
                  end, ets:lookup(ServerName, EventType)).

subscribe(ServerName, EventType, Pid) ->
    regine_server:register(ServerName, Pid, EventType, undefined).

get_subscribers(ServerName, EventType) ->
    [Pid || {_, Pid} <- ets:lookup(ServerName, EventType)].

get_subscriptions(ServerName, Pid) ->
    regine_server:lookup_pid(ServerName, Pid).

unsubscribe(ServerName, Pid) ->
    regine_server:unregister_pid(ServerName, Pid).

unsubscribe(ServerName, Pid, EventType) ->
    regine_server:unregister_pid(ServerName, Pid, EventType).

%% ------------------------------------------------------------------------------------------
%% -- regine_server callbacks
init({ServerName}) ->
    Table = ets:new(ServerName, [bag, protected, named_table, {read_concurrency, true}]),
    {ok, Table}.

handle_register(Pid, EventType, _Args, Table) ->
    ets:insert(Table, {EventType, Pid}),
    {ok, [EventType], Table}.

handle_unregister(EventType, Table) ->
    Pids = ets:lookup(Table, EventType),
    ets:delete(EventType, Table),
    {Pids, Table}.

handle_pid_remove(Pid, PidEventTypes, Table) ->
    lists:foreach(fun (EventType) ->
                          ets:delete_object(Table, {EventType, Pid})
                  end, PidEventTypes),
    Table.

handle_death(_Pid, _Reason, Table) -> Table.
terminate(_Reason, _State)         -> ok.