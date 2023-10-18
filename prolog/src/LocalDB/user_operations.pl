:- module(user_operations, [createUser/6, getUserByEmail/3, getTipoByEmail/3, getUser/4, userAlreadyExists/3, getusuariosByEmail/4,
                            createCar/8, carroPorPlaca/3, carAlreadyExists/3, getProximoIDCarro/2, consultarCarrosPraReparo/2]).
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


getusuariosByEmail(Connection, [ Email | T ], usuariosTemp, usuarios):-
    length(T, L),
    (L > 0 ->
        getUserByEmail(Connection, Email, User),
        getusuariosByEmail(Connection, T, [ User | usuariosTemp ], usuarios) ;
        getUserByEmail(Connection, Email, User),
        reverse([ User | usuariosTemp ], usuarios)
    ).
createUser(Connection, Email, Senha, Nome, Sobrenome, Confirmacao):-
    userAlreadyExists(Connection, Email, Fstconf),
    ( Fstconf =:= 0 ->
        db_parameterized_query_no_return(
            Connection, 
            "INSERT INTO usuarios (nome, sobrenome, email, senha) values ('%w','%w','%w','%w');",
            [ Nome, Sobrenome, Email, Senha]),
        Confirmacao is 1;
        Confirmacao is 0).
alugar(Connection, UserID, CarroID, DiasAluguel, ValorTotal) :-
    db_parameterized_query_no_return(
        Connection, 
        "INSERT INTO Alugueis (id_carro, id_usuario, data_inicio, data_devolucao, valor_total, status_aluguel) VALUES (%w, %w, CURRENT_DATE, CURRENT_DATE + interval '%w day', %w, 'ativo');",
        [CarroID, UserID, DiasAluguel, ValorTotal]
    ),
    % Atualizar o status do carro para 'O' (ou o status apropriado) na tabela "carros"
    db_parameterized_query_no_return(
        Connection, 
        "UPDATE carros SET status = 'O' WHERE id_carro = %w;",
        [CarroID]
    ).

getCarro(Connection, CarroID, CarroInfo) :-
    Q = "SELECT * FROM carros WHERE id_carro = '%w'",
    db_parameterized_query(Connection, Q, [CarroID], CarroInfo).

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

