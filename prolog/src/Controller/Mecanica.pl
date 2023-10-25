:- module(Mecanica, [menuMecanica/0, carrosPraReparo/0, mostraCarros/1, carrosPraReparo/0, mostraCarros/1,
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
    Opcao = "1" -> carrosPraReparo,    menuMecanica;
    Opcao = "2" -> finalizarReparo,    menuMecanica;
    Opcao = "0" -> writeln('Saindo...\n'), halt;
    writeln('Opção inválida. Por favor, escolha novamente.'), menuMecanica
    ).

carrosPraReparo :-
    writeln("|------------------------------------------------------------------------------|"),
    writeln("|                              CARROS COM DEFEITO                              |"),
    writeln("|------------------------------------------------------------------------------|"),
    connectiondb:iniciandoDatabase(Connection),
    user_operations:consultarCarrosPraReparo(Connection,ListaCarros),
    mostraCarros(ListaCarros),
    writeln("|------------------------------------------------------------------------------|\n\n\n"),
    connectiondb:encerrandoDatabase(Connection).

mostraCarros([]).  
mostraCarros([row(Id, Marca, Modelo, Ano, Placa) | Outros]) :-
    format('|Id:~t ~w ~t~7+ Marca:~t ~w ~t~22+ Modelo:~t ~w ~t~21+ Ano:  ~w   Placa:  ~w|~n',[ Id, Marca, Modelo, Ano, Placa]),
    mostraCarros(Outros).

finalizarReparo :-
    connectiondb:iniciandoDatabase(Connection),
    user_operations:consultarCarrosPraReparo(Connection, Carros) ,

    (Carros = [] ->
        writeln('Não há carros em reparo para finalizar.');
        carrosPraReparo, % Função para listar os carros em reparo
        writeln('Informe o ID do carro a ser finalizado o reparo:'),
        read_line_to_string(user_input, CarroIdStr),
        atom_number(CarroIdStr, CarroId),
        (
            user_operations:carroPraReparo(Connection, CarroId) ->
            writeln('Há algum valor a ser pago para o reparo? (0 para nenhum valor):'),
            read_line_to_string(user_input, ValorReparoStr),
            atom_number(ValorReparoStr, ValorReparo),
        
            dbop:db_parameterized_query(Connection, "SELECT id_aluguel FROM Alugueis WHERE id_carro = %w AND status_aluguel = 'ativo'", [CarroId], [row(AluguelId)]),
            dbop:db_parameterized_query_no_return(Connection, "UPDATE Alugueis SET valor_total = valor_total + %d WHERE id_aluguel = %d", [ValorReparo,AluguelId]),
            dbop:db_parameterized_query_no_return(Connection, "UPDATE Alugueis SET status_aluguel = 'Concluído' WHERE id_carro = %w AND status_aluguel = 'ativo'", [CarroId]),
            dbop:db_parameterized_query_no_return(Connection, "UPDATE Carros SET status = 'D' WHERE id_carro = %w", [CarroId]),
            
            (ValorReparo > 0 ->
                writeln('Valor do reparo computado.');
            writeln('Reparo finalizado com sucesso!')
            );
            writeln('O carro selecionado não está em reparo.')
        )
    ),

    connectiondb:encerrandoDatabase(Connection).


