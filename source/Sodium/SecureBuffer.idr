module Sodium.SecureBuffer

import Data.String
import Data.Bits

import Sodium.Primitives
import Sodium.Memory
import Sodium.Random

%default total

||| A secure, runtime managed memory buffer. By default, the memory region
||| this record represents is marked as ReadOnly.
public export
record SecureBuffer where
  constructor MkSecureBuffer
  pointer : GCAnyPtr
  length  : Bits64

||| Constructs a new secure buffer with the given size.
||| The memory region is locked and marked as no access.
|||
||| @ Bits64 The size of the new secure buffer.
export
newSecureBuffer : HasIO io => Bits64 -> io SecureBuffer
newSecureBuffer size = do
  ptr <- allocateTrackedMemory size
  _   <- lockMemory (cast ptr) size
  _   <- readOnlyMemory (cast ptr)
  liftIO $ pure $ MkSecureBuffer ptr size

||| Peeks into the secure buffer, returning the byte at the given index.
||| Requires Read privileges.
|||
||| @ Bits64 The index to peek into the buffer at.
export
peek : SecureBuffer -> Bits64 -> Bits8
peek (MkSecureBuffer ptr size) index = 
  let raw = cast ptr
  in prim__peek raw index size

||| Pokes a new value into the secure buffer, returning the old value.
||| Requires Read/Write privileges.
|||
||| @ Bits64 The index to poke the new value into.
||| @ Bits8  The new value that will be put into that memory space.
export
poke : HasIO io => SecureBuffer -> Bits64 -> Bits8 -> io Bits8
poke (MkSecureBuffer ptr size) index value =
  let raw = cast ptr
  in primIO $ prim__poke raw index value size

||| Marks the secure buffer for no access, revoking all permissions.
export
noAccessBuffer : HasIO io => SecureBuffer -> io Int
noAccessBuffer (MkSecureBuffer ptr _) = let raw = cast ptr
                                        in noAccessMemory raw

||| Marks the secure buffer as read only, disallowing writes.
export
readOnlyBuffer : HasIO io => SecureBuffer -> io Int
readOnlyBuffer (MkSecureBuffer ptr _) = let raw = cast ptr
                                        in readOnlyMemory raw

||| Enables read and write permissions on the secure buffer.
export
readWriteBuffer : HasIO io => SecureBuffer -> io Int
readWriteBuffer (MkSecureBuffer ptr _) = let raw = cast ptr
                                         in readWriteMemory raw

||| Zeroes the given secure buffer. Requires Read/Write privileges.
export
zeroBuffer : HasIO io => SecureBuffer -> io ()
zeroBuffer (MkSecureBuffer ptr size) = let raw = cast ptr
                                       in zeroMemory raw size

||| Fills a buffer with random bytes.
export
randomizeBuffer : HasIO io => SecureBuffer -> io ()
randomizeBuffer (MkSecureBuffer ptr size) = let raw = cast ptr
                                            in randomMemory raw size

||| Pads the data present in the secure buffer.
|||
||| @ SecureBuffer The buffer that contains the unpadded data.
||| @ Bits64       The length of the data region inside the buffer.
||| @ Bits64       The block size to pad to.
export
padBuffer : HasIO io => SecureBuffer -> Bits64 -> Bits64 -> io Bits64
padBuffer (MkSecureBuffer ptr size) len blockSize =
  let rawPtr = cast ptr
  in padMemory rawPtr len blockSize size

||| Unpads the data present inside the secure buffer.
|||
||| @ SecureBuffer The buffer that contains the padded data.
||| @ Bits64       The length of the data region inside the buffer.
||| @ Bits64       The block size of the padded data.
export
unpadBuffer : HasIO io => SecureBuffer -> Bits64 -> Bits64 -> io Bits64
unpadBuffer (MkSecureBuffer ptr _) len blockSize = 
  let rawPtr = cast ptr
  in unpadMemory rawPtr len blockSize

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
bufferToString : (sb : SecureBuffer) -> Bits64 -> List String -> String
bufferToString buffer 0 lst =
  let val = peek buffer 0
  in concat $ (byteToHex val :: lst)
bufferToString buffer i lst = 
  let val = peek buffer i
  in bufferToString buffer
                    (assert_smaller i $ i - 1) 
                    (byteToHex val :: lst)

export
Show SecureBuffer where
  show buffer = let size  = length buffer
                    value = bufferToString buffer (size - 1) []
                in "SecureBuffer[" ++ value ++ "] (Length: " ++ show size ++ ")"
