{-# LANGUAGE OverloadedStrings #-}

module Controller.Locadora where
import Data.Time (Day)
import Data.Time
import Data.Time (getCurrentTime)
import Data.Time.Format (formatTime, defaultTimeLocale)
import Data.Time.Calendar
import Controller.Mecanica
import Control.Exception
import Data.IORef
import System.IO.Unsafe (unsafePerformIO)
import Controller.Dashboard
import Database.PostgreSQL.Simple

type LocadoraID = Integer

locadoraIdRef :: IORef (Maybe LocadoraID)
locadoraIdRef = unsafePerformIO $ do
    newIORef Nothing
{-# NOINLINE locadoraIdRef #-}

data LocadoraExistenteException = LocadoraExistenteException
    deriving (Show)

menuLocadora :: Connection -> LocadoraID -> IO ()
menuLocadora conn locadoraId = do
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
            menuLocadora conn locadoraId
        "2" -> do
          putStrLn "Teste2"
          menuLocadora conn locadoraId
        "3" -> do
          registraDevolucao conn locadoraId
        "4" -> do
          putStrLn "Teste4"
          menuLocadora conn locadoraId
        "5" -> do
          menuDashboard conn
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
        [(data_inicio, data_devolucao, id_carro, valor_total)] -> do
            printAluguel conn (data_inicio, data_devolucao, id_carro, valor_total)
            devolucao <- verificaDevolucao data_devolucao
            case (devolucao :: String) of
              "Devolução dentro do prazo" -> printDevolucao conn locadoraId valor_total
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
                        valor <- calculaValor data_inicio data_devolucao valor_total
                        printDevolucao conn locadoraId valor
              "Devolução atrasada" -> do
                valor <- calculaValor data_inicio data_devolucao valor_total
                printDevolucao conn locadoraId valor


buscarAluguel :: Connection -> Integer -> IO [(Day, Day, Integer, Double)]
buscarAluguel conn numContrato = do
    alugueis <- query conn "SELECT data_inicio, data_devolucao, id_carro, valor_total FROM Alugueis WHERE id_aluguel = ? AND status_aluguel = 'ativo'" (Only numContrato)
    return alugueis


buscarCarro :: Connection -> Integer -> IO ()
buscarCarro conn id_carro = do
    putStrLn ""
    putStrLn $ "Detalhes do carro com ID '" ++ show id_carro ++ "':"
    carro <- query conn "SELECT marca, modelo, ano FROM Carros WHERE id_carro = ?" (Only id_carro)

    if null carro
        then putStrLn $ "Carro com ID '" ++ show id_carro ++ "' não encontrado."
        else printCarroLocadora (head carro)


printAluguel :: Connection -> (Day, Day, Integer, Double) -> IO ()
printAluguel conn (data_inicio, data_devolucao, id_carro, valor_total) = do
    putStrLn "Carro Alugado: "
    buscarCarro conn id_carro
    putStrLn $ "Data de início do aluguel: " ++ show data_inicio ++ ", Data de devolução: " ++ show data_devolucao
    putStrLn ("Valor total do aluguel: " ++ show valor_total)

printCarroLocadora :: (String, String, Int) -> IO ()
printCarroLocadora (marca, modelo, ano) = do
    putStrLn $ "Marca: " ++ marca ++ ", Modelo: " ++ modelo ++ ", Ano: " ++ show ano

verificaDevolucao :: Day -> IO String
verificaDevolucao inputDate = do
    -- Obtém a data atual
    currentDay <- getCurrentTime >>= return . utctDay

    if inputDate == currentDay
        then return "Devolução dentro do prazo."
        else if inputDate < currentDay
            then return "Devolução adiantada"
            else return "Devolução atrasada"

printDevolucao :: Connection -> LocadoraID -> Double -> IO ()
printDevolucao conn locadoraId valor = do
    putStrLn "Realizar pagamento do aluguel! Valor total: "
    print valor
    putStrLn "1. Confirmar pagamento"
    putStrLn "2. Cancelar"
    confirmaPagamento <- getLine
    case confirmaPagamento of
        "1" -> do
            putStrLn "Pagamento realizado com sucesso!"
            putStrLn "Aluguel finalizado."
            menuLocadora conn locadoraId
        "2" -> do
            putStrLn "Operação cancelada!"
            menuLocadora conn locadoraId

calculaValor :: Day -> Day -> Double -> IO Double
calculaValor data_inicio data_devolucao valor_total = do
    dataAtual <- getCurrentTime >>= return . utctDay
    let qtdDiasAlugados = fromIntegral (diffDays data_inicio data_devolucao)
    let diaria = valor_total / qtdDiasAlugados
    
    if qtdDiasAlugados <= 0
        then return diaria
        else do
            let diferencaDeDias = fromIntegral (diffDays data_inicio dataAtual)

            -- Calcula o valor total
            return $ diferencaDeDias * diaria


-- Funcões temporárias

enviaParaMecanico :: Connection -> Integer -> Integer -> IO Double
enviaParaMecanico conn id_carro id_aluguel = do
    let valorCalculado = 100.0

    return valorCalculado