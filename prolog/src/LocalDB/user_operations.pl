:- module(user_operations, [createUser/6, getUserByEmail/3, getTipoByEmail/3, getUser/4, userAlreadyExists/3, getusuariosByEmail/4, alugar/5, getCarro/3, buscarAlugueisPorUsuario/3, printAluguelInfo/1, verificaTempoAluguel/3, getAlugueisPorPessoa/3, clienteExiste/2]).

:- use_module(library(odbc)).
:- use_module('./util.pl').
:- use_module('./dbop.pl').

getUserByEmail(Connection, Email, User):-
    Q = "SELECT * FROM usuarios WHERE email = '%w'",
    db_parameterized_query(Connection, Q, [Email], User).

getTipoByEmail(Connection, Email, Tipo):-
    Q = "SELECT tipo FROM usuarios WHERE email = '%w'",
    db_parameterized_query(Connection, Q, [Email], Tipo).

getUser(Connection, Email, Senha, User) :-
    Q = "SELECT * FROM usuarios WHERE email = '%w' and senha = '%w'",
    db_parameterized_query(Connection, Q, [Email, Senha], User).

userAlreadyExists(Connection, Email, Confirmacao):-
    getUserByEmail(Connection, Email, User),
    length(User, Confirmacao).

clienteExiste(Connection, ClienteID) :-
    Q = "SELECT COUNT(*) FROM usuarios WHERE id_usuario = %w",
    db_parameterized_query(Connection, Q, [ClienteID], [row(CountRow)]),

    % Verificar se a contagem é maior que zero
    (CountRow = row(Count), Count > 0).

getusuariosByEmail(Connection, [Email | T], usuariosTemp, usuarios) :-
    length(T, L),
    (L > 0 ->
        getUserByEmail(Connection, Email, User),
        getusuariosByEmail(Connection, T, [User | usuariosTemp], usuarios);
     getUserByEmail(Connection, Email, User),
     reverse([User | usuariosTemp], usuarios)
    ).

createUser(Connection, Email, Senha, Nome, Sobrenome, Confirmacao) :-
    userAlreadyExists(Connection, Email, Fstconf),
    (Fstconf =:= 0 ->
        db_parameterized_query_no_return(
            Connection, 
            "INSERT INTO usuarios (nome, sobrenome, email, senha) values ('%w','%w','%w','%w');",
            [Nome, Sobrenome, Email, Senha]
        ),
        Confirmacao is 1;
     Confirmacao is 0
    ).

alugar(Connection, UserID, CarroID, DiasAluguel, ValorTotal) :-
    db_parameterized_query_no_return(
        Connection, 
        "INSERT INTO alugueis (id_carro, id_usuario, data_inicio, data_devolucao, valor_total, status_aluguel) VALUES (%w, %w, current_date, current_date + interval '%w day', %w, 'ativo');",
        [CarroID, UserID, DiasAluguel, ValorTotal]
    ),
    % Atualizar o status do carro para 'O' (ou o status apropriado) na tabela "Carros"
    db_parameterized_query_no_return(
        Connection, 
        "UPDATE carros SET status = 'O' WHERE id_carro = %w;",
        [CarroID]
    ).

getCarro(Connection, CarroID, CarroInfo) :-
    Q = "SELECT * FROM carros WHERE id_carro = '%w'",
    db_parameterized_query(Connection, Q, [CarroID], CarroInfo).

% buscarAlugueisPorUsuario/3
buscarAlugueisPorUsuario(Connection, UserID, Alugueis) :-
    Q = "SELECT id_aluguel, id_carro, valor_total FROM Aluguéis WHERE id_usuario = '%w' AND status_aluguel = 'ativo'",
    db_parameterized_query(Connection, Q, [UserID], Alugueis).

% printAluguelInfo/1
printAluguelInfo(row(IdAluguel, IdCarro, ValorTotal)) :-
    format('~w             |       ~w     |        ~w~n', [IdAluguel, IdCarro, ValorTotal]).

% verificaTempoAluguel/3
verificaTempoAluguel(Connection, AluguelId, Tempo) :-
    Q = "SELECT verificaTempoAluguel('%w')",
    db_parameterized_query(Connection, Q, [AluguelId], [row(Tempo)]).

% getAlugueisPorPessoa/3
getAlugueisPorPessoa(Connection, ClienteID, Alugueis) :-
    swritef(Query, "SELECT c.marca, c.modelo, a.data_inicio, a.data_devolucao, a.valor_total, a.status_aluguel FROM Aluguéis a INNER JOIN carros c ON a.id_carro = c.id_carro WHERE a.id_usuario = %w", [ClienteID]),
    db_parameterized_query(Connection, Query, Alugueis).
