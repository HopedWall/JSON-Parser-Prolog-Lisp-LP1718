LP_E1P_JSON_2017: A JSON Parser

Group components:
816042 Porto Francesco
817315 Pelliccioli Simone
820934 Valli Mattia

Main features:
-Directly parses a given JSONString into a Lisp-friendly form
-Retrieves a certain value from a JSON given a list of parameters
-Writes/Reads a JSON from/to a file

How to use this program (with a file):
1) Call json-load(filename), in order to get the Lisp-friendly-form of your .json file. 
2) Call json-get(json, fields), in order to retrieve a certain element from your json (NOTE: here json IS json_obj, the result of json-load/json-parse).
3) Call json-write(json, Filename), your json will be written to a file with name Filename (NOTE: here json IS json_obj, the result of json-load/json-parse).

Can also be found on Github:
https://github.com/HopedWall/JSONinProlog-Lisp

Thanks for reading!