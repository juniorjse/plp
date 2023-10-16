:- module(Locadora, [menuLocadora/0, listarAlugueisPorCliente/0]).
:- use_module(library(odbc)).
:- use_module(Controller/util).
:- use_module(dbop).
:- use_module(library(date)).

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

    (Opcao = "4" ->
        listarAlugueisPorCliente
    ; Opcao = "0" ->
        writeln('Saindo do sistema...')
    ; otherwise ->
        writeln('Opção inválida. Tente novamente.'),
        menuLocadora
    ).

listarAlugueisPorCliente :-
    writeln('Digite o ID do cliente para listar os registros de aluguéis:'),
    get_input('', ClienteIDStr),
    writeln(''),

    (isANumber(ClienteID, ClienteIDStr) ->
        % Abra uma conexão com o banco de dados PostgreSQL (substitua 'DSN' pelo DSN correto)
        odbc_connect('DSN', Connection, []),

        (clienteExiste(Connection, ClienteID) ->
            obterAlugueisPorCliente(Connection, ClienteID, Alugueis),
            (length(Alugueis, NumRegistros), NumRegistros > 0 ->
                writeln('Registros de Aluguéis:'),
                mostrarRegistrosDeAlugueis(Alugueis)
            ;
                writeln('Não há registros de aluguéis para este cliente.')
            ),
            % Feche a conexão com o banco de dados
            odbc_disconnect(Connection)
        ;
            writeln('Cliente não encontrado na base de dados.')
        )
    ;
        writeln('ID de cliente inválido. Tente novamente.')
    ).

mostrarRegistrosDeAlugueis([]).
mostrarRegistrosDeAlugueis([Registro | RegistrosRestantes]) :-
    mostrarRegistroDeAluguel(Registro),
    mostrarRegistrosDeAlugueis(RegistrosRestantes).

mostrarRegistroDeAluguel(Registro) :-
    writeln('Carro:               '),
    writeln('Data de Início:      '),
    writeln('Data de Devolução:   '),
    writeln('Valor do Aluguel:    R$ '),
    writeln('Status do Aluguel:   '),
    writeln('').

clienteExiste(Connection, ClienteID) :-
    swritef(Query, "SELECT COUNT(*) FROM Usuarios WHERE id_usuario = %w", [ClienteID]),
    db_parameterized_query(Connection, Query, [RowCount]),
    RowCount > 0.

obterAlugueisPorCliente(Connection, ClienteID, Alugueis) :-
    swritef(Query, "SELECT c.marca, c.modelo, c.ano, a.data_inicio, a.data_devolucao, a.valor_total, a.status_aluguel FROM Alugueis a INNER JOIN Carros c ON a.id_carro = c.id_carro WHERE a.id_usuario = %w", [ClienteID]),
    db_parameterized_query(Connection, Query, Alugueis).
