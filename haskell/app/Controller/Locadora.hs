{-# LANGUAGE OverloadedStrings #-}

module Controller.Locadora where
import Database.PostgreSQL.Simple

menuLocadora :: Connection -> IO ()
menuLocadora conn = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Cadastrar carro"
    putStrLn "2. Remover Carro"
    putStrLn "3. Registrar Devolução"
    putStrLn "4. Registro de Aluguéis por pessoa"
    putStrLn "5. Dashboard"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> do
            putStrLn "Teste1"
            menuLocadora conn
        "2" -> do
          putStrLn "Teste2"
          menuLocadora conn
        "3" -> do
          menuLocadora conn
        "4" -> do
          putStrLn "Teste4"
          menuLocadora conn
        "5" -> do
          putStrLn "Teste5"
          menuLocadora conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuLocadora conn
