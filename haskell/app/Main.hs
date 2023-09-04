module Main where

import Controller.User
import Database.PostgreSQL.Simple
import LocalDB.ConnectionDB

main :: IO ()
main = do
  conn <- iniciandoDatabase
  menu conn
  close conn
  putStrLn ""
