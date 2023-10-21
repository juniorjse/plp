:- module(Mecanica, [menuMecanica/0, carrosPraReparo/0, mostraCarros/1,
 finalizarReparo/0, listarCarrosReparo/2]).
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

finalizarReparo :-
    connectiondb:iniciandoDatabase(Connection),

    user_operations:consultarCarrosPraReparo(Connection, ListaCarros),

    (ListaCarros = [] ->
        writeln('Não há carros em reparo para finalizar.');
    listarCarrosReparo(ListaCarros, 1), % Função para listar os carros em reparo
        writeln('Informe o ID do carro a ser finalizado o reparo:'),
        read(CarroIdStr),
        atom_number(CarroIdStr, CarroId),
        (
            member(CarroId, ListaCarros) ->
            writeln('Há algum valor a ser pago para o reparo? (0 para nenhum valor):'),
            read(ValorReparoStr),
            atom_number(ValorReparoStr, ValorReparo),
        
            dbop:db_parameterized_query(Connection, "SELECT id_aluguel FROM Alugueis WHERE id_carro = $1 AND status_aluguel = 'ativo'", [CarroId], [AluguelId]),
            dbop:db_parameterized_query(Connection, "UPDATE Alugueis SET valor_total = valor_total + $1 WHERE id_aluguel = $2", [ValorReparo, AluguelId], _),
            dbop:db_parameterized_query(Connection, "UPDATE Alugueis SET status_aluguel = 'Concluído' WHERE id_carro = $1 AND status_aluguel = 'ativo'", [CarroId], _),
            dbop:db_parameterized_query(Connection, "UPDATE Carros SET status = 'D' WHERE id_carro = $1", [CarroId], _),
            
            (ValorReparo > 0 ->
                writeln('Valor do reparo computado.');
            writeln('Reparo finalizado com sucesso!')
            );
            writeln('O carro selecionado não está em reparo.')
        )
    ),

    connectiondb:encerrandoDatabase(Connection).

listarCarrosReparo([], _).
listarCarrosReparo([Carro|Resto], N) :-
    format('ID: ~w ~w\n', [N, Carro]),
    N1 is N + 1,
    listarCarrosReparo(Resto, N1).


