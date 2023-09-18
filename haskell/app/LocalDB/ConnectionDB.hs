{-# LANGUAGE OverloadedStrings #-}

module LocalDB.ConnectionDB where
import Control.Monad (void)
import Database.PostgreSQL.Simple

localDB :: ConnectInfo
localDB = defaultConnectInfo
  { connectHost = "localhost"
  , connectDatabase = "plp_app"
  , connectUser = "postgres"
  , connectPassword = "plp123"
  , connectPort = 5433
  }

connectionMyDB :: IO Connection
connectionMyDB = connect localDB

createUsuarios :: Connection -> IO ()
createUsuarios conn = do
  execute_ conn "CREATE TABLE IF NOT EXISTS Usuarios (\
                \id_usuario SERIAL PRIMARY KEY,\
                \nome VARCHAR(100) NOT NULL,\
                \sobrenome VARCHAR(100) NOT NULL,\
                \email VARCHAR(100) NOT NULL,\
                \senha VARCHAR(100) NOT NULL,\
                \tipo VARCHAR(20) DEFAULT 'cliente' NOT NULL,\
                \CONSTRAINT UNQ_USUARIO_EMAIL UNIQUE (email));"
  return ()

createCarros :: Connection -> IO ()
createCarros conn = do
  execute_ conn "CREATE TABLE IF NOT EXISTS Carros (\
                \id_carro SERIAL PRIMARY KEY,\
                \marca VARCHAR(100) NOT NULL,\
                \modelo VARCHAR(100) NOT NULL,\
                \ano INTEGER NOT NULL,\
                \placa VARCHAR(20) NOT NULL,\
                \categoria VARCHAR(100) NOT NULL,\
                \status VARCHAR(1) NOT NULL,\
                \quilometragem DOUBLE PRECISION NOT NULL,\
                \diaria_carro float NOT NULL,\
                \descricao_carro text NOT NULL);"
  return ()

createAlugueis :: Connection -> IO ()
createAlugueis conn = do
  execute_ conn "CREATE TABLE IF NOT EXISTS Alugueis (\
                \id_aluguel SERIAL PRIMARY KEY,\
                \id_carro INTEGER NOT NULL,\
                \id_usuario INTEGER NOT NULL,\
                \data_inicio DATE NOT NULL,\
                \data_devolucao DATE NOT NULL,\
                \valor_total DOUBLE PRECISION NOT NULL,\
                \status_aluguel VARCHAR(100) NOT NULL,\
                \FOREIGN KEY (id_carro) REFERENCES Carros (id_carro),\
                \FOREIGN KEY (id_usuario) REFERENCES Usuarios (id_usuario));"
  return ()

createLocadora :: Connection -> IO ()
createLocadora conn = do
  execute_ conn "CREATE TABLE IF NOT EXISTS Locadora (\
                \id_locadora SERIAL PRIMARY KEY,\
                \nome VARCHAR(100) NOT NULL,\
                \endereco VARCHAR(200) NOT NULL,\
                \contato VARCHAR(100) NOT NULL);"
  return ()

createVerificaTempoAluguel :: Connection -> IO ()
createVerificaTempoAluguel conn = do
    void $ execute_ conn $
        "CREATE OR REPLACE FUNCTION verificaTempoAluguel(aluguel_id INT) \
        \RETURNS INT AS $$ \
        \DECLARE \
        \    data_inicio_aluguel DATE; \
        \    duracao INT; \
        \BEGIN \
        \    SELECT data_inicio INTO data_inicio_aluguel FROM alugueis WHERE id_aluguel = aluguel_id; \
        \    duracao := (SELECT DATE_PART('day', NOW() - data_inicio_aluguel)::INT); \
        \    IF duracao > 1 THEN \
        \        RETURN 1; \
        \    ELSE \
        \        RETURN 0; \
        \    END IF; \
        \END; \
        \$$ LANGUAGE plpgsql;"

iniciandoDatabase :: IO Connection
iniciandoDatabase = do
  c <- connectionMyDB
  createUsuarios c
  createCarros c
  createAlugueis c
  createLocadora c
  return c