:- module(user_operations, [menuMecanica/0]).
:- use_module(library(odbc)).
:- use_module(util).
:- use_module(dbop).

menuMecanica :-
    writeln(''),
    writeln('|---------------------------------|'),
    writeln('|              MENU               |'),
    writeln('|---------------------------------|'),
    writeln('|1. Carros aguardando reparo      |'),
    writeln('|2. Marcar reparo como finalizado |'),
    writeln('|0. Sair                          |'),
    writeln(''),
    writeln('Escolha uma opção: '),

    read_line_to_string(user_input, Opcao),

    writeln('').
