#!/usr/bin/env escript

main([N]) ->
    run(list_to_integer(N));
main(_) ->
    run(1000).

run(N) ->
    inets:start(),
    sequential(N),
    async(N).

sequential(N) ->
    Start = os:timestamp(),
    {Ok, Err} = lists:foldl(fun(_, {Ok, Err}) ->
        case httpc:request("http://127.0.0.1/") of
            {ok, _} -> {Ok + 1, Err};
            {error, _} -> {Ok, Err + 1}
        end
    end, {0, 0}, lists:seq(1, N)),
    End = os:timestamp(),
    io:format("sequential: ~p~n", [timer:now_diff(End, Start) / 1000000]),
    io:format("  success: ~p, failed: ~p~n", [Ok, Err]).

async(N) ->
    Self = self(),
    Pid = spawn(fun() -> loop(Self, N, {0, 0}) end),
    Start = os:timestamp(),
    lists:foreach(fun(_) ->
        httpc:request(get, {"http://127.0.0.1/", []}, [], [{sync, false}, {receiver, Pid}])
    end, lists:seq(1, N)),
    % rpc:pmap({httpc, request}, [], M),
    receive {finish, {Ok, Err}} -> ok end,
    End = os:timestamp(),
    io:format("async: ~p~n", [timer:now_diff(End, Start) / 1000000]),
    io:format("  success: ~p, failed: ~p~n", [Ok, Err]).

loop(Pid, 0, Status) ->
    Pid ! {finish, Status};
loop(Pid, N, {Ok, Err}) ->
    receive
        {http, {_, {error, _}}} -> loop(Pid, N-1, {Ok, Err+1});
        {http, _} -> loop(Pid, N-1, {Ok+1, Err})
    end.
