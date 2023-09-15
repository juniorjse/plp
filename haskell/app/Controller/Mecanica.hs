{-# LANGUAGE OverloadedStrings #-}

module Controller.Mecanica where
import Database.PostgreSQL.Simple

menuMecanica :: Connection -> IO ()
menuMecanica conn = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Mecânica teste1"
    putStrLn "2. Mecânica teste2"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> do
            putStrLn "Teste1"
            menuMecanica conn
        "2" -> do
          putStrLn "Teste2"
          menuMecanica conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuMecanica conn