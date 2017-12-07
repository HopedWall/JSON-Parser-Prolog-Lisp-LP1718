json_parse(JSONString, Object) :-
    string_codes(JSONString, JSONChars),
    skip_newlines_and_whitespaces(JSONChars, JSONChars1),
    json_object(JSONChars1, _,Result),
    Object = json_obj(Result).

json_parse(JSONString, Object) :-
    string_codes(JSONString, JSONChars),
    skip_newlines_and_whitespaces(JSONChars, JSONChars1),
    json_array(JSONChars1, _, Result),
    Object = json_array(Result).

json_object(JSONChars, JSONChars3, Object) :-
    first_char('{', JSONChars, JSONChars1),
    json_members(JSONChars1, JSONChars2, Object),
    first_char('}', JSONChars2, JSONChars3).

json_array(JSONChars, JSONChars3, Object) :-
    first_char('[', JSONChars, JSONChars1),
    json_elements(JSONChars1, JSONChars2, Object),
    first_char(']', JSONChars2, JSONChars3).

json_members(JSONChars1, JSONChars3, Object) :-
    json_pair(JSONChars1, JSONChars2, Object),
    json_members(JSONChars2, JSONChars3, Object).

json_elements(JSONChars1, JSONChars4, Object) :-
    json_value(JSONChars1, JSONChars2, Object),
    first_char(',', JSONChars2, JSONChars3),
    json_elements(JSONChars3, JSONChars4, Object).

json_pair(JSONChars1, JSONChars4, Object) :-
    json_string(JSONChars1, JSONChars2, Object),
    first_char(':', JSONChars2, JSONChars3),
    json_value(JSONChars3, JSONChars4, Object).

json_string(JSONChars1, JSONChars4, Key) :-
    first_char('\'', JSONChars1, JSONChars2),
    !,
    string_creation_sq(JSONChars2, JSONChars3, Result),
    first_char('\'', JSONChars3, JSONChars4),
    string_codes(Key, Result).
json_string(JSONChars1, JSONChars4, Key) :-
    first_char('\"', JSONChars1, JSONChars2),
    !,
    string_creation_dq(JSONChars2, JSONChars3, Result),
    first_char('\"', JSONChars3, JSONChars4),
    string_codes(Key, Result).


json_value(JSONChars1, JSONChars2, Object) :-
    json_string(JSONChars1, JSONChars2, Object),
    !.
json_value(JSONChars1, JSONChars2, Object) :-
    json_number(JSONChars1, JSONChars2, Object),
    !.
json_value(JSONChars1, JSONChars2, Object) :-
    json_nested(JSONChars1, JSONChars2, Object),
    !.

json_number(JSONChars1, _, Object) :-
    parse_number(JSONChars1, _, Object).

json_nested(JSONChars1, JSONChars2, Object) :-
    json_object(JSONChars1, JSONChars2, Object),
    !.
json_nested(JSONChars1, JSONChars2, Object) :-
    json_array(JSONChars1, JSONChars2, Object),
    !.

first_char(Char, [X | Xs], JSONChars2) :-
    string_codes(Char, [Y | _]),
    Y = X,
    JSONChars2 = Xs.

parse_number(X, _, Y) :-
    number_string(Y, X).

string_creation_sq([X | _], _, _) :-
    string_codes("\"", [Char | _]),
    X = Char,
    !,
    fail.
string_creation_sq([X | Xs], [X | Xs], []) :-
    string_codes("\'", [Char | _]),
    X = Char,
    !.
string_creation_sq([X | Xs], _, [X | Ys]) :-
    string_creation_sq(Xs, _, Ys).

string_creation_dq([X | _], _, _) :-
    string_codes("\'", [Char | _]),
    X = Char,
    !,
    fail.
string_creation_dq([X | Xs], [X | Xs], []) :-
    string_codes("\"", [Char | _]),
    X = Char,
    !.
string_creation_dq([X | Xs], _, [X | Ys]) :-
    string_creation_dq(Xs, _, Ys).



skip_newlines_and_whitespaces([],[]) :- !.
skip_newlines_and_whitespaces([X | Xs], Ys) :-
    is_whitespace_or_newline(X),
    !,
    skip_newlines_and_whitespaces(Xs, Ys).
skip_newlines_and_whitespaces([X | Xs], Ys) :-
    Ys = [X | Xs],
    !.

is_whitespace_or_newline(X) :-
    is_whitespace_custom(X),
    !.
is_whitespace_or_newline(X) :-
    is_newline_custom(X),
    !.
is_whitespace_custom(X) :-
    string_codes(" ", [Y | _]),
    X = Y,
    !.
is_newline_custom(X) :-
    string_codes("\n", [Y | _]),
    X = Y,
    !.
































































