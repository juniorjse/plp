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
import Control.Monad (void)


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
            registrarCarro conn locadoraId
        "2" -> do
            removerCarro conn locadoraId
        "3" -> do
            registraDevolucao conn locadoraId
        "4" -> 
            listarAlugueisPorCliente conn locadoraId
        "4" -> do
            menuDashboard conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuLocadora conn locadoraId

registrarCarro :: Connection -> LocadoraID -> IO ()
registrarCarro conn locadoraId = do
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
            registrarCarro conn locadoraId
    -- cancelou o cadastro:
    else if not confirmacao 
        then do
            putStrLn "O cadastro foi cancelado."
            menuLocadora conn locadoraId
    -- verifica existencia do carro no bd:
    else do 
        carroExiste <- carroJaCadastrado conn placa 
        if carroExiste 
            then do
                putStrLn "Esse carro já foi cadastrado no sistema. Tente novamente."
                registrarCarro conn locadoraId
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
                novoCadastro conn locadoraId
                
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

novoCadastro :: Connection -> LocadoraID -> IO()
novoCadastro conn locadoraId = do
    putStrLn "\nDeseja cadastrar outro carro? \n 1. Sim \n 2.Não"
    novoCadastro <- getLine
    case novoCadastro of
        "1" -> registrarCarro conn locadoraId
        "2" -> menuLocadora conn locadoraId
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."


carroJaCadastrado :: Connection -> String -> IO Bool
carroJaCadastrado conn placa = do
    [Only count] <- query conn "SELECT COUNT(*) FROM carros WHERE placa = ?" (Only placa)
    return (count /= (0 :: Int))


-- Remove um carro do banco de dados
removerCarro :: Connection -> LocadoraID -> IO ()
removerCarro conn locadoraId = do
    putStrLn "Informe o ID do carro que deseja remover:"
    carroIdStr <- getLine
    putStrLn ""
    let carroId = read carroIdStr :: Integer  

    carroExiste <- verificaCarroExistente conn carroId

    if carroExiste
        then do
            carroDisponivel <- verificaCarroDisponivel conn carroId

            if carroDisponivel
                then do
                    putStrLn "Tem certeza de que deseja remover este carro? (Sim/Não)"
                    confirmacao <- getLine

                    case confirmacao of
                        "Sim" -> do
                            removeCarroDoSistema conn carroId
                            putStrLn "Carro removido com sucesso!"
                            menuLocadora conn locadoraId
                        "Não" -> menuLocadora conn locadoraId
                        _ -> do
                            putStrLn "Opção inválida. Por favor, escolha novamente."
                            removerCarro conn locadoraId
                else do
                    putStrLn "Este carro está atualmente alugado (status 'O') e não pode ser removido."
                    menuLocadora conn locadoraId
        else do
            putStrLn "ID de carro inválido ou inexistente. Tente novamente."
            removerCarro conn locadoraId

removeCarroDoSistema :: Connection -> Integer -> IO ()
removeCarroDoSistema conn carroId = do
    void $ execute conn "DELETE FROM carros WHERE id_carro = ?" (Only carroId)

verificaCarroExistente :: Connection -> Integer -> IO Bool
verificaCarroExistente conn carroId = do
    [Only count] <- query conn "SELECT COUNT(*) FROM Carros WHERE id_carro = ?" (Only carroId)
    return (count > (0 :: Int))

verificaCarroDisponivel :: Connection -> Integer -> IO Bool
verificaCarroDisponivel conn carroId = do
    [Only status] <- query conn "SELECT status FROM Carros WHERE id_carro = ?" (Only carroId)
    return (status == ("D" :: String))


-- Registros de Aluguéis por Cliente
listarAlugueisPorCliente :: Connection -> LocadoraID -> IO ()
listarAlugueisPorCliente conn locadoraId = do
    putStrLn "Digite o ID do cliente para listar os registros de aluguéis:"
    clienteIdStr <- getLine
    putStrLn ""
    let clienteId = read clienteIdStr :: Integer

    clienteExiste <- verificaClienteExistente conn clienteId

    if clienteExiste
        then do
            alugueis <- obterAlugueisPorCliente conn clienteId locadoraId
            if null alugueis
                then do
                    putStrLn "Não há registros de aluguéis para este cliente."
                else do
                    putStrLn "Registros de Aluguéis:"
                    mapM_ (mostrarRegistroAluguel) alugueis
        else do
            putStrLn "Cliente não encontrado na base de dados."
    menuLocadora conn locadoraId

mostrarRegistroAluguel :: (String, String, Int, Day, Day, Double, String) -> IO ()
mostrarRegistroAluguel (marca, modelo, ano, dataInicio, dataDevolucao, valor, status) = do
    putStrLn $ "Carro: " ++ marca ++ " " ++ modelo ++ " (" ++ show ano ++ ")"
    putStrLn $ "Data de Início: " ++ formatTime defaultTimeLocale "%Y-%m-%d" dataInicio
    putStrLn $ "Data de Devolução: " ++ formatTime defaultTimeLocale "%Y-%m-%d" dataDevolucao
    putStrLn $ "Valor do Aluguel: $ " ++ show valor
    putStrLn $ "Status do Aluguel: " ++ status
    putStrLn ""

verificaClienteExistente :: Connection -> Integer -> IO Bool
verificaClienteExistente conn clienteId = do
    [Only count] <- query conn "SELECT COUNT(*) FROM Usuarios WHERE id_usuario = ?" (Only clienteId)
    return (count > (0 :: Int))

obterAlugueisPorCliente :: Connection -> Integer -> LocadoraID -> IO [(String, String, Int, Day, Day, Double, String)]
obterAlugueisPorCliente conn clienteId locadoraId = do
    query conn "SELECT c.marca, c.modelo, c.ano, a.data_inicio, a.data_devolucao, a.valor_total, a.status_aluguel FROM Alugueis a INNER JOIN Carros c ON a.id_carro = c.id_carro WHERE a.id_usuario = ?" (Only clienteId)
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
              "Devolução dentro do prazo" -> printDevolucao conn locadoraId valor_total id_carro
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
                        printDevolucao conn locadoraId valor id_carro
              "Devolução atrasada" -> do
                valor <- calculaValor data_inicio data_devolucao valor_total
                printDevolucao conn locadoraId valor id_carro


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

printDevolucao :: Connection -> LocadoraID -> Double -> Integer -> IO ()
printDevolucao conn locadoraId valor id_carro = do
    putStrLn "Realizar pagamento do aluguel! Valor total: "
    print valor
    putStrLn "1. Confirmar pagamento"
    putStrLn "2. Cancelar"
    confirmaPagamento <- getLine
    case confirmaPagamento of
        "1" -> do
            putStrLn "Pagamento realizado com sucesso!"
            putStrLn "Aluguel finalizado."
            execute conn "UPDATE Alugueis SET status_aluguel = 'Concluído' WHERE id_carro = ? AND status_aluguel = 'ativo'" (Only id_carro)
            execute conn "UPDATE Carros SET status = 'D' WHERE id_carro = ?" (Only id_carro)
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