{-# LANGUAGE OverloadedStrings #-}
module Controller.User where
import Database.PostgreSQL.Simple
import System.IO
import Control.Exception

data UsuarioExistenteException = UsuarioExistenteException
    deriving (Show)

instance Exception UsuarioExistenteException

menu :: Connection -> IO ()
menu conn = do
    putStrLn "Menu:"
    putStrLn "1. Logar"
    putStrLn "2. Cadastrar"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    case opcao of
        "1" -> do
            putStrLn "Digite o e-mail:"
            email <- getLine
            putStrLn "Digite a senha:"
            senha <- getLine

            login conn email senha
        "2" -> solicitarCadastro conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menu conn

solicitarCadastro :: Connection -> IO ()
solicitarCadastro conn = do
    putStrLn "Digite o nome:"
    nome <- getLine
    putStrLn "Digite o sobrenome:"
    sobrenome <- getLine
    putStrLn "Digite o e-mail:"
    email <- getLine
    putStrLn "Digite a senha (mínimo de 7 caracteres):"
    senha <- getLine

    if null nome || null sobrenome || null email || null senha
        then do
            putStrLn "Campos não podem ser nulos. Por favor, preencha todos os campos."
            solicitarCadastro conn
        else if length senha < 7
            then do
                putStrLn "A senha deve ter no mínimo 7 caracteres."
                solicitarCadastro conn
            else do
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
                        menu conn

            

login :: Connection -> String -> String -> IO ()
login conn email senha = do
    usuario <- buscarUsuarioPorEmailSenha conn email senha
    case usuario of
        Just (nome, sobrenome) -> do
            putStrLn $ "Bem-vindo, " ++ nome ++ " " ++ sobrenome ++ "!"
            -- Realizar as ações após o login
        Nothing -> do
            putStrLn "E-mail ou senha incorretos."
            menu conn

buscarUsuarioPorEmailSenha :: Connection -> String -> String -> IO (Maybe (String, String))
buscarUsuarioPorEmailSenha conn email senha = do
    [user] <- query conn "SELECT nome, sobrenome FROM USUARIOS WHERE email = ? AND senha = ?" (email, senha)
    return user

usuarioComEmailCadastrado :: Connection -> String -> IO Bool
usuarioComEmailCadastrado conn email = do
    [Only count] <- query conn "SELECT COUNT(*) FROM USUARIOS WHERE email = ?" (Only email)
    return (count /= (0 :: Int))
