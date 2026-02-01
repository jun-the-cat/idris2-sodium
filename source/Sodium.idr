module Sodium

import Sodium.Primitives

import Sodium.Memory
import Sodium.PasswordHash

-- Initialization Routines --

||| Initializes the LibSodium runtime. This returns True if
||| the runtime has been initialized or reinitialized, and
||| False if an issued occurred during initialization.
initSodium : IO Bool
initSodium = do
  outcome <- primIO $ prim__initSodium
  pure $ case outcome of
    -1 => False
    _  => True

test : IO ()
test = do
  _   <- initSodium
  str <- hashPassword Interactive Interactive "Hello, world!"
  putStrLn $ show str
  case str of
    Just hash => putStrLn $ show $ verifyPassword hash "Hello, world!"
    Nothing   => putStrLn "Cannot validate."
