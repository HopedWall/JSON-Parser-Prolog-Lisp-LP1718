LP_E1P_JSON_2017: A JSON Parser

Group components:
816042 Porto Francesco
817315 Pelliccioli Simone
820934 Valli Mattia

Main features:
-Directly parses a given JSONString into a Prolog-friendly form
-Retrieves a certain value from a JSON given a list of parameters
-Writes/Reads a JSON from/to a file

How to use this program (with a file):
1) Call json_load(Filename, X), X will be your json in prolog-form.
2) Call json_get(X, fields, Y), in order to retrieve a certain element from your json in Y.
3) Call json_write(X, Filename), your json will be written to a file with name Filename.

Can also be found on Github:
https://github.com/HopedWall/JSONinProlog-Lisp

Thanks for reading!