{-# LANGUAGE OverloadedStrings #-}
module Controller.User where
import Data.Maybe (fromJust)
import System.IO.Unsafe
import Data.IORef
import Database.PostgreSQL.Simple
import System.IO
import Control.Exception
import Control.Exception (catch, SomeException)
import Data.Maybe (listToMaybe)
import Data.Int (Int64)
import Database.PostgreSQL.Simple.ToField (ToField (..))
import System.Console.ANSI
import Controller.Locadora 
import Controller.Mecanica 

data UsuarioExistenteException = UsuarioExistenteException
    deriving (Show)

type UserID = Integer

userIdRef :: IORef (Maybe UserID)
userIdRef = unsafePerformIO (newIORef Nothing)
{-# NOINLINE userIdRef #-}

instance Exception UsuarioExistenteException

clearScreenOnly :: IO ()
clearScreenOnly = do
    clearScreen
    setCursorPosition 0 0
    return ()

menu :: Connection -> IO ()
menu conn = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Logar"
    putStrLn "2. Cadastrar"
    putStrLn "3. Remover Carro"
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
    
menuCliente :: Connection -> UserID -> IO ()
menuCliente conn userId = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Listar carros por categoria"
    putStrLn "2. Realizar aluguel"
    putStrLn "3. Cancelar aluguel"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> do
            clearScreenOnly
            putStrLn "Opções de Categoria:"
            putStrLn "1. Econômico"
            putStrLn "2. Intermediário"
            putStrLn "3. SUV"
            putStrLn "4. Luxo"
            putStrLn ""
            putStrLn "Escolha a categoria de carro desejada (1/2/3/4): "
            categoria <- getLine

            case categoria of
                "1" -> listarCarrosPorCategoria conn "Econômico"
                "2" -> listarCarrosPorCategoria conn "Intermediário"
                "3" -> listarCarrosPorCategoria conn "SUV"
                "4" -> listarCarrosPorCategoria conn "Luxo"
                "5" -> listarCarrosPorCategoria conn "Minivan"
                "6" -> listarCarrosPorCategoria conn "Sedan"
                "7" -> listarCarrosPorCategoria conn "Conversível"
                "8" -> listarCarrosPorCategoria conn "Esportivo"
                "9" -> listarCarrosPorCategoria conn "Pickup"
                "10" -> listarCarrosPorCategoria conn "Elétrico"
                _   -> putStrLn "Opção inválida. Por favor, escolha uma categoria válida."
            menuCliente conn userId

        "2" -> do
            putStrLn "ID do carro:"
            carroId <- getLine
            realizarAluguel conn userId carroId
        "3" -> cancelarAluguel conn userId
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuCliente conn userId

login :: Connection -> String -> String -> IO ()
login conn email senha = do
    maybeUserTuple <- buscarUsuarioPorEmailSenha conn email senha
    putStrLn ""

    case maybeUserTuple of
        Just (nome, sobrenome, tipo) -> do
            clearScreenOnly  
            putStrLn "Bem-vindo!"
            putStrLn $ "Nome: " ++ nome ++ " " ++ sobrenome
            setUserID conn email
            maybeUserId <- readIORef userIdRef
            case maybeUserId of
                Just userId ->
                    if tipo == "administrador"
                        then menuLocadora conn
                        else if tipo == "mecanico"
                            then menuMecanica conn
                            else menuCliente conn userId
                Nothing -> putStrLn "UserID não encontrado."
        Nothing -> do
            clearScreenOnly
            putStrLn "E-mail ou senha incorretos."
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

buscarUsuarioPorEmailSenha :: Connection -> String -> String -> IO (Maybe (String, String, String))
buscarUsuarioPorEmailSenha conn email senha = do
    users <- query conn "SELECT nome, sobrenome, tipo FROM USUARIOS WHERE email = ? AND senha = ?" (email, senha)
    return $ listToMaybe users

usuarioComEmailCadastrado :: Connection -> String -> IO Bool
usuarioComEmailCadastrado conn email = do
    [Only count] <- query conn "SELECT COUNT(*) FROM USUARIOS WHERE email = ?" (Only email)
    return (count /= (0 :: Int))
