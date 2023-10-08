:- module(usuarios, [solicitarCadastro/0, login/0, menu/0, usuario/4, menuCliente/0]).
:- use_module(library(odbc)).
:- use_module('./localdb/connectiondb').
:- use_module('./localdb/dbop').
:- use_module('./localdb/user_operations').
:- use_module('./Locadora').
:- use_module('./Mecanica').

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
    writeln('Opção inválida. Por favor, escolha novamenteeeeee.'),
    menu.

login :-
    iniciandoDatabase(Connection),
    writeln(''),
    writeln('Digite o seu e-mail:'),
    read_line_to_string(user_input, Email),
    writeln('Digite a sua senha:'),
    read_line_to_string(user_input, Senha),
    authenticate(Connection, Email, Senha, Autenticado),
    ( Autenticado =:= 1 ->
        writeln('Login bem-sucedido!'),
        menuCliente
    ;
        writeln(''),
        writeln('E-mail ou senha inválidos!')
    ).

redirecionarMenu("administrador") :-
    menuLocadora.

redirecionarMenu("mecanico") :-
    menuMecanico.

redirecionarMenu("cliente") :-
    menuCliente.

authenticate(Connection, Email, Senha, Autenticado) :-
    getUser(Connection, Email, Senha, User),
    ( User = [] ->
        Autenticado is 0 ; % Usuário não encontrado
        Autenticado is 1 % Senha correta
    ).

menuCliente :-
    writeln(''),
    writeln('Menu do Cliente:'),
    writeln('1. Listar carros por categoria'),
    writeln('2. Realizar aluguel'),
    writeln('3. Cancelar aluguel'),
    writeln('4. Ranking de Carros Mais Alugados'),
    writeln('Escolha uma opção:'),

    read_line_to_string(user_input, Opcao), % Leitura da opção do cliente aqui.

    writeln('').

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
