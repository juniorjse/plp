:- module(main, [main/0]).
:- use_module("./Controller/User").
:- use_module("./LocalDB/ConnectionDB").

main :-
    iniciandoDatabase(Connection),
    createUsuarios(Connection),
    menu,
    close(Connection),
    writeln('').
