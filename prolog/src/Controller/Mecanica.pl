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
    writeln("|------------------------------------------------------------------------------|"),
    writeln("|                              CARROS COM DEFEITO                              |"),
    writeln("|------------------------------------------------------------------------------|"),
    connectiondb:iniciandoDatabase(Connection),
    user_operations:consultarCarrosPraReparo(Connection,ListaCarros),
    mostraCarros(ListaCarros),
    writeln("|------------------------------------------------------------------------------|\n\n\n"),
    connectiondb:encerrandoDatabase(Connection),
    menuMecanica.

mostraCarros([]).  
mostraCarros([row(Id, Marca, Modelo, Ano, Placa) | Outros]) :-
    format('|Id:~t ~w ~t~7+ Marca:~t ~w ~t~22+ Modelo:~t ~w ~t~21+ Ano:  ~w   Placa:  ~w|~n',[ Id, Marca, Modelo, Ano, Placa]),
    mostraCarros(Outros).