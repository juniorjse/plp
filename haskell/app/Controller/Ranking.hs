{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use sortOn" #-}
module Controller.Ranking where
import Database.PostgreSQL.Simple
import System.IO
import Data.List
import Data.Ord (comparing)
import Control.Monad (liftM)

mostrarRanking :: Connection -> IO ()
mostrarRanking conn = do
    ordem <- ordemRanking conn
    putStrLn "---------------Carros mais alugados---------------"
    ranking conn ordem 1

ranking :: Connection -> [(Int, Int)] -> Int -> IO ()
ranking _ [] _ = putStrLn "--------------------------------------------------"
ranking conn ((id, qtd):t) cont = do
    [Only marca]    <- query conn "SELECT marca FROM carros WHERE id_carro = ?"              (Only id)
    [Only modelo]   <- query conn "SELECT modelo FROM carros WHERE id_carro = ?"             (Only id)
    [Only ano]      <- query conn "SELECT CAST(ano AS TEXT) FROM carros WHERE id_carro = ?"  (Only id)
    [Only placa]    <- query conn "SELECT placa FROM carros WHERE id_carro = ?"              (Only id)
    putStrLn (show cont ++ "º: " ++ marca ++ ", " ++ modelo ++ ", " ++ ano ++ ", " ++ placa ++ "." ++ "\t Alugado " ++ show qtd ++ " vezes.")
    ranking conn t (cont + 1)

ordemRanking :: Connection -> IO [(Int, Int)]
ordemRanking conn = do
    rows <- query_ conn "SELECT id_carro, COUNT(*) as quantidade_alugueis FROM Alugueis GROUP BY id_carro ORDER BY quantidade_alugueis DESC;"
    return [(id_carro, quantidade_alugueis) | (id_carro, quantidade_alugueis) <- rows]
