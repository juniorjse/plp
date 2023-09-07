{-# LANGUAGE OverloadedStrings #-}

module Controller.Locadora where
import Database.PostgreSQL.Simple

menuLocadora :: Connection -> IO ()
menuLocadora conn = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Cadastrar carro"
    putStrLn "2. Locadora teste1"
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
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuLocadora conn
