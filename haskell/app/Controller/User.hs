{-# LANGUAGE OverloadedStrings #-}
module Controller.User where
import Database.PostgreSQL.Simple
import System.IO
import Control.Exception

data UsuarioExistenteException = UsuarioExistenteException
    deriving (Show)

instance Exception UsuarioExistenteException

solicitarCadastro :: Connection -> IO ()
solicitarCadastro conn = do
  
    putStrLn "Digite o nome:"
    nome <- getLine
    putStrLn "Digite o sobrenome:"
    sobrenome <- getLine
    putStrLn "Digite o e-mail:"
    email <- getLine
    putStrLn "Digite a senha:"
    senha <- getLine

    emailExists <- usuarioComEmailCadastrado conn email

    if emailExists
        then do
            putStrLn "Usuário com e-mail já cadastrado. Por favor, forneça um e-mail diferente."
            solicitarCadastro conn
        else do
            execute_ conn "BEGIN"

            execute conn "INSERT INTO USUARIOS (nome, sobrenome, email, senha) VALUES (?, ?, ?, ?)" (nome, sobrenome, email, senha)

            execute_ conn "COMMIT"

            putStrLn "Cadastro realizado com sucesso."

usuarioComEmailCadastrado :: Connection -> String -> IO Bool
usuarioComEmailCadastrado conn email = do
    [Only count] <- query conn "SELECT COUNT(*) FROM USUARIOS WHERE email = ?" (Only email)
    return (count /= (0 :: Int))