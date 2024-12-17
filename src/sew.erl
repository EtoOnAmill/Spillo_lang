-module(sew).
-export([comp/1]).

%%]#fhaslskjdh#
comp(Filename) ->
    case file:read_file(Filename) of
        {ok, Content} ->
            Lexed = lex:lex(bitstring_to_list(Content)),
            io:format("Lexed succsessfuly:~p~n", [Lexed]),
            Parsed = parse:parse_spillo(Lexed),
            io:format("Parsed succsessfuly:~p~n", [Parsed]),
            io:format("Compiled ~s succsessfuly~n", [Filename]);
        Err -> io:fwrite("Failed with error ~p~n", [Err])
    end,
    halt().

