:- module(Mecanica, [menuMecanica/0, carrosPraReparo/0, mostraCarros/1]).
:- use_module(library(odbc)).
:- use_module(util).
:- use_module('./localdb/connectiondb').
:- use_module('./localdb/dbop').
:- use_module('./localdb/user_operations').

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

    writeln(''),
    
    (
    Opcao = "1" -> carrosPraReparo;
    Opcao = "2" -> finalizarReparo;
    Opcao = "0" -> writeln('Saindo...\n'), halt;
    writeln('Opção inválida. Por favor, escolha novamente.'), menuCliente
    ).

carrosPraReparo :-
    writeln("------------------------"),
    writeln("   CARROS COM DEFEITO   "),
    writeln("------------------------"),
    writeln(''),
    connectiondb:iniciandoDatabase(Connection),
    user_operations:consultarCarrosPraReparo(Connection,ListaCarros),
    mostraCarros(ListaCarros),
    connectiondb:encerrandoDatabase(Connection),
    menuMecanica.

mostraCarros([]).  
mostraCarros([row(Id, Marca, Modelo, Ano, Placa) | Outros]) :-
    write('| ID:     '),       writeln(Id),
    write('| Marca:  '),    writeln(Marca),
    write('| Modelo: '),   writeln(Modelo),
    write('| Ano:    '),      writeln(Ano),
    write('| Placa:  '),    writeln(Placa),
    writeln(''),
    mostraCarros(Outros).
