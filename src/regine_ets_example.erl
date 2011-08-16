%    __                        __      _
%   / /__________ __   _____  / /___  (_)___  ____ _
%  / __/ ___/ __ `/ | / / _ \/ / __ \/ / __ \/ __ `/
% / /_/ /  / /_/ /| |/ /  __/ / /_/ / / / / / /_/ /
% \__/_/   \__,_/ |___/\___/_/ .___/_/_/ /_/\__, /
%                           /_/            /____/
%
% Copyright (c) Travelping GmbH <info@travelping.com>

-module(regine_ets_example).
-behaviour(regine_server).

-export([start/0, lookup/1, register/2, unregister/1]).
-export([init/1, handle_register/4, handle_unregister/2, handle_death/3, terminate/2]).

-define(NAME, ?MODULE).

%% ------------------------------------------------------------------------------------------
%% -- API
start() ->
    regine_server:start({local, ?NAME}, ?MODULE, {}).

lookup(Key) ->
    ets:lookup(?NAME, Key).

register(Key, Pid) ->
    regine_server:register(?NAME, Pid, Key, undefined).

unregister(Key) ->
    regine_server:unregister(?NAME, Key, undefined).

%% ------------------------------------------------------------------------------------------
%% -- regine_server callbacks
init({}) ->
    Table = ets:new(?NAME, [bag, protected, named_table, {read_concurrency, true}]),
    {ok, Table}.

handle_register(Pid, Key, _Args, Table) ->
    ets:insert(Table, {Key, Pid}),
    {ok, [Key], Table}.

handle_unregister(Key, Table) ->
    Pids = ets:lookup(Table, Key),
    ets:delete(Key, Table),
    {Pids, Table}.

handle_death(Pid, Key, Table) ->
    ets:delete_object(Table, {Key, Pid}),
    Table.

terminate(_Reason, _State) ->
    ok.