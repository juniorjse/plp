{-# LANGUAGE OverloadedStrings #-}

module Controller.Mecanica where
import Database.PostgreSQL.Simple
import Data.Text as T

menuMecanica :: Connection -> IO ()
menuMecanica conn = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Carros aguardando reparo"
    putStrLn "2. Marcar reparo como finalizado"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> do
            listarCarros conn
            menuMecanica conn
        "2" -> do
            finalizarReparo conn
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
    let texto = T.unpack (T.justifyLeft 15 ' ' marca) ++ T.unpack (T.justifyLeft 10 ' ' modelo) ++ show ano ++ "    " ++ T.unpack (T.justifyLeft 10 ' ' placa) ++ show id_carro
    putStrLn texto
    carrosParaReparo conn t

chamaCarros :: Connection -> IO [(Int, Text, Text, Int, Text )]
chamaCarros conn = do
    rows <- query_ conn "SELECT id_carro, modelo, marca, ano, placa FROM carros WHERE status='R';"
    return [(id_carro, modelo, marca, ano, placa) | (id_carro, modelo, marca, ano, placa) <- rows]



finalizarReparo :: Connection -> IO ()
finalizarReparo conn = do
    listarCarros conn
    putStrLn "Nos informe o ID do carro a fim de ser finalizado o reparo:"
    carroIdStr <- getLine
    let carroId = read carroIdStr :: Int

    [Only carro] <- query conn "SELECT COUNT(*) FROM carros WHERE id_carro = ? AND status = 'R'" (Only carroId)
    let emReparo = carro /= (0 :: Int)

    if emReparo
        then do
            putStrLn "Há algum valor a ser pago para o reparo?"
            valorReparoStr <- getLine
            let valorReparo = read valorReparoStr :: Double

            [Only aluguel] <- query conn "SELECT id_aluguel FROM Alugueis WHERE id_carro = ? AND status_aluguel = 'ativo'" (Only (carroId :: Int))

            execute conn "UPDATE Alugueis SET valor_total = valor_total + ? WHERE id_aluguel = ?" (valorReparo :: Double, aluguelId :: Int)

            execute conn "UPDATE Alugueis SET status_aluguel = 'Concluído' WHERE id_carro = ? AND status_aluguel = 'ativo'" (Only carroId)

            execute conn "UPDATE Carros SET status = 'D' WHERE id_carro = ?" (Only carroId)

            if valorReparo > 0
                then putStrLn "Valor do reparo computado."
                else putStrLn "Reparo finalizado com sucesso!"

        else putStrLn "O carro buscado não existe ou não está em reparo."