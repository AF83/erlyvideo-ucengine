-module(ucengine_app).
-author('Thierry Bomandouki <thierry.bomandouki@af83.com>').
-behaviour(application).
-version(1.0).

-export([start/2, stop/1, config_change/3, handle_events/0]).

-include("ucengine.hrl").

%%--------------------------------------------------------------------
%% @spec (Type::any(), Args::list()) -> any()
%% @doc Starts UCengine library
%% @end
%%--------------------------------------------------------------------

handle_events() ->
    receive
	{event, #uce_event{} = Event} ->
	    io:format("E: ~p~n", [Event]),
	    ucengine_event:notify(Event),
	    handle_events();
	stop ->
	    nothing
    end.

start(_Type, _Args) ->
    Config = ems:get_var(ucengine, []),

    {host, Host} = lists:keyfind(host, 1, Config),
    {port, Port} = lists:keyfind(port, 1, Config),
    {uid, Uid} = lists:keyfind(uid, 1, Config),
    {token, Token} = lists:keyfind(token, 1, Config),

    {ok, Supervisor} = ucengine_sup:start_link(Host, Port),
    case ucengine_client:connect(Uid, Token) of
	{ok, _} ->
	    Pid = spawn_link(?MODULE, handle_events, []),
	    Now = integer_to_list(ucengine_client:time()),
	    ucengine_client:subscribe([], ?UCE_MEETING_JOIN_EVENT, [{"start", Now}], Pid),
	    ucengine_client:subscribe([], ?UCE_MEETING_LEAVE_EVENT, [{"start", Now}], Pid),
	    {ok, Supervisor};
	{error, Reason} ->
	    ems_log:error(default, "~p:~p - Destination unreachable: ~p~n", [Host, Port, Reason]),
	    {error, Reason}
    end.

%%--------------------------------------------------------------------
%% @spec (Any::any()) -> ok()
%% @doc UCengine RTMP library
%% @end
%%--------------------------------------------------------------------
stop(_S) ->
    ok.


%%--------------------------------------------------------------------
%% @spec (Any::any(),Any::any(),Any::any()) -> any()
%% @doc Reload UCengine Application config
%% @end
%%--------------------------------------------------------------------
config_change(_Changed, _New, _Remove) ->
    ok.

