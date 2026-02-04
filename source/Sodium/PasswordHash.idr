module Sodium.PasswordHash

import Data.String

import Sodium.Primitives
import Sodium.SecureBuffer
import Sodium.Memory

-- Password Hashing Data Types --

||| The options for the different configurable limits of Sodium's
||| hashing routines.
public export
data HashLimit
  = Minimum
  | Interactive
  | Moderate
  | Sensitive
  | Maximum
  | Immediate Bits64

||| The available hashing algorithms.
public export
data HashAlgorithm = Argon2I13 | Argon2ID13 | Default

getHashAlgorithm : HashAlgorithm -> Int
getHashAlgorithm Argon2I13  = prim__crypto_pwhash_alg_argon2i13
getHashAlgorithm Argon2ID13 = prim__crypto_pwhash_alg_argon2id13
getHashAlgorithm Default    = prim__crypto_pwhash_alg_default

defaultHashPrefix : String
defaultHashPrefix = prim__crypto_pwhash_strprefix

||| The length of a salt for Sodium's password hashing and key derivation
||| routines.
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

||| Lower level abstraction that exposes the raw key derivation routine.
export
derivePassKeyImmediate : HasIO io =>
                        AnyPtr -> Bits64 ->
                        String ->
                        AnyPtr ->
                        HashLimit -> HashLimit -> HashAlgorithm -> io Int
derivePassKeyImmediate out outLen passwd salt ops mem alg = 
  let opsLimit = getOpLimit ops
      memLimit = getMemLimit mem
      algID    = getHashAlgorithm alg
      passLen  = strLength passwd
  in primIO $ prim__hashPassword out outLen
                                 passwd (cast passLen)
                                 salt
                                 opsLimit memLimit algID
                        

-- High Level, SecureBuffer Based Password Key Derivation --

||| The PassKey record. Contains the key itself as well as the hash, stringPrefix,
||| algorithm, opLimit, and memLimit of the derivation.
public export
record PassKey where
  constructor MkPassKey
  key          : SecureBuffer
  salt         : SecureBuffer
  stringPrefix : String
  algorithm    : HashAlgorithm
  opLimit      : HashLimit
  memLimit     : HashLimit

||| Displays a PassKey in a string representation that can be parsed back
||| into a PassKey later.
export
Show PassKey where
  show pwHash = let h = bufferAsHex $ key pwHash
                    s = bufferAsHex $ salt pwHash
                    p = stringPrefix pwHash
                    a = show $ getHashAlgorithm $ algorithm pwHash
                    o = show $ getOpLimit $ opLimit pwHash
                    m = show $ getMemLimit $ memLimit pwHash
                in p ++ s ++ "$" ++ h ++ "$" ++ a ++ "$" ++ o ++ "$" ++ m

private
newSalt : HasIO io => io SecureBuffer
newSalt = do
  buffer <- newSecureBuffer saltLength
  _      <- randomizeBuffer buffer
  liftIO $ pure $ buffer

||| Derives a PassKey from the given settings and password string.
||| A PassKey is a record that contains the raw key (stored within
||| a secure buffer), as well as the salt and all configuration settings
||| used to derive the key.
|||
||| @ HashLimit     The operation limit of the derivation.
||| @ HashLimit     The memory limit of the derivation.
||| @ HashAlgorithm The algorithm to derive the key with.
||| @ Bits64        The size of the final key.
||| @ String        The password to derive the key from.
export
deriveKey : HasIO io =>
            HashLimit -> HashLimit -> HashAlgorithm -> Bits64 -> String ->
            io (Maybe PassKey)
deriveKey ops mem algo keySize passwd = do 
  out     <- newSecureBuffer keySize
  salt    <- newSalt
  outcome <- derivePassKeyImmediate (rawPointer out) (length out)
                                    passwd (rawPointer salt)
                                    ops mem algo
  liftIO $ pure (if outcome == 0
                 then Just (MkPassKey out salt defaultHashPrefix algo ops mem)
                 else Nothing)

||| Derives a PassKey according to Interactive limit settings.
|||
||| @ HashAlgorithm The algorithm to derive the key with.
||| @ Bits64        The size of the final key.
||| @ String        The password to derive the key from.
export
deriveKeyInteractive : HasIO io => HashAlgorithm -> Bits64 -> String ->
                       io (Maybe PassKey)
deriveKeyInteractive = deriveKey Interactive Interactive

||| Derives a PassKey according to Moderate limit settings.
|||
||| @ HashAlgorithm The algorithm to derive the key with.
||| @ Bits64        The size of the final key.
||| @ String        The password to derive the key from.
export
deriveKeyModerate : HasIO io => HashAlgorithm -> Bits64 -> String ->
                    io (Maybe PassKey)
deriveKeyModerate = deriveKey Moderate Moderate

||| Derives a PassKey according to Sensitive limit settings.
|||
||| @ HashAlgorithm The algorithm to derive the key with.
||| @ Bits64        The size of the final key.
||| @ String        The password to derive the key from.
export
deriveKeySensitive : HasIO io => HashAlgorithm -> Bits64 -> String ->
                     io (Maybe PassKey)
deriveKeySensitive = deriveKey Sensitive Sensitive

||| Marks the given PassKey as no access.
export
noAccessKey : HasIO io => PassKey -> io Bool
noAccessKey pwHash = do
  o1 <- noAccessBuffer (key pwHash)
  o2 <- noAccessBuffer (salt pwHash)
  liftIO $ pure $ o1 && o2

||| Marks the given PassKey as Read only.
export
readOnlyKey : HasIO io => PassKey -> io Bool
readOnlyKey pwHash = do
  o1 <- readOnlyBuffer (key pwHash)
  o2 <- readOnlyBuffer (salt pwHash)
  liftIO $ pure $ o1 && o2

||| Marks the given PassKey as Read/Write.
export
readWriteKey : HasIO io => PassKey -> io Bool
readWriteKey pwHash = do
  o1 <- readWriteBuffer (key pwHash)
  o2 <- readWriteBuffer (salt pwHash)
  liftIO $ pure $ o1 && o2

export
Protected PassKey where
  noAccess  = noAccessKey
  readOnly  = readOnlyKey
  readWrite = readWriteKey

-- High Level, Password Hashing --

||| Hashes the given password alongside the given strength limits.
|||
||| TODO: Contemplate if this should be moved into the shim. If it is,
|||       one could argue to forego the IO component. While side effects
|||       technically take place within the function, they are restricted
|||       to the function and shouldn't affect the world overall. This is
|||       especially true if moved to the shim, as the strBuf could then be
|||       stack allocated.
|||
||| @ HashLimit The operation limit of the hashing.
||| @ HashLimit The memory limit of the hashing.
||| @ String    The password to hash.
export
hashPassword : HasIO io => HashLimit -> HashLimit -> String -> io (Maybe String)
hashPassword ops mem passwd =
  let ol = getOpLimit  ops
      ml = getMemLimit mem
      sl = length passwd
  in do
    strBuf <- allocateMemory prim__crypto_pwhash_strbytes
    res    <- primIO $ prim__crypto_pwhash_str strBuf passwd (cast sl) ol ml
    liftIO $ case cBool res of
      True  => let str = prim__stringify strBuf
               in do
                 freeMemory strBuf
                 pure $ Just str
      False => do freeMemory strBuf
                  pure Nothing

||| Hashes a password with Interactive limit settings.
export
hashPasswordInteractive : HasIO io => String -> io (Maybe String)
hashPasswordInteractive = hashPassword Interactive Interactive

||| Hashes a password with Moderate limit settings.
export
hashPasswordModerate : HasIO io => String -> io (Maybe String)
hashPasswordModerate = hashPassword Moderate Moderate

||| Hashes a password with Sensitive limit settings.
export
hashPasswordSensitive : HasIO io => String -> io (Maybe String)
hashPasswordSensitive = hashPassword Sensitive Sensitive

||| Verifies that the given password matches the provided password hash.
|||
||| TODO: Determine if this needs IO. The world does not necessarily change
|||       when the primitive is called, but it does a lot of side effects
|||       behind the scenes. Something worth a debate.
|||
||| @ String The password hash to validate with.
||| @ String The password to validate.
export
verifyPassword : String -> String -> Bool
verifyPassword hash passwd =
  cBool $ prim__crypto_pwhash_str_verify hash passwd (cast $ length passwd)

||| Determines whether or not the given password hash requires rehashing.
export
passwordNeedsRehash : String -> HashLimit -> HashLimit -> Bool
passwordNeedsRehash hash ops mem = 
  let ol = getOpLimit  ops
      ml = getMemLimit mem
  in cBool $ prim__crypto_pwhash_str_needs_rehash hash ol ml
