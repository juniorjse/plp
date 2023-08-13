:- module(user_operations, [createUser/6, getUserByEmail/3, getUser/4, userAlreadyExists/3, getusuariosByEmail/4]).
:- use_module(library(odbc)).
:- use_module('./util.pl').
:- use_module('./dbop.pl').


createUser(Connection, Email, Senha, Nome, Sobrenome, Confirmacao):-
    userAlreadyExists(Connection, Email, Fstconf),
    ( Fstconf =:= 0 ->
        db_parameterized_query_no_return(
            Connection, 
            "INSERT INTO usuarios (nome, sobrenome, email, senha) values ('%w','%w','%w','%w');",
            [ Nome, Sobrenome, Email, Senha]),
        Confirmacao is 1;
        Confirmacao is 0).


getUserByEmail(Connection, Email, User):-
    Q = "SELECT * FROM usuarios WHERE email = '%w'",
    db_parameterized_query(Connection, Q, [Email], User).

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