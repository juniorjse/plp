:- module(locadora, [menuLocadora/0, opcaoMenu/1, cadastrarCarro/0, listarAlugueisPorPessoa/0, confirmaCadastro/1]).
:- use_module(library(odbc)).
:- use_module('./localdb/connectiondb').
:- use_module('./localdb/dbop').
:- use_module('./localdb/user_operations').
:- use_module('./localdb/util').

menuLocadora :-
    writeln(''),
    writeln('Menu:'),
    writeln('1. Cadastrar carro'),
    writeln('2. Remover Carro'),
    writeln('3. Registrar Devolução'),
    writeln('4. Registro de Aluguéis por pessoa'),
    writeln('5. Dashboard'),
    writeln('0. Sair'),
    writeln('Escolha uma opção:'),

    read_line_to_string(user_input, Opcao),

    (Opcao = "1" -> cadastrarCarro;
    Opcao = "4" -> listarAlugueisPorPessoa;
    Opcao = "0" -> writeln('Saindo do sistema...'), halt; 
    otherwise -> writeln('Opção inválida. Tente novamente.')),
    menuLocadora.


listarAlugueisPorPessoa :-
    writeln('Digite o ID do cliente para listar os registros de aluguéis:'),
    util:get_input('', ClienteIDStr),
    writeln(''),

    (util:isANumber(ClienteID, ClienteIDStr) ->
        connectiondb:iniciandoDatabase(Connection),
        (clienteExiste(Connection, ClienteID) ->
            obterAlugueisPorPessoa(Connection, ClienteID, Alugueis),
            (length(Alugueis, NumRegistros), NumRegistros > 0 ->
                writeln('Registros de Aluguéis:'),
                mostrarRegistrosDeAlugueis(Connection, Alugueis)
            ;
                writeln('Não há registros de aluguéis para este cliente.')
            ),
            connectiondb:encerrandoDatabase(Connection)
        ;
            writeln('Cliente não encontrado na base de dados.')
        )
    ;
        writeln('ID de cliente inválido. Tente novamente.')
    ).

mostrarRegistrosDeAlugueis(_, []).
mostrarRegistrosDeAlugueis(Connection, [Registro | RegistrosRestantes]) :-
    mostrarRegistroDeAluguel(Connection, Registro),
    mostrarRegistrosDeAlugueis(Connection, RegistrosRestantes).

mostrarRegistroDeAluguel(Connection, Registro) :-
    user_operations:getCarro(Connection, CarroID, CarroInfo), % Função que obtém informações do carro
    user_operations:verificaTempoAluguel(Connection, Registro, DataInicio), % Função que verifica a data de início
    user_operations:verificaTempoAluguel(Connection, Registro, DataDevolucao), % Função que verifica a data de devolução
    user_operations:verificaTempoAluguel(Connection, Registro, Valor), % Função que verifica o valor
    user_operations:verificaTempoAluguel(Connection, Registro, Status), % Função que verifica o status
    writeln('Carro:               '), writeln(CarroInfo), % Imprime informações do carro
    writeln('Data de Início:      '), writeln(DataInicio), % Imprime informações da data de início
    writeln('Data de Devolução:   '), writeln(DataDevolucao), % Imprime informações da data de devolução
    writeln('Valor do Aluguel:    R$ '), writeln(Valor), % Imprime informações do valor
    writeln('Status do Aluguel:   '), writeln(Status), % Imprime informações do status
    writeln('').
