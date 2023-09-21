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
import Database.PostgreSQL.Simple
import Control.Monad (void)
import Control.Monad (forM_)

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
            registrarCarro conn
        "2" -> do
            removerCarro conn
        "3" -> do
            registraDevolucao conn
        "4" -> 
            listarAlugueisPorCliente conn
        "5" -> do
            menuDashboard conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuLocadora conn

menuDashboard :: Connection -> IO ()
menuDashboard conn = do
    putStrLn ""
    putStrLn "Dashboard:"
    putStrLn "1. Receita total"
    putStrLn "2. Número de aluguéis"
    putStrLn "3. Total de carros"
    putStrLn "4. Carros mais defeituosos"
    putStrLn "5. Aluguéis por categoria"
    putStrLn "Escolha uma opção (ou digite qualquer outra coisa para voltar ao menu principal):"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> exibirReceitaTotal conn
        "2" -> exibirNumeroDeAlugueis conn
        "3" -> exibirTotalDeCarros conn
        "4" -> exibirCarrosMaisDefeituosos conn
        "5" -> exibirAlugueisPorCategoria conn
        _ -> do
            putStrLn "Dígito inválido. Voltando ao menu principal."
            menuLocadora conn

getProximoIDCarro :: Connection -> IO Int
getProximoIDCarro conn = do
    [Only proximoID] <- query_ conn "SELECT COALESCE(MAX(id_carro), 0) + 1 FROM Carros"
    return proximoID

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
    else if not confirmacao
        then do
            putStrLn "O cadastro foi cancelado."
            menuLocadora conn
            else do 
                carroExiste <- carroJaCadastrado conn placa 
                if carroExiste 
                    then do
                        putStrLn ""
                        putStrLn "Esse carro já foi cadastrado no sistema. Tente novamente."
                        putStrLn ""
                        registrarCarro conn
                else do
                        -- Obtém o próximo ID disponível
                    proximoID <- getProximoIDCarro conn
    
                    -- Insere o carro no banco de dados com o próximo ID
                    execute conn "INSERT INTO Carros (id_carro, marca, modelo, ano, placa, categoria, quilometragem, status, diaria_carro, descricao_carro) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)" (proximoID, marca, modelo, ano, placa, categoria, 0.0 :: Double, "A" :: String, diaria, descricao)
                    putStrLn "Cadastro realizado com sucesso! Informações do carro cadastrado:"
                    putStrLn $ "ID:         " ++ show proximoID
                    putStrLn $ "Marca:      " ++ marca
                    putStrLn $ "Modelo:     " ++ modelo
                    putStrLn $ "Ano:        " ++ ano
                    putStrLn $ "Placa:      " ++ placa
                    putStrLn $ "Categoria:  " ++ categoria
                    putStrLn $ "Diária:     " ++ diaria
                    putStrLn $ "Descrição:  " ++ descricao
                    novoCadastro conn
                
confirma :: Connection -> IO Bool
confirma conn = do
    putStrLn "Tem certeza que deseja cadastrar esse carro? \n 1.Sim \n 2.Não"
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
    putStrLn "\nDeseja cadastrar outro carro? \n 1.Sim \n 2.Não"
    novoCadastro <- getLine
    case novoCadastro of
        "1" -> registrarCarro conn
        "2" -> menuLocadora conn
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."

carroJaCadastrado :: Connection -> String -> IO Bool
carroJaCadastrado conn placa = do
    [Only count] <- query conn "SELECT COUNT(*) FROM carros WHERE placa = ?" (Only placa)
    return (count /= (0 :: Int))

removerCarro :: Connection -> IO ()
removerCarro conn = do
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
                    putStrLn "Tem certeza de que deseja remover este carro?  \n 1.Sim \n 2.Não"
                    confirmacao <- getLine

                    case confirmacao of
                        "1" -> do
                            removeCarroDoSistema conn carroId
                            putStrLn "Carro removido com sucesso!"
                            menuLocadora conn
                        "2" -> do
                            putStrLn "Remoção de carro cancelada!"
                            menuLocadora conn
                        _ -> do
                            putStrLn "Opção inválida. Por favor, escolha novamente."
                            removerCarro conn
                else do
                    putStrLn "Este carro está atualmente alugado (status 'O') e não pode ser removido."
                    menuLocadora conn
        else do
            putStrLn "ID de carro inválido ou inexistente. Tente novamente."
            removerCarro conn

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

listarAlugueisPorCliente :: Connection -> IO ()
listarAlugueisPorCliente conn = do
    putStrLn "Digite o ID do cliente para listar os registros de aluguéis:"
    clienteIdStr <- getLine
    putStrLn ""
    let clienteId = read clienteIdStr :: Integer

    clienteExiste <- verificaClienteExistente conn clienteId

    if clienteExiste
        then do
            alugueis <- obterAlugueisPorCliente conn clienteId
            if null alugueis
                then do
                    putStrLn "Não há registros de aluguéis para este cliente."
                else do
                    putStrLn "Registros de Aluguéis:"
                    mapM_ (mostrarRegistroAluguel) alugueis
        else do
            putStrLn "Cliente não encontrado na base de dados."
    menuLocadora conn

mostrarRegistroAluguel :: (String, String, Int, Day, Day, Double, String) -> IO ()
mostrarRegistroAluguel (marca, modelo, ano, dataInicio, dataDevolucao, valor, status) = do
    putStrLn $ "Carro:               " ++ marca ++ " " ++ modelo ++ " (" ++ show ano ++ ")"
    putStrLn $ "Data de Início:      " ++ formatTime defaultTimeLocale "%Y-%m-%d" dataInicio
    putStrLn $ "Data de Devolução:   " ++ formatTime defaultTimeLocale "%Y-%m-%d" dataDevolucao
    putStrLn $ "Valor do Aluguel:    R$ " ++ show valor
    putStrLn $ "Status do Aluguel:   " ++ status
    putStrLn ""

verificaClienteExistente :: Connection -> Integer -> IO Bool
verificaClienteExistente conn clienteId = do
    [Only count] <- query conn "SELECT COUNT(*) FROM Usuarios WHERE id_usuario = ?" (Only clienteId)
    return (count > (0 :: Int))

obterAlugueisPorCliente :: Connection -> Integer -> IO [(String, String, Int, Day, Day, Double, String)]
obterAlugueisPorCliente conn clienteId = do
    query conn "SELECT c.marca, c.modelo, c.ano, a.data_inicio, a.data_devolucao, a.valor_total, a.status_aluguel FROM Alugueis a INNER JOIN Carros c ON a.id_carro = c.id_carro WHERE a.id_usuario = ?" (Only clienteId)

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
        [(data_inicio, data_devolucao, id_carro, valor_total)] -> do
            printAluguel conn (data_inicio, data_devolucao, id_carro, valor_total)
            devolucao <- verificaDevolucao data_devolucao
            case (devolucao :: String) of
              "Devolução dentro do prazo" -> printDevolucao conn valor_total id_carro
              "Devolução adiantada" -> do
                putStrLn "Motivo da devolução adiantada:"
                putStrLn "1. Problema no carro"
                putStrLn "2. Outro motivo"
                motivo <- getLine
                case motivo of
                    "1" -> do
                        enviaParaMecanico conn id_carro
                        menuLocadora conn
                    "2" -> do
                        valor <- calculaValor conn data_inicio data_devolucao valor_total id_carro
                        printDevolucao conn valor id_carro
                        menuLocadora conn
                    _ -> do
                        putStrLn "Opção inválida. Você será direcionado(a) ao menu inicial."
                        menuLocadora conn
              "Devolução atrasada" -> do
                valor <- calculaValor conn data_inicio data_devolucao valor_total id_carro
                printDevolucao conn valor id_carro
                menuLocadora conn

buscarAluguel :: Connection -> Integer -> IO [(Day, Day, Integer, Double)]
buscarAluguel conn numContrato = do
    alugueis <- query conn "SELECT data_inicio, data_devolucao, id_carro, valor_total FROM Alugueis WHERE id_aluguel = ? AND status_aluguel = 'ativo'" (Only numContrato)
    return alugueis

buscarCarro :: Connection -> Integer -> IO ()
buscarCarro conn id_carro = do
    putStrLn ""
    putStrLn $ "Detalhes do aluguel com ID '" ++ show id_carro ++ "':"
    carro <- query conn "SELECT marca, modelo, ano FROM Carros WHERE id_carro = ?" (Only id_carro)

    if null carro
        then putStrLn $ "Carro com ID '" ++ show id_carro ++ "' não encontrado."
        else printCarroLocadora (head carro)

printAluguel :: Connection -> (Day, Day, Integer, Double) -> IO ()
printAluguel conn (data_inicio, data_devolucao, id_carro, valor_total) = do
    putStrLn "Carro Alugado: "
    buscarCarro conn id_carro
    valor_final <- calculaValor conn data_inicio data_devolucao valor_total id_carro
    putStrLn $ "Data de início do aluguel: " ++ show data_inicio ++ "\nData de devolução:         " ++ show data_devolucao
    putStrLn ("Valor total do aluguel:    R$ " ++ show valor_final)

printCarroLocadora :: (String, String, Int) -> IO ()
printCarroLocadora (marca, modelo, ano) = do
    putStrLn $ "Carro:                     " ++ marca ++ " " ++ modelo ++ " (" ++ show ano ++ ")"

verificaDevolucao :: Day -> IO String
verificaDevolucao inputDate = do
    currentDay <- getCurrentTime >>= return . utctDay

    if inputDate == currentDay
        then return "Devolução dentro do prazo."
        else if inputDate > currentDay
            then return "Devolução adiantada"
            else return "Devolução atrasada"

printDevolucao :: Connection -> Double -> Integer -> IO ()
printDevolucao conn valor id_carro = do
    putStrLn "\nRealizar pagamento do aluguel! Valor total: "
    putStrLn $ "R$ " ++ show valor
    putStrLn "\n1. Confirmar pagamento"
    putStrLn "2. Cancelar"
    confirmaPagamento <- getLine
    case confirmaPagamento of
        "1" -> do
            putStrLn "Pagamento realizado com sucesso!"
            putStrLn "Aluguel finalizado."
            execute conn "UPDATE Alugueis SET status_aluguel = 'Concluído' WHERE id_carro = ? AND status_aluguel = 'ativo'" (Only id_carro)
            execute conn "UPDATE Carros SET status = 'D' WHERE id_carro = ?" (Only id_carro)
            menuLocadora conn
        "2" -> do
            putStrLn "Operação cancelada!"
            menuLocadora conn
        _ -> do
            putStrLn "Opção inválida. Você será direcionado(a) ao menu inicial."
            menuLocadora conn

retornaDiaria :: Connection -> Integer -> IO Double
retornaDiaria conn id_carro = do
    [Only diariaFloat] <- query conn "SELECT diaria_carro FROM carros WHERE id_carro = ?" (Only id_carro)
    let diariaDouble = diariaFloat :: Double
    return diariaDouble

calculaValor :: Connection -> Day -> Day -> Double -> Integer-> IO Double
calculaValor conn data_inicio data_devolucao valor_total id_carro= do
    dataAtual <- getCurrentTime >>= return . utctDay
    let qtdDiasAlugados = fromIntegral (diffDays data_inicio dataAtual)
    diaria <- retornaDiaria conn id_carro
    
    return $ (-1*qtdDiasAlugados) * diaria
    

enviaParaMecanico :: Connection -> Integer -> IO ()
enviaParaMecanico conn id_carro = do
    void $ execute conn "UPDATE Carros SET status = 'R' WHERE id_carro = ?" (Only id_carro)

calcularReceitaTotal :: Connection -> IO Double
calcularReceitaTotal conn = do
    [Only total] <- query_ conn "SELECT SUM(valor_total) FROM Alugueis"
    return total

contarAlugueis :: Connection -> IO Int
contarAlugueis conn = do
    [Only count] <- query_ conn "SELECT COUNT(*) FROM Alugueis"
    return count

contarCarros :: Connection -> IO Int
contarCarros conn = do
    [Only count] <- query_ conn "SELECT COUNT(*) FROM Carros"
    return count

listarCarrosMaisDefeituosos :: Connection -> IO [(String, String)]
listarCarrosMaisDefeituosos conn = do
    query_ conn "SELECT marca, modelo FROM Carros WHERE status = 'R'"

listarAlugueisPorCategoria :: Connection -> IO [(String, Int)]
listarAlugueisPorCategoria conn = do
    query_ conn "SELECT categoria, COUNT(*) FROM Alugueis JOIN Carros ON Alugueis.id_carro = Carros.id_carro GROUP BY categoria"

exibirReceitaTotal :: Connection -> IO ()
exibirReceitaTotal conn = do
    totalReceita <- calcularReceitaTotal conn
    putStrLn $ "Receita Total: " ++ show totalReceita
    menuDashboard conn
exibirNumeroDeAlugueis :: Connection -> IO ()
exibirNumeroDeAlugueis conn = do
    numeroAlugueis <- contarAlugueis conn
    putStrLn $ "Número de Aluguéis: " ++ show numeroAlugueis
    menuDashboard conn

exibirTotalDeCarros :: Connection -> IO ()
exibirTotalDeCarros conn = do
    totalCarros <- contarCarros conn
    putStrLn $ "Total de Carros: " ++ show totalCarros
    menuDashboard conn

exibirCarrosMaisDefeituosos :: Connection -> IO ()
exibirCarrosMaisDefeituosos conn = do
    carrosDefeituosos <- listarCarrosMaisDefeituosos conn
    putStrLn "Carros mais defeituosos:"
    forM_ carrosDefeituosos (\(marca, modelo) -> putStrLn $ marca ++ " " ++ modelo)
    menuDashboard conn

exibirAlugueisPorCategoria :: Connection -> IO ()
exibirAlugueisPorCategoria conn = do
    alugueisPorCategoria <- listarAlugueisPorCategoria conn
    putStrLn "Aluguéis por Categoria:"
    forM_ alugueisPorCategoria (\(categoria, quantidade) -> putStrLn $ categoria ++ ": " ++ show quantidade)
    menuDashboard conn