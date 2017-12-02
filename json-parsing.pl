%%%% -*- Mode: Prolog -*-

%%%%  json-parsing.pl

json_parse(JSONString, Object) :-
    json_array(JSONString, Object),
    !.
json_parse(JSONString, Object) :-
    json_obj(JSONString, Object),
    !.

json_obj(JSONString, json_obj([])) :-
    %usa atom_string per problemi di compatibilità
    starts_with(JSONString, '{'),
    ends_with(JSONString, '}'),
    term_string(X, JSONString),
    X = {},
    !.
json_obj(JSONString, json_obj(Object)) :-
    starts_with(JSONString, '{'),
    ends_with(JSONString, '}'),
    term_string(X, JSONString),
    {Y} = X,
    !,
    json_member(Y, Object).

json_array(JSONString, json_array([])) :-
    starts_with(JSONString, '['),
    ends_with(JSONString, ']'),
    term_string(X, JSONString),
    X = [],
    !.
json_array(JSONString, json_array(Object)) :-
    starts_with(JSONString,'['),
    ends_with(JSONString,']'),
    term_string(X, JSONString),
    [Y | Ys] = X,
    !,
    json_values([Y | Ys], Object).

json_values([], []) :- !.
json_values([X | Xs],[X1 | Ys]) :-
    checkJNS(X,X1),
    json_values(Xs, Ys).

json_member(JSONString, Object) :-
    term_to_atom(JSONString, X),
    %devo mettere in una lista tutte le copie A:B
    split_string(X,",","", L),
    json_pair(L, Object).

json_pair([], []) :- !.
json_pair([X | Xs], [(A1,B1)|Ys] ) :-
    term_string(Z, X),
    A:B = Z,
    checkString(A, A1),
    checkJNS(B, B1),
    json_pair(Xs, Ys).

checkString(Val, Ris) :- string(Val), !, Ris = Val.
checkJNS(Val,Ris) :- number(Val), !, Ris = Val.
checkJNS(Val,Ris) :- json_parse(Val,Ris).
checkJNS(Val,Ris) :- string(Val), !, Ris = Val.

starts_with(String, Char) :-
    string_chars(String, [X|_]),
    X = Char.

ends_with(String, Char) :-
    string_chars(String, X),
    check_ends_with(X, Char).
check_ends_with([X], Char) :-
    !,
    X = Char.
check_ends_with([_|Xs],Char) :-
    check_ends_with(Xs, Char).


skip_newlines_and_whitespaces(String, Result) :-
    string_codes(String, X),
    skip_whitespaces(X, X1),
    skip_newlines(X1, X2),
    string_codes(Result, X2).

skip_whitespaces([], []) :- !.
skip_whitespaces([X | Xs], Ys) :-
    is_whitespace_custom(X),
    !,
    skip_whitespaces(Xs, Ys).
skip_whitespaces([X | Xs], [X | Ys]) :-
    skip_whitespaces(Xs, Ys).

skip_newlines([], []) :- !.
skip_newlines([X | Xs], Ys) :-
    is_newline_custom(X),
    !,
    skip_newlines(Xs, Ys).
skip_newlines([X | Xs], [X | Ys]) :-
    skip_newlines(Xs, Ys).

is_whitespace_custom(X) :-
    string_codes(" ", [Y | _]),
    X = Y.
is_newline_custom(X) :-
    string_codes("\n", [Y | _]),
    X = Y.



%%%% json_get(JSON_obj, Fields, Result)
json_get(_, [], _) :- !, fail.
json_get(json_obj(), _, _) :- !, fail.
json_get(json_array(), _, _) :- !, fail.
json_get(JSON_obj, [X], Result) :-
    json_get_elements(JSON_obj, X, Result),
    !.
json_get(JSON_obj, [X|Xs], Result) :-
    json_get_elements(JSON_obj, X, Temp),
    !,
    json_get(Temp, Xs, Result).
%json_get(JSON_obj, X, Result) :-
%    json_get_elements(JSON_obj, X, Result).

json_get_elements(JSON_obj, Fields, Result) :-
    json_obj([Y|Ys]) = JSON_obj,
    !,
    json_get_member([Y|Ys], Fields, Result).
json_get_elements(JSON_obj, Index , Result) :-
    json_array([X|Xs]) = JSON_obj,
    !,
    json_get_member_position([X | Xs], Index, Result).

json_get_member([], _, _) :- fail.
json_get_member([(X,Y)| _], Z, Result) :-
    X = Z,
    !,
    Result = Y.
json_get_member([_| Xs], Z, Result) :-
    json_get_member(Xs, Z, Result).

json_get_member_position([],[_], _) :- fail.
json_get_member_position([X | _], Y, Result) :-
    Y = 0,
    !,
    Result = X.
json_get_member_position([_ | Xs], Y, Result) :-
    Z is Y-1,
    json_get_member_position(Xs, Z, Result).


%%%% json_load(FileName, JSON).
json_load(Filename, JSON) :-
    open(Filename, read, In),
    read_stream_to_codes(In, X),
    close(In),
    atom_codes(JSONString, X),
    json_parse(JSONString, JSON).


%%%% json_write(JSON, Filename).
json_write(JSON, Filename) :-
    open(Filename, write, Out),
    json_print(JSON, JSONString),
    write(Out, JSONString),
    close(Out).

json_print(JSON, JSONString) :-
    JSON = json_obj([]),
    !,
    JSONString = "{}".
json_print(JSON, JSONString) :-
    json_obj([Y | Ys]) = JSON,
    !,
    concat("", "{", JSONString1),
    json_print_object([Y | Ys], "", JSONString2),
    concat(JSONString1, JSONString2, JSONString3),
    concat(JSONString3, "}", JSONString).
json_print(JSON, JSONString) :-
    JSON = json_array([]),
    !,
    JSONString = "[]".
json_print(JSON, JSONString) :-
    json_array([Y | Ys]) = JSON,
    !,
    concat("", "[", JSONString1),
    json_print_array([Y | Ys], "", JSONString2),
    concat(JSONString1, JSONString2, JSONString3),
    concat(JSONString3, "]", JSONString).


json_print_object([], JSONString, Result) :-
    !,
    string_concat(Temp, ",", JSONString),
    Result = Temp.
json_print_object([(X,Y)| Xs], JSONString, Result) :-
    json_print_element(X, JSONString1),
    string_concat(JSONString, JSONString1, JSONString2),
    string_concat(JSONString2, ":", JSONString3),
    json_print_element(Y, JSONString4),
    string_concat(JSONString3, JSONString4, JSONString5),
    string_concat(JSONString5, ",", JSONString6),
    json_print_object(Xs, JSONString6, Result).


 json_print_array([], JSONString, Result) :-
    !,
    string_concat(Temp, ",", JSONString),
    Result = Temp.
json_print_array([X| Xs], JSONString, Result) :-
    json_print_element(X, JSONString1),
    string_concat(JSONString, JSONString1, JSONString2),
    string_concat(JSONString2, ",", JSONString3),
    json_print_array(Xs, JSONString3, Result).

json_print_element(X, Result) :-
    number(X),
    !,
    Result = X.

json_print_element(X, Result) :-
    json_print(X, Result),
    !.

json_print_element(X, Result) :-
    string(X),
    !,
    string_concat("", "\"", JSONString1),
    string_concat(JSONString1, X, JSONString2),
    string_concat(JSONString2, "\"", JSONString3),
    Result = JSONString3.

%%%%  end of file -- json-parsing.pl


























