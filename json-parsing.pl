%%%% -*- Mode: Prolog -*-

%%%%  json-parsing.pl


json([X | Xs]) --> json_array([X | Xs]), !.
json(Val) --> json_object(Val).

json_object([]) --> "{", "}", !.
json_object([X | Xs]) -->  "{", json_member([X | Xs]), "}".

json_member([]) --> [], !.
json_member([X | Xs]) --> json_pair(X), json_member(Xs).

json_pair(X,Y) --> {atom_codes(X,Val)}, atomic(Val), ":", json_pair(Y).

json_array([]) --> [], !.
json_array([X | Xs]) --> json_elements([X | Xs]).

json_elements([X | Xs]) --> json_value(X), json_elements(Xs).

json_value(Val) --> json(Val).
json_value(Val) --> {atom_codes(X,Val), term_string(Y,X)}, integer(Y).
json_value(Val) --> {atom_codes(X,Val)}, string(X).

s --> "" ; (" ";"\t";"\n";"\r"), s.


%%%% json_parse(JSONString, Object)
%json_parse(JSONString, Object) :-
%   atom_codes(JSONString, Codes),
%    phrase(json(X), Codes, _),
%    Object = X.

json_parse(JSONString, Object) :-
    %json_array(JSONString, Object),
    json_obj(JSONString, Object).

json_obj(JSONString, json_obj(Object)) :-
    term_string(X, JSONString),
    {Y} = X,
    json_member(Y, Object).

json_member(JSONString, Object) :-
    term_to_atom(JSONString, X),
    split_string(X,",","", L),
    json_pair(L, Object).

json_pair([], []) :- !.
json_pair([X | Xs], [(A,B)|Ys] ) :-
    term_string(Z, X),
    A:B = Z,
    checkString(A),
    checkJNS(B),
    json_pair(Xs, Ys).

checkString(Val) :- string(Val).
checkJNS(Val) :- number(Val).
checkJNS(Val) :- string(Val).
checkJNS(Val) :- json_parse(Val,_).




%%%% json_get(JSON_obj, Fields, Result)
json_get(JSON_obj, Fields, Result) :-
    json_obj(Y) = JSON_obj,
    json_get_member(Y, Fields, Result).

json_get_member([(X,Y)| _], Z, Result) :-
    X = Z,
    !,
    Result = Y.

json_get_member([_| Xs], Z, Result) :-
    json_get_member(Xs, Z, Result).

json_get_member([], _, _) :- fail.



%%%% json_load(FileName, JSON).
json_load(Filename, JSON) :-
    open(Filename, read, In),
    read_stream_to_codes(In, X),
    close(In),
    atom_codes(JSON, X).


%%%% json_write(JSON, Filename).
json_write(JSON, Filename) :-
    open(Filename, write, Out),
    atom_string(JSON, JSONmod),
    write(Out, JSONmod),
    close(Out).

%%%%  end of file -- json-parsing.pl


















