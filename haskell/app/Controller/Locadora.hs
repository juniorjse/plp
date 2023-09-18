{-# LANGUAGE OverloadedStrings #-}

module Controller.Locadora where
import Database.PostgreSQL.Simple
import Control.Monad (void)
import Controller.Dashboard

menuLocadora :: Connection -> IO ()
menuLocadora conn = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Cadastrar carro"
    putStrLn "2. Remover carro"
    putStrLn "3. Dashboard"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> do
            registrarCarro conn
            menuLocadora conn
        "2" -> do
            removerCarro conn
            menuLocadora conn
        "3" -> do
            menuDashboard conn
            menuLocadora conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuLocadora conn

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
            menuLocadora conn
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
                            menuLocadora conn
                        "Não" -> menuLocadora conn
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