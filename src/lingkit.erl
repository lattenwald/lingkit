-module(lingkit).
-export([compile_forms/1, compile_forms/2, convert_bytecode/1, convert_bytecode/2, test_forms/0]).

compile_forms(Forms) ->
    compile_forms(Forms, [verbose, report_errors, report_warnings]).

compile_forms(Forms, Opts) ->
    case compile:forms(Forms, Opts) of
        {ok, Module, Binary} -> {ok, Module, convert_bytecode(Binary)};
        {ok, Module, Binary, W} -> {ok, Module, convert_bytecode(Binary), W};
        Error -> Error
    end.

convert_bytecode(Binary) -> convert_bytecode(Binary, erlang:system_info(machine)).

convert_bytecode(Binary, "BEAM") -> Binary;
convert_bytecode(Binary, "LING") ->
    Username = application:get_env(lingkit, username, "test"),
    Password = application:get_env(lingkit, password, "test"),
    BuildService = application:get_env(lingkit, build_service, "http://build.erlangonxen.org:8088"),
    Encoded = base64:encode_to_string(lists:append([Username, ":", Password])),
    AuthHeader = {"Authorization","Basic " ++ Encoded},

    case httpc:request(
            post,
            {BuildService ++ "/1/transform", [AuthHeader], "application/octet-stream", Binary},
            [{ssl, [{verify, verify_none}]}],
            [{sync, true}, {body_format, binary}, {socket_opts, [{recbuf, 32768}]}]) of
        {ok, {_, _, Response}} -> Response;
        E -> {error, {convert_bytecode, E}}
    end;
convert_bytecode(Binary, _) -> Binary. % wow!

test_forms() -> [{attribute,1,module,userboot},{attribute,2,compile,[export_all]},{function,4,start,0,[{clause,4,[],[],[{call,5,{remote,5,{atom,5,erlang},{atom,5,display}},[{atom,5,hello}]}]}]}].
