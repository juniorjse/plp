{-# LANGUAGE OverloadedStrings #-}

module Controller.Locadora where

import Database.PostgreSQL.Simple
import Data.Time
import Data.Time.Format
import Controller.Mecanica
import Control.Exception

data LocadoraExistenteException = LocadoraExistenteException
    deriving (Show)

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
            registraDevolucao conn
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

registraDevolucao :: Connection -> IO ()
registraDevolucao conn = do
    putStrLn "Digite o número do contrato/ Id do aluguel a ser encerrado:"
    numContratoStr <- getLine
    let numContrato = read numContratoStr :: Integer
    maybeAluguel <- buscarAluguel conn numContrato
    case maybeAluguel of
        [] -> do
            putStrLn "Aluguel não encontrado."
            putStrLn "1. Para digitar novamente"
            putStrLn "2. Para voltar ao menu inicial"
            opcao <- getLine
            case opcao of
                "1" -> registraDevolucao conn
                "2" -> menuLocadora conn
                _ -> do
                    putStrLn "Opção inválida. Você será direcionado(a) ao menu inicial."
                    menuLocadora conn
        [(data_inicio, data_devolucao, id_carro)] -> do
            printAluguel conn (data_inicio, data_devolucao, id_carro)


buscarAluguel :: Connection -> Integer -> IO [(String, String, Integer)]
buscarAluguel conn numContrato = do
    query conn "SELECT data_inicio, data_devolucao, id_carro FROM Alugueis WHERE id_aluguel = ? AND status_aluguel = 'ativo'" (Only numContrato)

buscarCarro :: Connection -> Integer -> IO ()
buscarCarro conn id_carro = do
    putStrLn ""
    putStrLn $ "Detalhes do carro com ID '" ++ show id_carro ++ "':"
    carro <- query conn "SELECT marca, modelo, ano FROM Carros WHERE id_carro = ?" (Only id_carro)
    
    if null carro
        then putStrLn $ "Carro com ID '" ++ show id_carro ++ "' não encontrado."
        else printCarroLocadora (head carro)
    

printAluguel :: Connection -> (String, String, Integer) -> IO ()
printAluguel conn (data_inicio, data_devolucao, id_carro) = do
    putStrLn "Carro Alugado: "
    buscarCarro conn id_carro
    putStrLn $ "Data de início do aluguel: " ++ data_inicio ++ ", Data de devolução: " ++ data_devolucao

printCarroLocadora :: (String, String, Int) -> IO ()
printCarroLocadora (marca, modelo, ano) = do
    putStrLn $ "Marca: " ++ marca ++ ", Modelo: " ++ modelo ++ ", Ano: " ++ show ano