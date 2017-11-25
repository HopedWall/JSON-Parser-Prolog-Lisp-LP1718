%%%% -*- Mode: Prolog -*-

%%%%  json-parsing.pl

%%%% json_parse(JSONString, Object)
%json_parse(JSONString, Object) :-
%   atom_codes(JSONString, Codes),
%    phrase(json(X), Codes, _),
%    Object = X.

json_parse(JSONString, Object) :-
    json_array(JSONString, Object).
json_parse(JSONString, Object) :-
    json_obj(JSONString, Object).

json_obj(JSONString, json_obj(Object)) :-
    term_string(X, JSONString),
    {Y} = X,
    json_member(Y, Object).

json_array(JSONString, json_array(Object)) :-
    term_string(X, JSONString),
    [Y | Ys] = X,
    json_values([Y | Ys], Object).

json_values([], []) :- !.
json_values([X | Xs],[X | Ys]) :-
    checkJNS(X),
    json_values(Xs, Ys).

json_member(JSONString, Object) :-
    term_to_atom(JSONString, X),
    %devo mettere in una lista tutte le copie A:B
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
%checkJNS(Val) :- json_parse(Val,_).




%%%% json_get(JSON_obj, Fields, Result)
json_get(JSON_obj, Fields, Result) :-
    json_obj(Y) = JSON_obj,
    json_get_member(Y, Fields, Result).
json_get(JSON_obj, Fields , Result) :-
    json_array([X|Xs]) = JSON_obj,
    json_get_member_position([X | Xs], Fields, Result).

json_get_member([], _, _) :- fail.
json_get_member([(X,Y)| _], Z, Result) :-
    X = Z,
    !,
    Result = Y.
json_get_member([_| Xs], Z, Result) :-
    json_get_member(Xs, Z, Result).

json_get_member_position([],[_], _) :- fail.
json_get_member_position([X | _], [Y], Result) :-
    Y = 0,
    !,
    Result = X.
json_get_member_position([_ | Xs], [Y], Result) :-
    Z is Y-1,
    json_get_member_position(Xs, [Z], Result).



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






















