%%%% -*- Mode: Prolog -*-

%%%%  json-parsing.pl

json(Val) --> json_object(Val).
json([X | Xs]) --> json_array([X | Xs]).

json_object(Val) --> "{", "}".
json_object(Val) -->  "{", json_member(V), "}".

json_member(Val) --> json_pair(Val).
json_member(Val) --> json_pair(V1), ",", json_member(V2).

json_pair(Val) --> json_string(V1), ":", json_pair(V2).

json_array(Val) --> "[", "]".
json_array(Val) --> "[", json_elements(Val), "]".

json_elements(Val) --> json_value(Val).
json_elements(Val) --> json_value(V1), "," , json_elements(V2).

%json_value(Val) --> json(Val).
json_value(Val) --> number(Val).
json_value(Val) --> json_string(Val).

number(Val) --> digit(Val).
number(Val) --> digit(V1), ".", digit(V2).

json_string(Val) --> { string_codes(Val, X), string(X) }.

%%%% json_parse(JSONString, Object)
json_prova(JSONString, Object) :-
    atom_codes(JSONString, Codes),
    phrase(json(X), Codes, _),
    Object = X.

%%%% json_get(JSON_obj, Fields, Result)
%json_get(JSON_obj, Fields, Result).


%%%% json_load(FileName, JSON).
json_load(Filename, JSON) :-
    open(Filename, read, In),
    read_stream_to_codes(In, X),
    close(In),
    atom_codes(JSON, X).


%%%% json_write(JSON, Filename).
json_write(JSON, Filename) :-
    open(Filename, write, Out),
    write(Out, JSON),
    close(Out).

%%%%  end of file -- json-parsing.pl


















