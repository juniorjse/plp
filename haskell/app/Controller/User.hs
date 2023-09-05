{-# LANGUAGE OverloadedStrings #-}
module Controller.User where
import Data.Maybe (fromJust)
import System.IO.Unsafe
import Data.IORef
import Database.PostgreSQL.Simple
import System.IO
import Control.Exception
import Control.Exception (catch, SomeException)
import Data.Maybe (listToMaybe)
import Data.Int (Int64)
import Database.PostgreSQL.Simple.ToField (ToField (..))
import System.Console.ANSI

data UsuarioExistenteException = UsuarioExistenteException
    deriving (Show)

type UserID = Integer

userIdRef :: IORef (Maybe UserID)
userIdRef = unsafePerformIO (newIORef Nothing)
{-# NOINLINE userIdRef #-}

instance Exception UsuarioExistenteException

clearScreenOnly :: IO ()
clearScreenOnly = do
    clearScreen
    setCursorPosition 0 0
    return ()

menu :: Connection -> IO ()
menu conn = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Logar"
    putStrLn "2. Cadastrar"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> do
            putStrLn "Digite o e-mail:"
            email <- getLine
            putStrLn "Digite a senha:"
            senha <- getLine
    
            login conn email senha
        "2" -> solicitarCadastro conn
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menu conn
    
menuCliente :: Connection -> UserID -> IO ()
menuCliente conn userId = do
    putStrLn ""
    putStrLn "Menu:"
    putStrLn "1. Listar carros"
    putStrLn "2. Realizar aluguel"
    putStrLn "3. Cancelar aluguel"
    putStrLn "0. Sair"
    putStrLn "Escolha uma opção:"

    opcao <- getLine

    putStrLn ""

    case opcao of
        "1" -> do
            clearScreenOnly
            putStrLn "Opções de Categoria:"
            putStrLn "1. Econômico"
            putStrLn "2. Intermediário"
            putStrLn "3. SUV"
            putStrLn "4. Luxo"
            putStrLn ""
            putStrLn "Escolha a categoria de carro desejada (1/2/3/4): "
            categoria <- getLine

            case categoria of
                "1" -> listarCarrosPorCategoria conn "Econômico"
                "2" -> listarCarrosPorCategoria conn "Intermediário"
                "3" -> listarCarrosPorCategoria conn "SUV"
                "4" -> listarCarrosPorCategoria conn "Luxo"
                _   -> putStrLn "Opção inválida. Por favor, escolha uma categoria válida."
            menuCliente conn userId

        "2" -> do
            putStrLn "ID do carro:"
            carroId <- getLine
            realizarAluguel conn userId carroId
        "3" -> cancelarAluguel conn userId
        "0" -> return ()
        _ -> do
            putStrLn "Opção inválida. Por favor, escolha novamente."
            menuCliente conn userId

login :: Connection -> String -> String -> IO ()
login conn email senha = do
    maybeUserTuple <- buscarUsuarioPorEmailSenha conn email senha
    putStrLn ""

    case maybeUserTuple of
        Just (nome, sobrenome) -> do
            clearScreenOnly  
            putStrLn "Bem-vindo!"
            putStrLn $ "Nome: " ++ nome ++ " " ++ sobrenome
            setUserID conn email
            maybeUserId <- readIORef userIdRef
            case maybeUserId of
                Just userId -> menuCliente conn userId
                Nothing -> putStrLn "UserID não encontrado."
        Nothing -> do
            clearScreenOnly
            putStrLn "E-mail ou senha incorretos."
            menu conn

solicitarCadastro :: Connection -> IO ()
solicitarCadastro conn = do
    putStrLn "Digite o nome:"
    nome <- getLine
    putStrLn "Digite o sobrenome:"
    sobrenome <- getLine
    putStrLn "Digite o e-mail:"
    email <- getLine
    putStrLn "Digite a senha (mínimo de 7 caracteres):"
    senha <- getLine
    putStrLn "Digite a senha novamente:"
    confirmaSenha <- getLine

    if null nome || null sobrenome || null email || null senha
        then do
            putStrLn "Campos não podem ser nulos. Por favor, preencha todos os campos."
            solicitarCadastro conn
        else if senha /= confirmaSenha
            then do
                putStrLn "Senhas diferentes. Tente novamente."
                solicitarCadastro conn
        else if length senha < 7
            then do
                putStrLn "A senha deve ter no mínimo 7 caracteres."
                solicitarCadastro conn
            else do
                emailExists <- usuarioComEmailCadastrado conn email

                if emailExists
                    then do
                        putStrLn "Usuário com e-mail já cadastrado. Por favor, forneça um e-mail diferente."
                        solicitarCadastro conn
                    else do
                        execute_ conn "BEGIN"
                        execute conn "INSERT INTO USUARIOS (nome, sobrenome, email, senha) VALUES (?, ?, ?, ?)" (nome, sobrenome, email, senha)
                        execute_ conn "COMMIT"

                        putStrLn "Cadastro realizado com sucesso."
                        menu conn         

buscarUsuarioPorEmailSenha :: Connection -> String -> String -> IO (Maybe (String, String))
buscarUsuarioPorEmailSenha conn email senha = do
    users <- query conn "SELECT nome, sobrenome FROM USUARIOS WHERE email = ? AND senha = ?" (email, senha)
    return $ listToMaybe users

usuarioComEmailCadastrado :: Connection -> String -> IO Bool
usuarioComEmailCadastrado conn email = do
    [Only count] <- query conn "SELECT COUNT(*) FROM USUARIOS WHERE email = ?" (Only email)
    return (count /= (0 :: Int))

setUserID :: Connection -> String -> IO ()
setUserID conn email = do
    [Only userId] <- query conn "SELECT id_usuario FROM USUARIOS WHERE email = ?" (Only email)
    writeIORef userIdRef (Just (userId :: Integer))

realizarAluguel :: Connection -> UserID -> String -> IO ()
realizarAluguel conn userId carroId = do
    putStrLn "Dias de aluguel do carro:"
    dias_aluguel_str <- getLine
    let dias_aluguel = read dias_aluguel_str :: Double -- Lê os dias como Double

    carros <- query conn "SELECT marca, modelo, placa, diaria_carro FROM carros WHERE id_carro = ?" (Only carroId)

    case carros of
        [] -> putStrLn "Carro não encontrado."
        [(marca, modelo, placa, diaria_carro)] -> do
            putStrLn $ marca ++ ", " ++ modelo ++ " - " ++ placa
            let valor_total = diaria_carro * dias_aluguel -- Agora a multiplicação é direta
            putStrLn $ "Valor total: " ++ show valor_total
            putStrLn ""
            putStrLn "Deseja confirmar o aluguel desse carro?"
            putStrLn "Sim(digite 1), Não(digite 2)"
            confirma <- getLine
            case confirma of
                "1" -> do
                    execute conn "INSERT INTO Alugueis (id_carro, id_usuario, data_inicio, data_devolucao, valor_total, status_aluguel) VALUES (?, ?, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day' * ?, ?, 'ativo')"(carroId, userId, dias_aluguel, valor_total)
                    execute conn "UPDATE carros SET status = 'O' WHERE id_carro = ?" (Only carroId)
                    putStrLn "Aluguel realizado com sucesso!"
                    menuCliente conn userId
                "2" -> menuCliente conn userId
                _ -> do
                    putStrLn "Opção inválida. Por favor, escolha novamente."
                    menuCliente conn userId

cancelarAluguel :: Connection -> Integer -> IO ()
cancelarAluguel conn userId = do
    alugueis <- buscarAlugueisPorUsuario conn userId
    putStrLn ""
    putStrLn "Aluguéis do usuário:"
    
    case alugueis of
        [] -> putStrLn "Nenhum aluguel encontrado para este usuário."
        _ -> do
            putStrLn $ "ID do Aluguel | ID do Carro | Valor Total"
            putStrLn "--------------------------------------------"
            mapM_ printAluguelInfo alugueis

            putStrLn "Digite o ID do aluguel que deseja cancelar:"
            aluguelIdStr <- getLine
            let aluguelId = read aluguelIdStr :: Integer

            -- Chama a função verificaTempoAluguel para verificar se o aluguel pode ser cancelado.
            tempo <- verificaTempoAluguel conn (fromInteger aluguelId)

            -- Agora, com base no valor de tempo, decidimos se o aluguel pode ser cancelado ou não
            if tempo == 0
                then do
                    clearScreenOnly
                    putStrLn "Aluguel possível de ser cancelado."
                    putStrLn ""
                    putStrLn "Deseja confirmar o cancelamento desse aluguel?"
                    putStrLn "Sim(digite 1), Não(digite 2)"
                    confirma <- getLine
                    case confirma of
                        "1" -> do
                            execute conn "UPDATE Alugueis SET status_aluguel = 'cancelado' WHERE id_aluguel = ?" (Only aluguelId)
                            execute conn "UPDATE carros SET status = 'D' WHERE id_carro = (SELECT id_carro FROM Alugueis WHERE id_aluguel = ?)" (Only aluguelId)
                            putStrLn "Aluguel cancelado com sucesso!"
                            menuCliente conn userId
                        "2" -> menuCliente conn userId
                        _ -> do
                            putStrLn "Opção inválida. Por favor, escolha novamente."
                            menuCliente conn userId
                else do
                    clearScreenOnly
                    putStrLn "Aluguel não é possível ser cancelado, pois faz mais de um dia que o aluguel foi iniciado."
                    putStrLn ""

            -- Retornar ao menu de cliente ou executar outras ações, se necessário
            menuCliente conn userId

buscarAlugueisPorUsuario :: Connection -> Integer -> IO [(Integer, Integer, Double)]
buscarAlugueisPorUsuario conn userId = do
    alugueis <- query conn "SELECT id_aluguel, id_carro, valor_total FROM Alugueis WHERE id_usuario = ? AND status_aluguel = 'ativo'" (Only userId)
    return alugueis

printAluguelInfo :: (Integer, Integer, Double) -> IO ()
printAluguelInfo (idAluguel, idCarro, valorTotal) = do
    putStrLn $ show idAluguel ++ "             |       " ++ show idCarro ++ "     |        " ++ show valorTotal

verificaTempoAluguel :: Connection -> Int -> IO Int
verificaTempoAluguel conn aluguelId = do
    [Only result] <- query conn "SELECT verificaTempoAluguel(?)" (Only aluguelId)
    return result
    
listarCarrosPorCategoria :: Connection -> String -> IO ()
listarCarrosPorCategoria conn categoria = do
    putStrLn ""
    putStrLn $ "Carros disponíveis na categoria '" ++ categoria ++ "':"
    carros <- query conn "SELECT marca, modelo, ano FROM Carros WHERE categoria = ? AND status = 'D'" [categoria]
    
    if null carros
        then putStrLn $ "Não há carros disponíveis na categoria '" ++ categoria ++ "'"
        else mapM_ printCarro carros

printCarro :: (String, String, Int) -> IO ()
printCarro (marca, modelo, ano) = do
    putStrLn $ "Marca: " ++ marca ++ ", Modelo: " ++ modelo ++ ", Ano: " ++ show ano
        