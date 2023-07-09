{-# LANGUAGE OverloadedStrings #-}
module LocalDB.ConnectionDB where
import Database.PostgreSQL.Simple

localDB:: ConnectInfo
localDB = defaultConnectInfo {
    connectHost = "localhost",
    connectDatabase = "plp_app",
    connectUser = "postgres",
    connectPassword = "plp123",
    connectPort = 5433
}

connectionMyDB :: IO Connection
connectionMyDB = connect localDB

createUsuarios :: Connection -> IO()
createUsuarios conn = do
    execute_ conn "CREATE TABLE IF NOT EXISTS USUARIOS (\
                    \NOME VARCHAR(100) NOT NULL,\
                    \SOBRENOME VARCHAR(100) NOT NULL,\
                    \EMAIL VARCHAR(100) NOT NULL,\
                    \SENHA VARCHAR(100) NOT NULL,\
                    \CONSTRAINT PK_USUARIO PRIMARY KEY(EMAIL));"
    return ()

iniciandoDatabase :: IO Connection
iniciandoDatabase = do
  c <- connectionMyDB
  createUsuarios c
  return c