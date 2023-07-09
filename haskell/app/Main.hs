module Main where
import Database.PostgreSQL.Simple
import LocalDB.ConnectionDB
import Controller.User

main :: IO()
main = do
  conn <- iniciandoDatabase
  solicitarCadastro conn
  close conn
  putStrLn "BD criado"
