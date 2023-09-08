{-# LANGUAGE OverloadedStrings #-}
module Controller.Carros where
import Database.PostgreSQL.Simple
import System.IO
import Data.Maybe (listToMaybe)
import qualified Data.Text as T


registrarCarro :: Connection -> IO ()
registrarCarro conn = do
    putStrLn "Digite as informações do carro."
    putStrLn "Marca:"
    marca <- getLine
    putStrLn "Modelo:"
    modelo <- getLine
    putStrLn "Ano:"
    ano <- getLine
    putStrLn "Placa:"
    placa <- getLine
    putStrLn "Categoria:"
    categoria <- getLine
    putStrLn "Diária:"
    diaria <- getLine
    putStrLn "Descrição:"
    descricao <- getLine
    putStrLn ""
    confirmacao <- confirma conn

    if null modelo || null ano || null placa || null categoria
        then do
            putStrLn "Campos não podem ser nulos. Por favor, preencha todos os campos."
            registrarCarro conn
    -- cancelou o cadastro:
    else if not confirmacao 
        then do
            putStrLn "O cadastro foi cancelado."
            -- VOLTAR PRO MENU
    -- verifica existencia do carro no bd:
    else do 
        carroExiste <- carroJaCadastrado conn placa 
        if carroExiste 
            then do
                putStrLn "Esse carro já foi cadastrado no sistema. Tente novamente."
                registrarCarro conn
            else do
                execute conn "INSERT INTO Carros (marca, modelo, ano, placa, categoria, quilometragem, status, diaria_carro, descricao_carro) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)" (marca, modelo, ano, placa, categoria, 0.0 :: Double, "A" :: String, diaria, descricao)
                putStrLn "Cadastro realizado com sucesso! Informações do carro cadastrado:"
                putStrLn $ "Marca: \t" ++ marca
                putStrLn $ "Modelo: \t" ++ modelo
                putStrLn $ "Ano: \t" ++ ano
                putStrLn $ "Placa: \t" ++ placa
                putStrLn $ "Categoria: \t" ++ categoria
                putStrLn $ "Diária: \t" ++ diaria
                putStrLn $ "Descrição: \t" ++ descricao
                novoCadastro conn
                
confirma :: Connection -> IO Bool
confirma conn = do
    putStrLn "Tem certeza que deseja cadastrar esse carro? \n 1. Sim \n 2.Não"
    confirmacao <- getLine 
    if confirmacao /= "1" && confirmacao /= "2" 
        then do
            putStrLn "Não foi possível ler a confirmação."
            confirma conn
    else do 
        let count = if confirmacao == "1" then 1 else 0
        return (count /= (0 :: Int))

novoCadastro :: Connection -> IO()
novoCadastro conn = do
    putStrLn "\nDeseja cadastrar outro carro? \n 1. Sim \n 2.Não"
    novoCadastro <- getLine
    case novoCadastro of
        "1" -> registrarCarro conn
        "2" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."


carroJaCadastrado :: Connection -> String -> IO Bool
carroJaCadastrado conn placa = do
    [Only count] <- query conn "SELECT COUNT(*) FROM carros WHERE placa = ?" (Only placa)
    return (count /= (0 :: Int))

mostrarRanking :: Connection -> IO ()
mostrarRanking conn = do
    ordem <- ordemRanking conn
    putStrLn "------------------------Carros mais alugados------------------------"
    putStrLn "     MARCA          MODELO   ANO     PLACA      ALUGUEIS "
    ranking conn ordem 1

ranking :: Connection -> [(Int, Int)] -> Int -> IO ()
ranking _ [] _ = putStrLn "--------------------------------------------------------------------"
ranking conn ((id, qtd):t) cont = do
    [Only marca]    <- query conn "SELECT marca FROM carros WHERE id_carro = ?"              (Only id)
    [Only modelo]   <- query conn "SELECT modelo FROM carros WHERE id_carro = ?"             (Only id)
    [Only ano]      <- query conn "SELECT CAST(ano AS TEXT) FROM carros WHERE id_carro = ?"  (Only id)
    [Only placa]    <- query conn "SELECT placa FROM carros WHERE id_carro = ?"              (Only id)
    let texto = T.pack(show cont ++ "º: " ++ T.unpack(T.justifyLeft 15 ' ' (T.pack marca)) ++ T.unpack(T.justifyLeft 10 ' ' (T.pack modelo)) ++ ano ++ "    " ++ placa ++ "    ")
    putStrLn (T.unpack(T.justifyLeft 45 ' ' texto) ++ "Alugado " ++ show qtd ++ " vezes.")
    ranking conn t (cont + 1)

ordemRanking :: Connection -> IO [(Int, Int)]
ordemRanking conn = do
    rows <- query_ conn "SELECT id_carro, COUNT(*) as quantidade_alugueis FROM Alugueis GROUP BY id_carro ORDER BY quantidade_alugueis DESC;"
    return [(id_carro, quantidade_alugueis) | (id_carro, quantidade_alugueis) <- rows]
