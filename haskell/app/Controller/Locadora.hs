{-# LANGUAGE OverloadedStrings #-}

module Controller.Locadora where
import Database.PostgreSQL.Simple
import Data.Time
import Data.Time.Format
import System.Locale
import Controller.Mecanica 

data LocadoraExistenteException = LocadoraExistenteException
    deriving (Show)

type LocadoraID = Integer

locadoraIdRef :: IORef (Maybe LocadoraID)
locadoraIdRef = unsafePerformIO (newIORef Nothing)
{-# NOINLINE locadoraIdRef #-}

instance Exception LocadoraExistenteException

menuLocadora :: Connection -> LocadoraId -> IO ()
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
          putStrLn "Teste5"
          menuLocadora conn locadoraId
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuLocadora conn locadoraId

registraDevolucao :: Conection -> LocadoraId -> IO ()
registraDevolucao conn locadoraId = do
    putStrLn "Digite o número do contrato/ Id do aluguel a ser encerrado:"
    numContrato <- getLine
    maybeAluguel <- buscarAluguel conn numContrato
    case maybeAluguel of
        [] -> do
            putStrLn "Auguel não encontrado."
            putStrLn "1. Para digitar novamente"
            putStrLn "2. Para voltar ao menu inicial"
            opcao <- getLine
            case opcao of
                "1" -> registraDevolucao conn locadoraId
                "2" -> menuLocadora conn locadoraId
                _ -> do
                    putStrLn "Opção inválida. Você será direcionado(a) ao menu inicial."
                    menuLocadora conn locadoraId --colocar locadoraId
        [(data_inicio, data_devolucao, id_carro)] -> do
          printAluguel conn maybeAluguel


buscarAluguel :: Connection -> Integer -> IO [(String, String, Integer)]
buscarAluguel conn numContrato  = do
    query conn "SELECT data_inicio, data_devolucao, id_carro FROM Alugueis WHERE id_aluguel = ? AND status_aluguel = 'ativo'" numContrato

buscarCarro :: Connection -> Integer -> IO ()
buscarCarro conn id_carro  = do
    carro <- query conn "SELECT marca, modelo, ano FROM Carros WHERE id_carro = ?" id_carro
    mapM_ printCarro carro

printAluguel :: Connection -> (String, String, Integer) -> IO ()
printAluguel conn (data_inicio, data_devolucao, id_carro) = do
    putStrLn "Carro Alugado: "
    putStrLn $ buscarCarro conn id_carro
    putStrLn $ "Data de início do aluguel: " ++ data_inicio ++ ", Data de devolução: " ++ data_devolucao


printCarro :: (String, String, Int) -> IO ()
printCarro (marca, modelo, ano) = do
    putStrLn $ "Marca: " ++ marca ++ ", Modelo: " ++ modelo ++ ", Ano: " ++ show ano

