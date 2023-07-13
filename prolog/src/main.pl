:- module(main, [main/0]).
:- use_module("Controller/User").
:- use_module("./LocalDB/ConnectionDB", [iniciandoDatabase/1, encerrandoDatabase/1, createUsuarios/1]).

main :-
    iniciandoDatabase(Connection),
    createUsuarios(Connection),
    menu,
    encerrandoDatabase(Connection),
    writeln('').

