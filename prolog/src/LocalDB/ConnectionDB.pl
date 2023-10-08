:- module(connectiondb, [
    iniciandoDatabase/1,
    encerrandoDatabase/1,
    createUsuarios/1,
    createCarros/1,
    createAlugueis/1,
    createLocadora/1,
    createVerificaTempoAluguel/1
]).

:- use_module(library(odbc)).

iniciandoDatabase(Connection) :-
    odbc_connect('SWI-Prolog', Connection, []).

encerrandoDatabase(Connection) :-
    odbc_disconnect(Connection).

createUsuarios(Connection) :-
    odbc_query(Connection,
        "CREATE TABLE IF NOT EXISTS USUARIOS (
            id_usuario SERIAL PRIMARY KEY,
            nome VARCHAR(100) NOT NULL,
            spbrenome VARCHAR(100) NOT NULL,
            email VARCHAR(100) NOT NULL,
            senha VARCHAR(100) NOT NULL,
            tipo VARCHAR(20) DEFAULT 'cliente' NOT NULL,
            CONSTRAINT UNQ_USUARIO_EMAIL UNIQUE (email)
        )", _).

createCarros(Connection) :-
    odbc_query(Connection,
        "CREATE TABLE IF NOT EXISTS Carros (
            id_carro SERIAL PRIMARY KEY,
            marca VARCHAR(100) NOT NULL,
            modelo VARCHAR(100) NOT NULL,
            ano INTEGER NOT NULL,
            placa VARCHAR(20) NOT NULL,
            categoria VARCHAR(100) NOT NULL,
            status VARCHAR(1) NOT NULL,
            quilometragem DOUBLE PRECISION NOT NULL,
            diaria_carro FLOAT NOT NULL,
            descricao_carro TEXT NOT NULL
        )", _).

createAlugueis(Connection) :-
    odbc_query(Connection,
        "CREATE TABLE IF NOT EXISTS Alugueis (
            id_aluguel SERIAL PRIMARY KEY,
            id_carro INTEGER NOT NULL,
            id_usuario INTEGER NOT NULL,
            data_inicio DATE NOT NULL,
            data_devolucao DATE NOT NULL,
            valor_total DOUBLE PRECISION NOT NULL,
            status_aluguel VARCHAR(100) NOT NULL,
            FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
        )", _).

createLocadora(Connection) :-
    odbc_query(Connection,
        "CREATE TABLE IF NOT EXISTS Locadora (
            id_locadora SERIAL PRIMARY KEY,
            nome VARCHAR(100) NOT NULL,
            endereco VARCHAR(200) NOT NULL,
            contato VARCHAR(100) NOT NULL
        )", _).

createVerificaTempoAluguel(Connection) :-
    odbc_query(Connection,
        "CREATE OR REPLACE FUNCTION verificaTempoAluguel(aluguel_id INT) \
        RETURNS INT AS $$ \
        DECLARE \
            data_inicio_aluguel DATE; \
            duracao INT; \
        BEGIN \
            SELECT data_inicio INTO data_inicio_aluguel FROM alugueis WHERE id_aluguel = aluguel_id; \
            duracao := (SELECT DATE_PART('day', NOW() - data_inicio_aluguel)::INT); \
            IF duracao > 1 THEN \
                RETURN 1; \
            ELSE \
                RETURN 0; \
            END IF; \
        END; \
        $$ LANGUAGE plpgsql;", _).