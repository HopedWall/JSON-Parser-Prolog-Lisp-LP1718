json_parse(JSONString, Object) :-
    string_codes(JSONString, JSONChars),
    skip_newlines_and_whitespaces(JSONChars, JSONChars1),
    json_object(JSONChars1, JSONChars2, [], Object),
    JSONChars2 = [],
    !.
json_parse(JSONString, Object) :-
    string_codes(JSONString, JSONChars),
    skip_newlines_and_whitespaces(JSONChars, JSONChars1),
    json_array(JSONChars1, JSONChars2, [], Object),
    JSONChars2 = [],
    !.

json_object(JSONChars, JSONChars2, InObject, json_obj(OutObject)) :-
    first_char("{", JSONChars, JSONChars1),
    first_char("}", JSONChars1, JSONChars2),
    !,
    InObject = OutObject.
json_object(JSONChars, JSONChars3, InObject, json_obj(OutObject)) :-
    first_char("{", JSONChars, JSONChars1),
    !,
    json_members(JSONChars1, JSONChars2, InObject, OutObject),
    first_char("}", JSONChars2, JSONChars3).

json_array(JSONChars, JSONChars2, InObject, json_array(OutObject)) :-
    first_char("[", JSONChars, JSONChars1),
    first_char("]", JSONChars1, JSONChars2),
    !,
    InObject = OutObject.
json_array(JSONChars, JSONChars3, InObject, json_array(OutObject)) :-
    first_char("[", JSONChars, JSONChars1),
    !,
    json_elements(JSONChars1, JSONChars2, InObject, OutObject),
    first_char("]", JSONChars2, JSONChars3).

json_members(JSONChars1, JSONChars4, InObject, OutObject1) :-
    json_pair(JSONChars1, JSONChars2, InObject, OutObject),
    first_char(",", JSONChars2, JSONChars3),
    json_members(JSONChars3, JSONChars4, OutObject, OutObject1),
    !.
json_members(JSONChars1, JSONChars2, InObject, OutObject) :-
    json_pair(JSONChars1, JSONChars2, InObject, OutObject),
    !.

json_elements(JSONChars1, JSONChars4, InObject, OutObject2) :-
    json_value(JSONChars1, JSONChars2, OutObject),
    first_char(",", JSONChars2, JSONChars3),
    !,
    append(InObject, [OutObject], OutObject1),
    json_elements(JSONChars3, JSONChars4, OutObject1, OutObject2).
json_elements(JSONChars1, JSONChars2, InObject, OutObject1) :-
    json_value(JSONChars1, JSONChars2, OutObject),
    append(InObject, [OutObject], OutObject1),
    !.


json_pair(JSONChars1, JSONChars4, InObject, OutObject) :-
    json_string(JSONChars1, JSONChars2, Key),
    first_char(":", JSONChars2, JSONChars3),
    json_value(JSONChars3, JSONChars4, Value),
    append(InObject, [(Key,Value)], OutObject).

json_string(JSONChars1, JSONChars4, Key) :-
    first_char("\'", JSONChars1, JSONChars2),
    !,
    string_creation_sq(JSONChars2, JSONChars3, Result),
    first_char("\'", JSONChars3, JSONChars4),
    string_codes(Key, Result).
json_string(JSONChars1, JSONChars4, Key) :-
    first_char("\"", JSONChars1, JSONChars2),
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

json_number(JSONChars1, JSONChars2, Object) :-
    number_creation(JSONChars1, JSONChars2, Value),
    number_codes(Object, Value).

json_nested(JSONChars1, JSONChars2, Object) :-
    json_object(JSONChars1, JSONChars2, [], Object),
    !.
json_nested(JSONChars1, JSONChars2, Object) :-
    json_array(JSONChars1, JSONChars2, [], Object),
    !.

first_char(Char, [X | Xs], JSONChars2) :-
    string_codes(Char, [Y | _]),
    Y = X,
    JSONChars2 = Xs.

%rivedere: niente.qualcosa è sbagliato
number_creation([X | Xs], _, [X | Ys]) :-
    string_codes(".", [Char | _]),
    X = Char,
    !,
    number_creation(Xs, _, Ys).
number_creation([X | Xs], [X | Xs], []) :-
    string_codes(",", [Char | _]),
    X = Char,
    !.
number_creation([X | Xs], [X | Xs], []) :-
    string_codes("}", [Char | _]),
    X = Char,
    !.
number_creation([X | Xs], [X | Xs], []) :-
    string_codes("]", [Char | _]),
    X = Char,
    !.
number_creation([X | _], _, _) :-
    X < 48,
    !,
    fail.
number_creation([X | _], _, _) :-
    X > 57,
    !,
    fail.
number_creation([X | Xs], Zs, [X | Ys]) :-
    number_creation(Xs, Zs, Ys).


string_creation_sq([X | _], _, _) :-
    string_codes("\"", [Char | _]),
    X = Char,
    !,
    fail.
string_creation_sq([X | Xs], [X | Xs], []) :-
    string_codes("\'", [Char | _]),
    X = Char,
    !.
string_creation_sq([X | Xs], Zs, [X | Ys]) :-
    string_creation_sq(Xs, Zs, Ys).

string_creation_dq([X | _], _, _) :-
    string_codes("\'", [Char | _]),
    X = Char,
    !,
    fail.
string_creation_dq([X | Xs], [X | Xs], []) :-
    string_codes("\"", [Char | _]),
    X = Char,
    !.
string_creation_dq([X | Xs], Zs, [X | Ys]) :-
    string_creation_dq(Xs, Zs, Ys).



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
































































