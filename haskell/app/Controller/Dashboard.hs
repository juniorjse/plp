{-# LANGUAGE OverloadedStrings #-}

module Controller.Dashboard where
import Database.PostgreSQL.Simple
import Control.Monad (forM_)

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
            return ()

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
    carrosDefeituosos <- query_ conn "SELECT marca, modelo FROM Carros WHERE status = 'R'"
    return carrosDefeituosos

listarAlugueisPorCategoria :: Connection -> IO [(String, Int)]
listarAlugueisPorCategoria conn = do
    alugueisPorCategoria <- query_ conn "SELECT categoria, COUNT(*) FROM Alugueis JOIN Carros ON Alugueis.id_carro = Carros.id_carro GROUP BY categoria"
    return alugueisPorCategoria

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