module Sodium.PasswordHash

import Data.String

import Sodium.Primitives
import Sodium.SecureBuffer
import Sodium.Memory

-- Password Hashing Data Types --

public export
data HashLimit
  = Minimum
  | Interactive
  | Moderate
  | Sensitive
  | Maximum
  | Immediate Bits64

public export
data HashAlgorithm = Argon2I13 | Argon2ID13 | Default

getHashAlgorithm : HashAlgorithm -> Int
getHashAlgorithm Argon2I13  = prim__crypto_pwhash_alg_argon2i13
getHashAlgorithm Argon2ID13 = prim__crypto_pwhash_alg_argon2id13
getHashAlgorithm Default    = prim__crypto_pwhash_alg_default

defaultHashPrefix : String
defaultHashPrefix = prim__crypto_pwhash_strprefix

export
saltLength : Bits64
saltLength = prim__crypto_pwhash_saltbytes

getOpLimit : HashLimit -> Bits64
getOpLimit Minimum       = prim__crypto_pwhash_opslimit_min
getOpLimit Interactive   = prim__crypto_pwhash_opslimit_interactive
getOpLimit Moderate      = prim__crypto_pwhash_opslimit_moderate
getOpLimit Sensitive     = prim__crypto_pwhash_opslimit_sensitive
getOpLimit Maximum       = prim__crypto_pwhash_opslimit_max
getOpLimit (Immediate n) = n

getMemLimit : HashLimit -> Bits64
getMemLimit Minimum       = prim__crypto_pwhash_memlimit_min
getMemLimit Interactive   = prim__crypto_pwhash_memlimit_interactive
getMemLimit Moderate      = prim__crypto_pwhash_memlimit_moderate
getMemLimit Sensitive     = prim__crypto_pwhash_memlimit_sensitive
getMemLimit Maximum       = prim__crypto_pwhash_memlimit_max
getMemLimit (Immediate n) = n

-- Medium Level, Immediate Password Hashing --

export
hashPasswordImmediate : HasIO io =>
                        AnyPtr -> Bits64 ->
                        String ->
                        AnyPtr ->
                        HashLimit -> HashLimit -> HashAlgorithm -> io Int
hashPasswordImmediate out outLen passwd salt ops mem alg = 
  let opsLimit = getOpLimit ops
      memLimit = getMemLimit mem
      algID    = getHashAlgorithm alg
      passLen  = strLength passwd
  in primIO $ prim__hashPassword out outLen
                                 passwd (cast passLen)
                                 salt
                                 opsLimit memLimit algID
                        

-- High Level, SecureBuffer Based Password Hashing --

public export
record PasswordHash where
  constructor MkPasswordHash
  hash         : SecureBuffer
  salt         : SecureBuffer
  stringPrefix : String
  algorithm    : HashAlgorithm
  opLimit      : HashLimit
  memLimit     : HashLimit

export
Show PasswordHash where
  show pwHash = let h = contentAsHex $ hash pwHash
                    s = contentAsHex $ salt pwHash
                    p = stringPrefix pwHash
                    a = show $ getHashAlgorithm $ algorithm pwHash
                    o = show $ getOpLimit $ opLimit pwHash
                    m = show $ getMemLimit $ memLimit pwHash
                in p ++ s ++ "$" ++ h ++ "$" ++ a ++ "$" ++ o ++ "$" ++ m

newSalt : HasIO io => io SecureBuffer
newSalt = do
  buffer <- newSecureBuffer saltLength
  randomizeBuffer buffer
  liftIO $ pure $ buffer

export
hashPassword : HasIO io =>
               HashLimit -> HashLimit -> HashAlgorithm -> Bits64 -> String ->
               io (Maybe PasswordHash)
hashPassword ops mem algo keySize passwd = do 
  out     <- newSecureBuffer keySize
  salt    <- newSalt
  outcome <- hashPasswordImmediate (rawPointer out) (length out)
                                   passwd (rawPointer salt)
                                   ops mem algo
  liftIO $ pure (if outcome == 0
                 then Just (MkPasswordHash out salt defaultHashPrefix algo ops mem)
                 else Nothing)

export
hashPasswordInteractive : HasIO io => HashAlgorithm -> Bits64 -> String ->
                          io (Maybe PasswordHash)
hashPasswordInteractive = hashPassword Interactive Interactive

export
hashPasswordModerate : HasIO io => HashAlgorithm -> Bits64 -> String ->
                          io (Maybe PasswordHash)
hashPasswordModerate = hashPassword Moderate Moderate

export
hashPasswordSensitive : HasIO io => HashAlgorithm -> Bits64 -> String ->
                          io (Maybe PasswordHash)
hashPasswordSensitive = hashPassword Sensitive Sensitive

export
noAccessPasswordHash : HasIO io => PasswordHash -> io Bool
noAccessPasswordHash pwHash = do
  o1 <- noAccessBuffer (hash pwHash)
  o2 <- noAccessBuffer (salt pwHash)
  liftIO $ pure $ o1 && o2

export
readOnlyPasswordHash : HasIO io => PasswordHash -> io Bool
readOnlyPasswordHash pwHash = do
  o1 <- readOnlyBuffer (hash pwHash)
  o2 <- readOnlyBuffer (salt pwHash)
  liftIO $ pure $ o1 && o2

export
readWritePasswordHash : HasIO io => PasswordHash -> io Bool
readWritePasswordHash pwHash = do
  o1 <- readWriteBuffer (hash pwHash)
  o2 <- readWriteBuffer (salt pwHash)
  liftIO $ pure $ o1 && o2
