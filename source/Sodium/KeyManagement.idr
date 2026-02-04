module Sodium.KeyManagement

import Sodium.Primitives
import Sodium.SecureBuffer
import Sodium.Random

import public Sodium.Protected

public export
record Key (n : Nat) (m : ProtectionMode) where
  constructor MkKey
  keySize   : Nat
  keyBuffer : SecureBuffer m

export
generateKey : HasIO io => (n : Nat) -> (m : ProtectionMode) -> io (Maybe (Key n m))
generateKey size mode = do
  buffer <- newSecureBuffer ReadWrite (cast size)
  _      <- randomizeBuffer buffer
  buffer <- setAccess mode buffer
  pure $ case buffer of
    Nothing     => Nothing
    Just buffer => Just $ MkKey size buffer

export
(n : Nat) => Protected (Key n) where
  noAccess (MkKey size buffer) = do
    buffer <- noAccess buffer
    pure $ buffer >>= (Just . MkKey size)
    
  readOnly (MkKey size buffer) = do
    buffer <- readOnly buffer
    pure $ buffer >>= (Just . MkKey size)
    
  readWrite (MkKey size buffer) = do
    buffer <- readWrite buffer
    pure $ buffer >>= (Just . MkKey size)
