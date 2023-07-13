:- module(usuarios, [solicitarCadastro/0, login/0, menu/0, usuario/4]).
:- use_module(library(odbc)).
:- use_module('./localdb/connectiondb').
:- use_module('./localdb/dbop').
:- use_module('./localdb/user_operations').

menu :-
    writeln(''),
    writeln('Menu:'),
    writeln('1. Logar'),
    writeln('2. Cadastrar'),
    writeln('0. Sair'),
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
    connectiondb:iniciandoDatabase(Connection),
    writeln(''),
    writeln('Digite o seu e-mail:'),
    read_line_to_string(user_input, Email),
    writeln('Digite a sua senha:'),
    read_line_to_string(user_input, Senha),
    authenticate(Connection, Email, Senha, Autenticado),
    ( Autenticado =:= 1 ->
        getUser(Connection, Email, Senha, User),
        writeln('Login bem sucessido!'),
        menu;
        writeln(''),
        writeln('E-mail ou senha inválidos!'),
        menu
    ).


authenticate(Connection, Email, Senha, Autenticado) :-
    getUser(Connection, Email, Senha, User),
    ( User = [] ->
        Autenticado is 0 ; % Usuário não encontrado
        Autenticado is 1 % Senha correta
    ).

solicitarCadastro :-
    writeln(''),
    writeln('Digite o seu nome:'),
    read_line_to_string(user_input, Nome),
    writeln('Digite o seu sobrenome:'),
    read_line_to_string(user_input, Sobrenome),
    writeln('Digite o seu e-mail:'),
    read_line_to_string(user_input, Email),
    writeln('Digite a sua senha (tem que ter no mínimo 8 caracteres):'),
    writeln(''),
    read_line_to_string(user_input, Senha),

    createUser(Email, Senha, Nome, Sobrenome, Confirmacao),
    (Confirmacao =:= 1 ->
        writeln('Usuário cadastrado com sucesso!'),
        menu;
        writeln('E-mail já existente, tente realizar o login ou utilizar um e-mail diferente.'),
        menu
    ).

createUser(Email, Senha, Nome, Sobrenome, Confirmacao) :-
    connectiondb:iniciandoDatabase(Connection),
    userAlreadyExists(Connection, Email, Fstconf),
    (
        Fstconf =:= 0 ->
            format(string(Query), "INSERT INTO usuarios (nome, sobrenome, email, senha) VALUES ('~w', '~w', '~w', '~w')",
                [Nome, Sobrenome, Email, Senha]),
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
