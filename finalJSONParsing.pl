%%%% -*- Mode: Prolog -*-
%%%%  json-parsing.pl

%%%%  json_parse(JSONString, Object)
% -Parses a JSONString and returns its equivalent JSON_Object.
% -Follows the recursive nature of a given JSON
%  (e.g. split an object into members, members into pairs and so on) in
%  order to produce a Prolog friendly list-like form (from now
%  on 'JSON_Object').
% -The main idea is to consume the characters one-by-one, starting from
%  the left side until either an error is found or the string is
%  correctly parsed. In order to do so, almost all of the predicates
%  have this form: predicate_name(InputCharlist, OutputCharlist,
%  InputObject, OutputObject). This is done in order to improve the
%  re-usability of the code.

json_parse(JSONString, Object) :-
    string_codes(JSONString, JSONChars),
    skip_newlines_and_whitespaces(JSONChars, JSONChars1),
    json_object(JSONChars1, JSONChars2, [], Object),
    skip_newlines_and_whitespaces(JSONChars2, JSONChars3),
    JSONChars3 = [],
    !.
json_parse(JSONString, Object) :-
    string_codes(JSONString, JSONChars),
    skip_newlines_and_whitespaces(JSONChars, JSONChars1),
    json_array(JSONChars1, JSONChars2, [], Object),
    skip_newlines_and_whitespaces(JSONChars2, JSONChars3),
    JSONChars3 = [],
    !.

%%%%  json_object(JSONSChars, JSONChars2, ObjectIn,json_obj(OutObject))
json_object(JSONCharsIn, JSONCharsOut, ObjectIn, json_obj(ObjectOut)) :-
    first_char("{", JSONCharsIn, JSONChars1),
    skip_newlines_and_whitespaces(JSONChars1, JSONChars2),
    first_char("}", JSONChars2, JSONCharsOut),
    !,
    ObjectIn = ObjectOut.
json_object(JSONCharsIn, JSONCharsOut, ObjectIn, json_obj(ObjectOut)) :-
    first_char("{", JSONCharsIn, JSONChars1),
    !,
    skip_newlines_and_whitespaces(JSONChars1, JSONChars2),
    json_members(JSONChars2, JSONChars3, ObjectIn, ObjectOut),
    skip_newlines_and_whitespaces(JSONChars3, JSONChars4),
    first_char("}", JSONChars4, JSONCharsOut).

%%%%  json_array(JSONSChars, JSONChars2, ObjectIn,json_array(ObjectOut))
json_array(JSONCharsIn, JSONCharsOut, ObjectIn, json_array(ObjectOut)) :-
    first_char("[", JSONCharsIn, JSONChars1),
    skip_newlines_and_whitespaces(JSONChars1, JSONChars2),
    first_char("]", JSONChars2, JSONCharsOut),
    !,
    ObjectIn = ObjectOut.
json_array(JSONCharsIn, JSONCharsOut, ObjectIn, json_array(ObjectOut)) :-
    first_char("[", JSONCharsIn, JSONChars1),
    !,
    skip_newlines_and_whitespaces(JSONChars1, JSONChars2),
    json_elements(JSONChars2, JSONChars3, ObjectIn, ObjectOut),
    skip_newlines_and_whitespaces(JSONChars3, JSONChars4),
    first_char("]", JSONChars4, JSONCharsOut).

%%%%  json_member(JSONSChars, JSONChars
json_members(JSONCharsIn, JSONCharsOut, ObjectIn, ObjectOut1) :-
    json_pair(JSONCharsIn, JSONChars2, ObjectIn, ObjectOut),
    skip_newlines_and_whitespaces(JSONChars2, JSONChars3),
    first_char(",", JSONChars3, JSONChars4),
    skip_newlines_and_whitespaces(JSONChars4, JSONChars5),
    json_members(JSONChars5, JSONCharsOut, ObjectOut, ObjectOut1),
    !.
json_members(JSONCharsIn, JSONCharsOut, ObjectIn, ObjectOut) :-
    json_pair(JSONCharsIn, JSONCharsOut, ObjectIn, ObjectOut),
    !.

json_elements(JSONCharsIn, JSONCharsOut, ObjectIn, ObjectOut2) :-
    json_value(JSONCharsIn, JSONChars2, ObjectOut),
    skip_newlines_and_whitespaces(JSONChars2, JSONChars3),
    first_char(",", JSONChars3, JSONChars4),
    skip_newlines_and_whitespaces(JSONChars4, JSONChars5),
    !,
    append(ObjectIn, [ObjectOut], ObjectOut1),
    json_elements(JSONChars5, JSONCharsOut, ObjectOut1, ObjectOut2).
json_elements(JSONCharsIn, JSONCharsOut, ObjectIn, ObjectOut1) :-
    json_value(JSONCharsIn, JSONCharsOut, ObjectOut),
    append(ObjectIn, [ObjectOut], ObjectOut1),
    !.


json_pair(JSONCharsIn, JSONCharsOut, ObjectIn, ObjectOut) :-
    json_string(JSONCharsIn, JSONChars2, Key),
    skip_newlines_and_whitespaces(JSONChars2, JSONChars3),
    first_char(":", JSONChars3, JSONChars4),
    skip_newlines_and_whitespaces(JSONChars4, JSONChars5),
    json_value(JSONChars5, JSONCharsOut, Value),
    append(ObjectIn, [(Key,Value)], ObjectOut).

json_string(JSONCharsIn, JSONCharsOut, Key) :-
    first_char("\'", JSONCharsIn, JSONChars2),
    !,
    string_creation_sq(JSONChars2, JSONChars3, Result),
    first_char("\'", JSONChars3, JSONCharsOut),
    string_codes(Key, Result).
json_string(JSONCharsIn, JSONCharsOut, Key) :-
    first_char("\"", JSONCharsIn, JSONChars2),
    !,
    string_creation_dq(JSONChars2, JSONChars3, Result),
    first_char('\"', JSONChars3, JSONCharsOut),
    string_codes(Key, Result).


json_value(JSONCharsIn, JSONCharsOut, Object) :-
    json_string(JSONCharsIn, JSONCharsOut, Object),
    !.
json_value(JSONCharsIn, JSONCharsOut, Object) :-
    json_number(JSONCharsIn, JSONCharsOut, Object),
    !.
json_value(JSONCharsIn, JSONCharsOut, Object) :-
    json_nested(JSONCharsIn, JSONCharsOut, Object),
    !.

json_number(JSONCharsIn, JSONCharsOut, Object) :-
    number_creation(JSONCharsIn, JSONChars1, Value1),
    first_char('.', JSONChars1, JSONChars2),
    char_code('.', Dot),
    append(Value1, [Dot], Value1Dot),
    !,
    number_creation(JSONChars2, JSONCharsOut, Value2),
    append(Value1Dot, Value2, Value),
    number_codes(Object, Value).

json_number(JSONCharsIn, JSONCharsOut, Object) :-
    number_creation(JSONCharsIn, JSONCharsOut, Value),
    number_codes(Object, Value).

json_nested(JSONCharsIn, JSONCharsOut, Object) :-
    json_object(JSONCharsIn, JSONCharsOut, [], Object),
    !.
json_nested(JSONCharsIn, JSONCharsOut, Object) :-
    json_array(JSONCharsIn, JSONCharsOut, [], Object),
    !.

first_char(Char, [X | Xs], JSONChars2) :-
    string_codes(Char, [Y | _]),
    Y = X,
    JSONChars2 = Xs.

%beginning of next token
number_creation([X | Xs], [X | Xs], []) :-
    X < 48,
    !.
number_creation([X | Xs], [X | Xs], []) :-
    X > 57,
    !.
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

%%%% json_get(JSON_obj, Fields, Result)

% Fails if Elements is empty
json_get(_, [], _) :- !, fail.

% Cannot find anything in an empty object/array!
json_get(json_obj(), _, _) :- !, fail.
json_get(json_array(), _, _) :- !, fail.

%
json_get(JSON_obj, [X], Result) :-
    json_get_elements(JSON_obj, X, Result),
    !.
json_get(JSON_obj, [X|Xs], Result) :-
    json_get_elements(JSON_obj, X, Temp),
    !,
    json_get(Temp, Xs, Result).

%%%json_get_elements(JSON_obj, Fields, Result)
%If Object is an object...
json_get_elements(JSON_obj, Fields, Result) :-
    json_obj([Y|Ys]) = JSON_obj,
    !,
    json_get_member([Y|Ys], Fields, Result).

%If Object is an array...
json_get_elements(JSON_obj, Index , Result) :-
    json_array([X|Xs]) = JSON_obj,
    !,
    json_get_member_position([X | Xs], Index, Result).

%%%json_get_member(JSON_list, Key, Result)
%Searches an element given a Key (Object only!)
json_get_member([], _, _) :- fail.
json_get_member([(X,Y)| _], Z, Result) :-
    X = Z,
    !,
    Result = Y.
json_get_member([_| Xs], Z, Result) :-
    json_get_member(Xs, Z, Result).

%%%json_get_member_position(JSON_list, Position, Result)
%Searches an element given an index (Array only!)
json_get_member_position([],[_], _) :- fail.
json_get_member_position([X | _], Y, Result) :-
    Y = 0,
    !,
    Result = X.
json_get_member_position([_ | Xs], Y, Result) :-
    Z is Y-1,
    json_get_member_position(Xs, Z, Result).


%%%% json_load(FileName, JSON).
%Loads a json file and returns its equivalent JSON_Object form
json_load(Filename, JSON) :-
    open(Filename, read, In),
    read_stream_to_codes(In, X),
    close(In),
    atom_codes(JSONString, X),
    json_parse(JSONString, JSON).


%%%% json_write(JSON, Filename).
%Writes a json (in JSON_Object form) into a .json file (in JSON-compatible syntax!)
json_write(JSON, Filename) :-
    open(Filename, write, Out),
    json_print(JSON, JSONString),
    write(Out, JSONString),
    close(Out).

%%% json_print(JSON, JSONString)
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

%%% json_print_object(JSONList, JSONString, Result)
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

%%% json_print_array(JSONList, JSONString, Result)
json_print_array([], JSONString, Result) :-
    !,
    string_concat(Temp, ",", JSONString),
    Result = Temp.
json_print_array([X| Xs], JSONString, Result) :-
    json_print_element(X, JSONString1),
    string_concat(JSONString, JSONString1, JSONString2),
    string_concat(JSONString2, ",", JSONString3),
    json_print_array(Xs, JSONString3, Result).

%%% json_print_element(Element, Result)
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
