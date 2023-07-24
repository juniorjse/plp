{-# LANGUAGE OverloadedStrings #-}

module LocalDB.ConnectionDB where

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
                \quilometragem DOUBLE PRECISION NOT NULL);"
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

iniciandoDatabase :: IO Connection
iniciandoDatabase = do
  c <- connectionMyDB
  createUsuarios c
  createCarros c
  createAlugueis c
  createLocadora c
  return c
