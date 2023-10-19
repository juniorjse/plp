:- module(usuarios, [solicitarCadastro/0, login/0, menu/0, usuario/4, menuCliente/0]).
:- use_module(library(odbc)).
:- use_module('./localdb/connectiondb').
:- use_module('./localdb/dbop').
:- use_module('./localdb/user_operations').
:- use_module('./Locadora').
:- use_module('./Mecanica').
:- dynamic(current_user_id/1).
current_user_id(0).

menu :-
    writeln(''),
    writeln('|------------------|'),
    writeln('|       MENU       |'),
    writeln('|------------------|'),
    writeln('|1. Logar          |'),
    writeln('|2. Cadastrar      |'),
    writeln('|0. Sair           |'),
    writeln(''),
    writeln('Escolha uma opção:'),
    read_line_to_string(user_input, Opcao),
    escolherOpcao(Opcao).

escolherOpcao("1") :-
    login.

escolherOpcao("2") :-
    solicitarCadastro.

escolherOpcao("0") :-
    writeln('Saindo...'),
    writeln(''),
    halt.

escolherOpcao(_) :-
    writeln('Opção inválida. Por favor, escolha novamente.'),
    menu.

login :-
    iniciandoDatabase(Connection),
    writeln(''),
    writeln('Digite o seu e-mail:'),
    read_line_to_string(user_input, Email),
    writeln('Digite a sua senha:'),
    read_line_to_string(user_input, Senha),
    authenticate(Connection, NomeUsuario, Email, Senha, TipoUsuario, UserID, Autenticado),
    ( Autenticado =:= 1 ->
        format('Seja bem-vindo, ~w\n', [NomeUsuario]),
        (TipoUsuario = 'administrador' ->
            menuLocadora
        ; TipoUsuario = 'mecanico' ->
            menuMecanica
        ; 
            menuCliente
        )
    ;
        writeln(''),
        writeln('E-mail ou senha inválidos!'),
        menu
    ).

authenticate(Connection, NomeUsuario, Email, Senha, TipoUsuario, UserID, Autenticado) :-
    getUser(Connection, Email, Senha, User),
    (User = [Row|_],
     Row = row(UserID, NomeUsuario, _, _, _, TipoUsuario) ->
        Autenticado = 1,
        asserta(current_user_id(UserID)) % Armazena o ID do usuário
    ;
        Autenticado = 0,
        NomeUsuario = none,
        TipoUsuario = none
    ).

menuCliente :-
    writeln(''),
    writeln('|------------------------------------|'),
    writeln('|            MENU CLIENTE            |'),
    writeln('|------------------------------------|'),
    writeln('|1. Listar carros por categoria      |'),
    writeln('|2. Realizar aluguel                 |'),
    writeln('|3. Cancelar aluguel                 |'),
    writeln('|4. Ranking de Carros Mais Alugados  |'),
    writeln('|0. Sair                             |'),
    writeln(''),
    writeln('Escolha uma opção:'),

    read_line_to_string(user_input, Opcao),
    writeln(''),

    (Opcao = "1" -> listarCarrosPorCategoria(Connection), menuCliente;
     Opcao = "2" -> 
        realizarAluguel(Connection),
        menuCliente;
     Opcao = "3" -> cancelarAluguel, menuCliente;
     Opcao = "4" -> rankingCarrosMaisAlugados, menuCliente;
     Opcao = "0" -> writeln('Saindo...\n'), halt;
        writeln('Opção inválida. Por favor, escolha novamente.'), menuCliente).

solicitarCadastro :-
    writeln(''),
    writeln('Digite o seu nome:'),
    read_line_to_string(user_input, Nome),
    writeln('Digite o seu sobrenome:'),
    read_line_to_string(user_input, Sobrenome),
    writeln('Digite o seu e-mail:'),
    read_line_to_string(user_input, Email),
    writeln('Digite a sua senha (tem que ter no mínimo 7 caracteres):'),
    read_line_to_string(user_input, SenhaString),    
    writeln('Digite a senha novamente:'),
    read_line_to_string(user_input, Senha2),
    writeln(''),

    string_chars(SenhaString, Senha),
    (
        (Nome = "" ; Sobrenome = "" ; Email = "" ; Senha = []) ->
            writeln('Nenhum campo (sobrenome, nome, email, senha) pode estar vazio. Por favor, tente novamente.'),
            solicitarCadastro
        ;
        (SenhaString \== Senha2) ->
            writeln('As senhas são diferentes. Por favor, tente novamente.'),
            solicitarCadastro
        ;
        length(Senha, Length),
        (
            Length < 7 ->
                writeln('A senha precisa ter no mínimo 7 caracteres. Por favor, tente novamente.'),
                solicitarCadastro
        ;
            createUser(Email, Senha, Nome, Sobrenome, Confirmacao),
            (
                Confirmacao =:= 1 ->
                    writeln('Usuário cadastrado com sucesso!'),
                    menu
                ;
                    writeln('Usuário com e-mail já cadastrado. Por favor, forneça um e-mail diferente.'),
                    menu
            )
        )
    ).

createUser(Email, Senha, Nome, Sobrenome, Confirmacao) :-
    connectiondb:iniciandoDatabase(Connection),
    userAlreadyExists(Connection, Email, Fstconf),
    (
        Fstconf =:= 0 ->
            string_chars(SenhaString, Senha), % Converte a lista de caracteres em string
            format(string(Query), "INSERT INTO usuarios (nome, sobrenome, email, senha) VALUES ('~w', '~w', '~w', '~w')",
                [Nome, Sobrenome, Email, SenhaString]), % Use SenhaString na consulta
            dbop:db_query_no_return(Connection, Query),
            Confirmacao is 1
        ;
            Confirmacao is 0
    ),
    connectiondb:encerrandoDatabase(Connection).

usuario(Email, Senha, Nome, Sobrenome) :-
    connectiondb:iniciandoDatabase(Connection),
    dbop:db_parameterized_query(Connection, 'SELECT COUNT(*) FROM usuarios WHERE email = ? AND senha = ?', [Email, Senha], [row(Count)]),
    (
        Count > 0,
        dbop:db_parameterized_query(Connection, 'SELECT nome, sobrenome FROM usuarios WHERE email = ?', [Email], [row(Nome, Sobrenome)])
    ),
    connectiondb:encerrandoDatabase(Connection).


authenticateCar(Connection, CarroID, DiariaCarro, Autenticado) :-
    getCarro(Connection, CarroID, CarroInfo),
    (CarroInfo = [row(_, _, _, _, _, _, _, _, DiariaCarro, _)] ->
        Autenticado = 1
    ;
        Autenticado = 0
    ).

realizarAluguel(Connection) :-
    current_user_id(UserID),
    iniciandoDatabase(Connection),
    writeln(''),
    writeln('Digite o ID do carro:'),
    read_line_to_string(user_input, CarroIDStr),
    atom_number(CarroIDStr, CarroID),

    writeln('Digite a quantidade de dias que deseja alugar:'),
    read_line_to_string(user_input, DiasAluguelStr),
    atom_number(DiasAluguelStr, DiasAluguel), % Converter os dias para número

    authenticateCar(Connection, CarroID, DiariaCarro, Autenticado),

    ( Autenticado =:= 1 ->
        ValorTotal is DiariaCarro * DiasAluguel,
        writeln(''),
        format('Valor Total: ~w\n', [ValorTotal]),
        writeln(''),
        writeln('Deseja confirmar o aluguel desse carro?'),
        writeln('1. Sim'),
        writeln('2. Não'),
        read_line_to_string(user_input, ConfirmaComNL), 
        atom_chars(ConfirmaComNL, [ConfirmaChar|_]),

        (ConfirmaChar = '1' ->
            writeln(''),
            alugar(Connection, UserID, CarroID, DiasAluguel, ValorTotal),
            writeln('Aluguel realizado com sucesso!')
        ;
            writeln(''),
            writeln('Aluguel cancelado.')
        )

    ;
        writeln('Carro não encontrado.')
    ).

rankingCarrosMaisAlugados :-
    writeln("|--------------------------------------------------------------------------------------|"),
    writeln("|                                  RANKING DE CARROS                                   |"),
    writeln("|--------------------------------------------------------------------------------------|"),
    connectiondb:iniciandoDatabase(Connection),
    user_operations:carrosPorPopularidade(Connection,ListaCarros),
    mostraCarros(ListaCarros),
    writeln("|--------------------------------------------------------------------------------------|\n\n\n"),
    connectiondb:encerrandoDatabase(Connection),
    menuMecanica.

mostraCarros([]).  
mostraCarros([row(Marca, Modelo, Ano, Placa, Alugueis) | Outros]) :-
    format('|Marca:~t ~w ~t~22+ Modelo:~t ~w ~t~21+ Ano:  ~w   Placa:  ~w   Alugueis:  ~w|~n',[ Marca, Modelo, Ano, Placa, Alugueis]),
    mostraCarros(Outros).

