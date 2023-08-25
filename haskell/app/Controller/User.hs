{-# LANGUAGE OverloadedStrings #-}
module Controller.User where
import System.IO.Unsafe
import Data.IORef
import Database.PostgreSQL.Simple
import System.IO
import Control.Exception
import Control.Exception (catch, SomeException)
import Data.Maybe (listToMaybe)
import Controller.Car_register

data UsuarioExistenteException = UsuarioExistenteException
    deriving (Show)

type UserID = Integer

userIdRef :: IORef (Maybe UserID)
userIdRef = unsafePerformIO (newIORef Nothing)
{-# NOINLINE userIdRef #-}

instance Exception UsuarioExistenteException

menu :: Connection -> IO ()
menu conn = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Logar"
    putStrLn "2. Cadastrar"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

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

menuCliente :: Connection -> IO ()
menuCliente conn = do

    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Listar carros"
    putStrLn "2. Realizar aluguel"
    putStrLn "3. Cadastrar carro"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> do
            putStrLn "Opção não implementada"
            menuCliente conn
        "2" -> do
            putStrLn "Opção não implementada"
            menuCliente conn
        "3" -> do
            registrarCarro conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuCliente conn

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
    putStrLn "Digite a senha novamente:"
    confirmaSenha <- getLine

    if null nome || null sobrenome || null email || null senha
        then do
            putStrLn "Campos não podem ser nulos. Por favor, preencha todos os campos."
            solicitarCadastro conn
        else if senha /= confirmaSenha
            then do
                putStrLn "Senhas diferentes. Tente novamente."
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
    putStrLn ""

    case usuario of
        Just (nome, sobrenome) -> do
            putStrLn $ "Bem-vindo, " ++ nome ++ " " ++ sobrenome ++ "!"
            putStrLn $ "Bem-vindo, " ++ nome ++ " " ++ sobrenome ++ "!"
                
            setUserID conn email
            userId <- readIORef userIdRef

            case userId of
                Just uid -> putStrLn $ "Seu ID de usuário é: " ++ show uid
            menuCliente conn
        Nothing -> do
            putStrLn "E-mail ou senha incorretos."
            menu conn

setUserID :: Connection -> String -> IO ()
setUserID conn email = do
    [Only userId] <- query conn "SELECT id_usuario FROM USUARIOS WHERE email = ?" (Only email)
    writeIORef userIdRef (Just (userId :: Integer))
            

buscarUsuarioPorEmailSenha :: Connection -> String -> String -> IO (Maybe (String, String))
buscarUsuarioPorEmailSenha conn email senha = do
    users <- query conn "SELECT nome, sobrenome FROM USUARIOS WHERE email = ? AND senha = ?" (email, senha)
    return $ listToMaybe users

usuarioComEmailCadastrado :: Connection -> String -> IO Bool
usuarioComEmailCadastrado conn email = do
    [Only count] <- query conn "SELECT COUNT(*) FROM USUARIOS WHERE email = ?" (Only email)
    return (count /= (0 :: Int))
