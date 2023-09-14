{-# LANGUAGE OverloadedStrings #-}

module Controller.Locadora where
import Database.PostgreSQL.Simple

menuLocadora :: Connection -> LocadoraID -> IO ()
menuLocadora conn locadoraId = do
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
            menuLocadora conn locadoraId
        "2" -> do
          putStrLn "Teste2"
          menuLocadora conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuLocadora conn locadoraId

registraDevolucao :: Connection -> LocadoraID -> IO ()
registraDevolucao conn locadoraId = do
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
                "1" -> registraDevolucao conn locadoraId
                "2" -> menuLocadora conn locadoraId
                _ -> do
                    putStrLn "Opção inválida. Você será direcionado(a) ao menu inicial."
                    menuLocadora conn locadoraId
        [(data_inicio, data_devolucao, id_carro)] -> do
            printAluguel conn (data_inicio, data_devolucao, id_carro)
            devolucao <- verificaDevolucao data_devolucao
            case (devolucao :: String) of
              "Devolução dentro do prazo" -> do
                valor <- calculaValor numContrato
                print valor
              "Devolução adiantada" -> do
                putStrLn "Motivo da devolução adiantada:"
                putStrLn "1. Problema no carro"
                putStrLn "2. Outro motivo"
                motivo <- getLine
                case motivo of
                    "1" -> do
                        mecanico <- enviaParaMecanico conn id_carro numContrato
                        print mecanico
                    "2" -> do
                        valor <- calculaValor numContrato
                        print valor
              "Devolução atrasada" -> do
                valor <- calculaValor numContrato
                print valor


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

verificaDevolucao :: String -> IO String
verificaDevolucao inputDate = do
    -- Obtém a data atual
    currentDay <- getCurrentTime >>= return . utctDay

    let parsedDate = parseTimeM True defaultTimeLocale "%Y-%m-%d" inputDate :: Maybe Day

    case parsedDate of
        Just date -> do
            if date == currentDay
                then return "Devolução dentro do prazo."
                else if date < currentDay
                    then return "Devolução adiantada"
                    else
                        return "Devolução atrasada"
        Nothing -> return "Data inválida."

-- Funcões temporárias
-- enviaParaMecanico :: Connection -> (String, String, Integer) -> Bool
-- enviaParaMecanico conn id_carro id_aluguel = do

enviaParaMecanico :: Connection -> Integer -> Integer -> IO Double
enviaParaMecanico conn id_carro id_aluguel = do
    let valorCalculado = 100.0 
    
    return valorCalculado

calculaValor ::  Integer -> IO Double
calculaValor id_aluguel = do
    let valorCalculado = 100.0 
    
    return valorCalculado