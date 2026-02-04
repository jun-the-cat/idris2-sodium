module Sodium.SecureBuffer

import Data.String
import Data.Bits

import Sodium.Primitives
import Sodium.Memory
import Sodium.Random

import public Sodium.Protected

%default total

||| A secure, runtime managed memory buffer. By default, the memory region
||| this record represents is marked as Read/Write.
public export
record SecureBuffer (mode : ProtectionMode) where
  constructor MkSecureBuffer
  pointer : GCAnyPtr
  length  : Bits64

||| Gets the buffer's underlying pointer as an AnyPtr, for interop with foreign
||| calls.
export
rawPointer : SecureBuffer _ -> AnyPtr
rawPointer buffer = cast $ pointer buffer

||| Constructs a new secure buffer with the given size.
||| The memory region is locked and marked as no access.
|||
||| @ Bits64 The size of the new secure buffer.
export
newSecureBuffer : HasIO io => (mode: ProtectionMode) -> Bits64 -> io (SecureBuffer mode)
newSecureBuffer mode size = do
  ptr <- allocateTrackedMemory size
  _   <- lockMemory (cast ptr) size
  _   <- setMemoryAccess mode (cast ptr)
  liftIO $ pure $ MkSecureBuffer ptr size

||| Peeks into the secure buffer, returning the byte at the given index.
||| Requires Read privileges.
|||
||| @ Bits64 The index to peek into the buffer at.
export
peek : CanRead mode => SecureBuffer mode -> Bits64 -> Bits8
peek (MkSecureBuffer ptr size) index = 
  let raw = cast ptr
  in prim__peek raw index size

||| Pokes a new value into the secure buffer, returning the old value.
||| Requires Read/Write privileges.
|||
||| @ Bits64 The index to poke the new value into.
||| @ Bits8  The new value that will be put into that memory space.
export
poke : CanWrite mode => HasIO io => SecureBuffer mode -> Bits64 -> Bits8 -> io Bits8
poke (MkSecureBuffer ptr size) index value =
  let raw = cast ptr
  in primIO $ prim__poke raw index value size

private
changeAccess : HasIO io =>
               (AnyPtr -> io Bool) -> SecureBuffer m1 -> io (Maybe (SecureBuffer m2))
changeAccess accessFn (MkSecureBuffer ptr len) = 
    let raw = cast    ptr
    in do
      success <- accessFn raw
      pure (if success 
        then Just $ MkSecureBuffer ptr len
        else Nothing)

export
Protected SecureBuffer where
  noAccess  = changeAccess noAccessMemory
  readOnly  = changeAccess readOnlyMemory
  readWrite = changeAccess readWriteMemory

||| Zeroes the given secure buffer.
export
zeroBuffer : CanWrite mode => HasIO io => SecureBuffer mode -> io Bits64
zeroBuffer (MkSecureBuffer ptr size) = zeroMemory size (cast ptr)

||| Fills a buffer with random bytes.
export
randomizeBuffer : CanWrite mode => HasIO io => SecureBuffer mode -> io Bits64
randomizeBuffer (MkSecureBuffer ptr size) = randomMemory size (cast ptr)

||| Pads the data present in the secure buffer.
|||
||| @ SecureBuffer The buffer that contains the unpadded data.
||| @ Bits64       The length of the data region inside the buffer.
||| @ Bits64       The block size to pad to.
export
padBuffer : HasIO io => SecureBuffer ReadWrite -> Bits64 -> Bits64 -> io Bits64
padBuffer (MkSecureBuffer ptr size) len blockSize =
  let ptr = cast ptr
  in padMemory ptr len blockSize size

||| Unpads the data present inside the secure buffer.
|||
||| @ SecureBuffer The buffer that contains the padded data.
||| @ Bits64       The length of the data region inside the buffer.
||| @ Bits64       The block size of the padded data.
export
unpadBuffer : HasIO io => SecureBuffer ReadWrite -> Bits64 -> Bits64 -> io Bits64
unpadBuffer (MkSecureBuffer ptr _) len blockSize = 
  let ptr = cast ptr
  in unpadMemory ptr len blockSize

-- Higher Order Abstractions --
-------------------------------

private
hexLookup : String
hexLookup = "0123456789ABCDEF"

private
byteToHex : Bits8 -> String
byteToHex byte = let hi     = shiftR byte 4
                     lo     = byte .&. 0x0F
                     hiChar = strSubstr (cast hi) 1 hexLookup
                     loChar = strSubstr (cast lo) 1 hexLookup
                 in hiChar ++ loChar

private
bufferToString : CanRead mode => SecureBuffer mode -> Bits64 -> List String -> String
bufferToString buffer 0 lst =
  let val = peek buffer 0
  in concat $ (byteToHex val :: lst)
bufferToString buffer i lst = 
  let val = peek buffer i
  in bufferToString buffer
                    (assert_smaller i $ i - 1) 
                    (byteToHex val :: lst)

export
bufferAsHex : CanRead mode => SecureBuffer mode -> String
bufferAsHex buffer = bufferToString buffer (length buffer - 1) []

export
CanRead mode => Show (SecureBuffer mode) where
  show buffer = let size  = length buffer
                    value = bufferToString buffer (size - 1) []
                in "SecureBuffer[" ++ value ++ "] (Length: " ++ show size ++ ")"
