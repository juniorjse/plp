:- module(user_operations, [createUser/6, getUserByEmail/3, getTipoByEmail/3, getUser/4, userAlreadyExists/3, getusuariosByEmail/4,
                            createCar/8, carroPorPlaca/3, carAlreadyExists/3, getProximoIDCarro/2, consultarCarrosPraReparo/2,
                            alugar/5, getCarro/3, buscarAlugueisPorUsuario/3, printAluguelInfo/1, verificaTempoAluguel/3, getAlugueisPorPessoa/3, clienteExiste/2]).

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
    (CountRow > 0).

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
    Q = "SELECT * FROM carros WHERE id_carro = %w",
    db_parameterized_query(Connection, Q, [CarroID], CarroInfo), writeln(CarroInfo).

% buscarAlugueisPorUsuario/3
buscarAlugueisPorUsuario(Connection, UserID, Alugueis) :-
    Q = "SELECT id_aluguel, id_carro, valor_total FROM Alugueis WHERE id_usuario = '%w' AND status_aluguel = 'ativo'",
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
    Query = "SELECT c.id_carro, c.marca, c.modelo, c.ano, a.data_inicio, a.data_devolucao, a.valor_total, a.status_aluguel FROM Alugueis a INNER JOIN carros c ON a.id_carro = c.id_carro WHERE a.id_usuario = %w",
    db_parameterized_query(Connection, Query, [ClienteID], Alugueis).


consultarCarrosPraReparo(Connection, Carros) :-
    db_query(
        Connection, 
        "SELECT id_carro, marca, modelo, ano, placa FROM carros WHERE status = 'R'", 
        Carros).

carrosPorPopularidade(Connection,Carros) :-
    db_query(Connection,
    "SELECT c.marca, c.modelo, c.ano, c.placa, COUNT(*) as quantidade_alugueis FROM Alugueis a JOIN Carros c ON a.id_carro = c.id_carro GROUP BY c.marca, c.modelo, c.ano, c.placa ORDER BY quantidade_alugueis DESC;",
    Carros).

carroPorPlaca(Connection, Placa, Carro) :-
    Q = "SELECT * FROM carros WHERE placa = '%w';",
    db_parameterized_query(Connection, Q, [Placa], Carro).

getProximoIDCarro(Connection, ProximoID) :-
    db_query(
        Connection,
        "SELECT COALESCE(MAX(id_carro), 0) + 1 as ProximoID FROM Carros",
        Rows
    ),
    Rows = [row(ProximoID)].


carAlreadyExists(Connection, Placa, ConfCarro) :-
    carroPorPlaca(Connection, Placa, Carro),
    length(Carro, ConfCarro).


createCar(Connection, Marca, Modelo, Ano, Placa, Categoria, Diaria, Descricao) :-
    carAlreadyExists(Connection, Placa, CarroExiste),
    (CarroExiste =:= 0 -> 
        getProximoIDCarro(Connection, Id),
        db_parameterized_query_no_return(
            Connection,
            "INSERT INTO carros (id_carro, marca, modelo, ano, placa, categoria, status, quilometragem, diaria_carro, descricao_carro) 
            VALUES ( %w, '%w', '%w', %w, '%w', '%w', '%w', %w, %w, '%w');",
            [Id, Marca, Modelo, Ano, Placa, Categoria, "A", 0.0, Diaria, Descricao]
            ),
        writeln("\nCadastro realizado com sucesso! \nInformações do carro cadastrado:\n"),
        format("|ID:        ~w \n|Marca:     ~w \n|Modelo:    ~w \n|Ano:       ~w \n|Placa:     ~w \n|Categoria: ~w \n|Diária:    ~w \n|Descrição: ~w \n ", 
                [Id, Marca, Modelo, Ano, Placa, Categoria, Diaria, Descricao])
    ;
    writeln("\nEsse carro já foi cadastrado no sistema! Tente novamente.")
    ).

%diz se o carro esta para reparo ou não 
carroPraReparo(Connection, ID) :-
    db_parameterized_query(
        Connection, 
        "SELECT id_carro FROM carros WHERE status = 'R' and id_carro = %w",
        [ID], 
        [row(Count)]),
    (Count > 0).
    
