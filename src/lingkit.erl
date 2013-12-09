-module(lingkit).
-export([compile_forms/1, compile_forms/2, convert_bytecode/1, test_forms/0]).

compile_forms(Forms) ->
    compile_forms(Forms, [verbose, report_errors, report_warnings]).

compile_forms(Forms, Opts) ->
    case compile:forms(Forms, Opts) of
        {ok, Module, Binary} -> {ok, Module, convert_bytecode(Binary)};
        {ok, Module, Binary, W} -> {ok, Module, convert_bytecode(Binary), W};
        Error -> Error
    end.

convert_bytecode(Binary) ->
    Username = application:get_env(lingkit, username, "test"),
    Password = application:get_env(lingkit, password, "test"),
    BuildService = application:get_env(lingkit, build_service, "https://build.erlangonxen.org:8080"),
    Encoded = base64:encode_to_string(lists:append([Username, ":", Password])),
    AuthHeader = {"Authorization","Basic " ++ Encoded},

    case httpc:request(
            post,
            {BuildService ++ "/1/transform", [AuthHeader], "application/octet-stream", Binary},
            [],
            [{sync, true}, {body_format, binary}]) of
        {ok, {_, _, Response}} -> Response;
        E -> {error, {convert_bytecode, E}}
    end.

test_forms() -> [{attribute,1,module,userboot},{attribute,2,compile,[export_all]},{function,4,start,0,[{clause,4,[],[],[{call,5,{remote,5,{atom,5,erlang},{atom,5,display}},[{atom,5,hello}]}]}]}].
