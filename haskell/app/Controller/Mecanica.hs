{-# LANGUAGE OverloadedStrings #-}

module Controller.Mecanica where
import Database.PostgreSQL.Simple
import Data.Text as T

menuMecanica :: Connection -> IO ()
menuMecanica conn = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Carros aguardando reparo"
    putStrLn "2. Mecânica teste2"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> do
            listarCarros conn 
            menuMecanica conn
        "2" -> do
          putStrLn "Teste2"
          menuMecanica conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuMecanica conn


listarCarros :: Connection -> IO ()
listarCarros conn = do
    putStrLn "--------------Carros com defeito--------------"
    putStrLn "MARCA          MODELO    ANO     PLACA     ID"
    listaCarros <- chamaCarros conn
    carrosParaReparo conn listaCarros

carrosParaReparo :: Connection -> [(Int, Text, Text, Int, Text)] -> IO ()
carrosParaReparo _ [] = putStrLn "----------------------------------------------"
carrosParaReparo conn ((id_carro, modelo, marca, ano, placa):t) = do
    let texto = T.unpack(T.justifyLeft 15 ' ' marca) ++ T.unpack(T.justifyLeft 10 ' ' modelo) ++ show ano ++ "    " ++ T.unpack(T.justifyLeft 10 ' ' placa) ++ show id_carro
    putStrLn texto
    carrosParaReparo conn t

chamaCarros :: Connection -> IO [(Int, Text, Text, Int, Text )]
chamaCarros conn = do
    rows <- query_ conn "SELECT id_carro, modelo, marca, ano, placa FROM carros WHERE status='R';"
    return [(id_carro, modelo, marca, ano, placa) | (id_carro, modelo, marca, ano, placa) <- rows]

