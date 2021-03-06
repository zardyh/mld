{-# LANGUAGE OverloadedStrings, TupleSections #-}
module Main where

import qualified Data.Map.Strict as Map

import System.Console.Haskeline

import Parser
import Syntax

import Typing.Monad
import Typing.Errors
import Typing

import Closure.Convert
import Closure.ToC

realise :: String -> Either (Either ParseError TypeError) (Exp, Typing)
realise code = do
  expr <- mapLeft Left (parser code)
  mapLeft Right $
    fmap (expr,) (runTyping demonstration (infer expr))

demonstration :: Gamma
demonstration =
  Gamma . Map.fromList $
    [ (Var "add", poly $ "Num" :-> "Num" :-> "Num")
    , (Var "if", poly $ "Bool" :-> "a" :-> "a" :-> "a")
    , (Var "true", poly "Bool")
    , (Var "false", poly "Bool")
    ]
  where poly = Typing Nothing mempty

mapLeft :: (a -> b) -> Either a c -> Either b c
mapLeft f = either (Left . f) Right

main :: IO ()
main = runInputT defaultSettings loop where
  loop :: InputT IO ()
  loop = do
    minput <- getInputLine "⊢ "
    case minput of
      Nothing -> return ()
      Just "quit" -> return ()
      Just input -> do
        liftIO (interp input)
        loop

  interp :: String -> IO ()
  interp s =
    case realise s of
      Left e -> either print (putStrLn . showError s) e
      Right (x, ty) ->
        print ty *> putStrLn (progToC (closureConvert x))
