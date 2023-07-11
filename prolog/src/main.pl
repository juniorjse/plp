:- use_module(library(readutil)).
:- use_module(library(lists)).

:- use_module(connectiondb).
:- use_module(user).
:- use_module(admin).

main :-
    iniciandoDatabase(Connection),
    createUsuarios(Connection),
    menu,
    close(Connection),
    writeln('').
