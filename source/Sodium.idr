module Sodium

import Sodium.Primitives

import Sodium.Memory
import Sodium.SecureBuffer
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
  putStr "Password: "
  _    <- initSodium
  line <- getLine
  pass <- deriveKeyModerate Default 64 line
  case pass of
    Nothing => putStrLn "Could not derive key from password."
    Just pass => do
      pass <- readOnly pass
      putStrLn . show $ pass
