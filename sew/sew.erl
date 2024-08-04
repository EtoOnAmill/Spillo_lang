-module(sew).
-export([comp/1]).

comp(Filename) -> 
    case file:read_file(Filename) of
        {ok, Content} -> io:format("Compiled ~s succsessfuly~n", [Filename]);
        Err -> io:fwrite("Failed with error ~p~n", [Err])
    end.
