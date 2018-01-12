%%%% 816042 Porto Francesco
%%%% 817315 Pelliccioli Simone
%%%% 820934 Valli Mattia

%%%% -*- Mode: Prolog -*-
%%%%  json-parsing.pl

%%%%  json_parse(JSONString, Object)
% -Parses a given JSONString by following its recursive nature
%  (e.g. split an object into members, members into pairs and so on) in
%  order to produce a Prolog friendly list-like form (from now
%  on 'JSON_Object').
% -The main idea is to consume the characters one-by-one, starting from
%  the left side until either an error is found or the string is
%  correctly parsed. In order to do so, almost all of the predicates
%  have this form: predicate_name(InputCharlist, OutputCharlist,
%  InputObject, OutputObject). This is done in order to improve the
%  re-usability of the code.

% If JSONString is an object...
json_parse(JSONString, Object) :-
    string_codes(JSONString, JSONChars),
    skip_newlines_and_whitespaces(JSONChars, JSONChars1),
    json_object(JSONChars1, JSONChars2, [], Object),
    skip_newlines_and_whitespaces(JSONChars2, JSONChars3),
    is_empty(JSONChars3),   %Just to make sure there's nothing nasty at the end
    !.
% If JSONString is an array...
json_parse(JSONString, Object) :-
    string_codes(JSONString, JSONChars),
    skip_newlines_and_whitespaces(JSONChars, JSONChars1),
    json_array(JSONChars1, JSONChars2, [], Object),
    skip_newlines_and_whitespaces(JSONChars2, JSONChars3),
    is_empty(JSONChars3),   %Just to make sure there's nothing nasty at the end
    !.

%%%%  json_object(JSONSChars, JSONChars2, ObjectIn,json_obj(OutObject))
% If there's an empty object {}...
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
% If there's an empty array []...
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

%%%%  json_member(JSONSChars, JSONCharsOut, ObjectIn, ObjectOut)
% It is essential to write both json_members and json_elements in this
% order, since using the opposite one would result in an error (the
% would both unify, which is wrong!). The same idea is used in the rest
% of this program with many predicates.
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
%%%% json_elements(JSONCharsIn, JSONCharsOut, ObjectIn, ObjectOut)
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

%%%% json_pair(JSONCharsIn, JSONCharsOut, ObjectIn, ObjectOut)
json_pair(JSONCharsIn, JSONCharsOut, ObjectIn, ObjectOut) :-
    json_string(JSONCharsIn, JSONChars2, Key),
    skip_newlines_and_whitespaces(JSONChars2, JSONChars3),
    first_char(":", JSONChars3, JSONChars4),
    skip_newlines_and_whitespaces(JSONChars4, JSONChars5),
    json_value(JSONChars5, JSONCharsOut, Value),
    append(ObjectIn, [(Key,Value)], ObjectOut).

%%%% json_string(JSONCharsIn, JSONCharsOut, Key)
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

%%%% json_value(JSONCharsIn, JSONCharsOut, Object)
json_value(JSONCharsIn, JSONCharsOut, Object) :-
    json_string(JSONCharsIn, JSONCharsOut, Object),
    !.
json_value(JSONCharsIn, JSONCharsOut, Object) :-
    json_nested(JSONCharsIn, JSONCharsOut, Object),
    !.
json_value(JSONCharsIn, JSONCharsOut, Object) :-
    json_number(JSONCharsIn, JSONCharsOut, Object),
    !.

%%%% json_number(JSONCharsIn, JSONCharsOut, Object)
%If number is negative...
json_number(JSONCharsIn, JSONCharsOut, Object) :-
    first_char("-", JSONCharsIn, JSONChars2),
    char_code('-', Minus),
    number_creation(JSONChars2, JSONChars3, Value1),
    is_not_empty(Value1),
    append([Minus], Value1, Value1Minus),
    first_char(".", JSONChars3, JSONChars4),
    !,
    char_code('.', Dot),
    append(Value1Minus, [Dot], Value2),
    number_creation(JSONChars4, JSONCharsOut, Value3),
    is_not_empty(Value3),
    append(Value2, Value3, Value),
    number_codes(Object, Value).


json_number(JSONCharsIn, JSONCharsOut, Object) :-
    first_char("-", JSONCharsIn, JSONChars2),
    char_code('-', Minus),
    number_creation(JSONChars2, JSONCharsOut, Value2),
    is_not_empty(Value2),
    !,
    append([Minus], Value2, Value),
    number_codes(Object, Value).

% If number is float...
json_number(JSONCharsIn, JSONCharsOut, Object) :-
    number_creation(JSONCharsIn, JSONChars1, Value1),
    first_char(".", JSONChars1, JSONChars2),
    char_code('.', Dot),
    append(Value1, [Dot], Value1Dot),
    !,
    number_creation(JSONChars2, JSONCharsOut, Value2),
    append(Value1Dot, Value2, Value),
    is_not_empty(Value),
    number_codes(Object, Value).
json_number(JSONCharsIn, JSONCharsOut, Object) :-
    number_creation(JSONCharsIn, JSONCharsOut, Value),
    is_not_empty(Value),
    number_codes(Object, Value).

%%%% is_not_empty(List)
is_not_empty(List) :- List \= [], !.

%%%% is_empty(List)
is_empty(List) :- List = [], !.

%%%% json_nested(JSONCharsIn, JSONCharsOut, Object)
json_nested(JSONCharsIn, JSONCharsOut, Object) :-
    json_object(JSONCharsIn, JSONCharsOut, [], Object),
    !.
json_nested(JSONCharsIn, JSONCharsOut, Object) :-
    json_array(JSONCharsIn, JSONCharsOut, [], Object),
    !.

%%%% first_char(CharToMatch, JSONCharsIn, JSONCharsOut)
% Please note: the following predicates also REMOVES the object from the actual
% char list!
first_char(Char, [X | Xs], JSONChars2) :-
    string_codes(Char, [Y | _]),
    Y = X,
    JSONChars2 = Xs.

%%%% number_creation(JSONCharsIn, JSONCharsOut, JSONCharsNumber)
%beginning of next token
number_creation([X | Xs], [X | Xs], []) :-
    X < 48,
    !.
number_creation([X | Xs], [X | Xs], []) :-
    X > 57,
    !.
number_creation([X | Xs], Zs, [X | Ys]) :-
    number_creation(Xs, Zs, Ys).

%%%% string_creation_sq(JSONCharsIn, JSONCharsOut, JSONCharsString)
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

%%%% string_creation_dq(JSONCharsIn, JSONCharsOut, JSONCharsString)
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


%%%% skip_newlines_and_whitespaces(JSONCharsIn, JSONCharsOut)
skip_newlines_and_whitespaces([],[]) :- !.
skip_newlines_and_whitespaces([X | Xs], Ys) :-
    is_whitespace_or_newline(X),
    !,
    skip_newlines_and_whitespaces(Xs, Ys).
skip_newlines_and_whitespaces([X | Xs], Ys) :-
    Ys = [X | Xs],
    !.

%%%% is_whitespace_or_newline(JSONChars)
is_whitespace_or_newline(X) :-
    is_whitespace_custom(X),
    !.
is_whitespace_or_newline(X) :-
    is_newline_custom(X),
    !.
is_whitespace_or_newline(X) :-
    is_tab_custom(X),
    !.

is_whitespace_custom(X) :-
    char_code(' ', Y),
    X = Y,
    !.
is_newline_custom(X) :-
    char_code('\n', Y),
    X = Y,
    !.
is_tab_custom(X) :-
    char_code('\t', Y),
    X = Y,
    !.

%%%% json_get(JSON_obj, Fields, Result)
% -Follows a chain of keys (iff JSON_obj at current level is an object)
%  or indexes (iff JSON_obj at current level is an array)in order to retrieve
%  a certain value.
% -The main idea is to retrieve the list inside the JSON_obj
%  and recursively work on that list.

% Fails if Elements is empty
json_get(_, [], _) :- !, fail.

% Cannot find anything in an empty object/array!
json_get(json_obj(), _, _) :- !, fail.
json_get(json_array(), _, _) :- !, fail.

json_get(JSON_obj, [X], Result) :-
    json_get_elements(JSON_obj, X, Result),
    !.
json_get(JSON_obj, [X|Xs], Result) :-
    json_get_elements(JSON_obj, X, Temp),
    !,
    json_get(Temp, Xs, Result).
json_get(JSON_obj, X, Result) :-
    json_get_elements(JSON_obj, X, Result),
    !.

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
    string(Z),
    X = Z,
    !,
    Result = Y.
json_get_member([_| Xs], Z, Result) :-
    string(Z),
    json_get_member(Xs, Z, Result).

%%%json_get_member_position(JSON_list, Position, Result)
%Searches an element given an index (Array only!)
json_get_member_position([],[_], _) :- fail.
json_get_member_position([X | _], Y, Result) :-
    number(Y),
    Y = 0,
    !,
    Result = X.
json_get_member_position([_ | Xs], Y, Result) :-
    number(Y),
    Z is Y-1,
    json_get_member_position(Xs, Z, Result).


%%%% json_load(FileName, JSON).
% -Loads a json file and returns its equivalent JSON_Object form
% -Quite self explanatory...
json_load(Filename, JSON) :-
    open(Filename, read, In),
    read_stream_to_codes(In, X),
    close(In),
    atom_codes(JSONString, X),
    json_parse(JSONString, JSON).


%%%% json_write(JSON, Filename).
% -Writes a JSON_Object into a .json file (in JSON-compatible syntax!)
% -The main idea is to retrieve the list inside the JSON_obj and recursively
%  work on that list.
%  (Same as json_get, the only difference being that it returns a string
%  representing the list instead of a single element)
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







