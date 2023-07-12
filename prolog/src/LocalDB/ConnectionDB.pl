:- module(connectiondb, [
    iniciandoDatabase/1,
    createUsuarios/1
]).

:- use_module(library(odbc)).

iniciandoDatabase(Connection) :-
    odbc_connect('SWI-Prolog', Connection, []).

createUsuarios(Connection) :-
    odbc_query(Connection,
        "CREATE TABLE IF NOT EXISTS USUARIOS (
            NOME VARCHAR(100) NOT NULL,
            SOBRENOME VARCHAR(100) NOT NULL,
            EMAIL VARCHAR(100) NOT NULL,
            SENHA VARCHAR(100) NOT NULL,
            CONSTRAINT PK_USUARIO PRIMARY KEY(EMAIL)
        )", _).
        