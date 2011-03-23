%%%-------------------------------------------------------------------
%%% File:      emetrics_metrics_resource.erl
%%% @author    joe williams <j@fastip.com>
%%% @copyright 2011 fast_ip
%%% @doc
%%% http end point that produces metrics collected from event handlers
%%% @end
%%%------------------------------------------------------------------

-module(emetrics_metrics_resource).

-export([init/1,
         content_types_provided/2,
         content_types_accepted/2,
         to_json/2,
         from_json/2,
         allowed_methods/2,
         resource_exists/2,
         delete_resource/2]).

-include_lib("webmachine/include/webmachine.hrl").

init(_) -> {ok, undefined}.

content_types_provided(ReqData, Context) ->
    {[{"application/json", to_json}], ReqData, Context}.

content_types_accepted(ReqData, Context) ->
    {[{"application/json", from_json}], ReqData, Context}.

allowed_methods(ReqData, Context) ->
    {['GET', 'PUT', 'DELETE'], ReqData, Context}.

resource_exists(ReqData, Context) ->
    resource_exists(wrq:path_info(id, ReqData), ReqData, Context).

delete_resource(ReqData, Context) ->
    Id = wrq:path_info(id, ReqData),
    emetrics_event:delete_handler(list_to_atom(Id)),
    {true, ReqData, Context}.

to_json(ReqData, Context) ->
    Result = get_request(wrq:path_info(id, ReqData)),
    {mochijson2:encode(Result), ReqData, Context}.

from_json(ReqData, Context) ->
    {struct, Body} = mochijson2:decode(wrq:req_body(ReqData)),
    Result = put_request(wrq:path_info(id, ReqData), Body),
    {mochijson2:encode(Result), ReqData, Context}.


% internal fuctions


resource_exists(undefined, ReqData, Context) ->
    {true, ReqData, Context};
resource_exists(Id, ReqData, Context) ->
    {emetrics_event:handler_exists(list_to_atom(Id)), ReqData, Context}.

get_request(undefined) ->
    emetrics_event:get_handlers();
get_request(Id) ->
    emetrics_event:get_all(list_to_atom(Id)).

put_request(undefined, Body) ->
    Id = list_to_atom(binary_to_list(proplists:get_value(<<"id">>, Body))),
    Type = list_to_atom(binary_to_list(proplists:get_value(<<"type">>, Body))),
    Size = proplists:get_value(<<"size">>, Body),
    add_handler(Type, Id, Size, Body);
put_request(Id, Body) ->
    Value = proplists:get_value(<<"value">>, Body),
    emetrics_event:notify({list_to_atom(Id), Value}).

add_handler(exdec, Id, Size, Body) ->
    Alpha = proplists:get_value(<<"alpha">>, Body),
    emetrics_event:add_handler(Id, exdec, Size, Alpha);
add_handler(uniform, Id, Size, _) ->
    emetrics_event:add_handler(Id, uniform, Size);
add_handler(_, Id, Size, _) ->
    emetrics_event:add_handler(Id, uniform, Size).

