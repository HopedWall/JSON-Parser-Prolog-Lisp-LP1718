%%%% -*- Mode: Prolog -*-

%%%%  json-parsing.pl


%%%% json_parse(JSONString, Object)

%Se è un object...
json_parse(JSONString, Object) :-

% Se è un array...
json_parse([], []).    
json_parse([X | Xs], Object) :-
.

%%%% json_get(JSON_obj, Fields, Result)

json_get(JSON_obj, Fields, Result).


%%%% json_load(FileName, JSON).

json_load(FileName, JSON).

%%%% json_write(JSON, Filename).

json_write(JSON, FileName).



%%%%  end of file -- json-parsing.pl