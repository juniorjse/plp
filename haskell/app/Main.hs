module Main where

import Controller.User
import Database.PostgreSQL.Simple
import LocalDB.ConnectionDB
import System.Console.ANSI

main :: IO ()
main = do
  conn <- iniciandoDatabase
  clearScreenOnly
  menu conn
  close conn
  putStrLn "Até a próxima !"