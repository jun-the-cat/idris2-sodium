module Sodium.Memory

import System.FFI

import Sodium.Primitives
import Sodium.Protected

-- Memory Allocation and Freeing, Including GC Tracking --

||| Frees memory allocated via the LibSodium allocation functions.
export
freeMemory : HasIO io => AnyPtr -> io ()
freeMemory ptr = primIO $ prim__freeMemory ptr

||| Frees a typed pointer through freeMemory.
export
forgetAndFreeMemory : HasIO io => Ptr t -> io ()
forgetAndFreeMemory ptr = freeMemory $ prim__forgetPtr ptr

||| Allocates untracked memory through LibSodium, must be freed with
||| freeMemory explicitly.
export
allocateMemory : HasIO io => Bits64 -> io AnyPtr
allocateMemory size = primIO $ prim__secureMalloc size

||| Allocated tracked memory, which will automatically be freed safely
||| on collection.
export
allocateTrackedMemory : HasIO io => Bits64 -> io GCAnyPtr
allocateTrackedMemory size = do
  ptr <- allocateMemory size
  onCollectAny ptr freeMemory

-- Memory Comparison --

||| Compares two memory regions for equality, up to the length
||| provided by Bits64. Returns True if equal, otherwise False.
export
compareMemory : AnyPtr -> AnyPtr -> Bits64 -> Bool
compareMemory ptr1 ptr2 size =
  if (prim__compareMemory ptr1 ptr2 size) == 0 then True
  else False

-- Memory Manipulation --

||| Zeroes the memory region provided by the memory address and size.
export
zeroMemory : HasIO io => Bits64 -> AnyPtr -> io Bits64
zeroMemory size ptr = do
  _ <- primIO $ prim__zeroMemory ptr size
  liftIO . pure $ size

-- Memory Locking and Unlocking --

||| Locks the given memory region, keeping it off of the disk.
export
lockMemory : HasIO io => AnyPtr -> Bits64 -> io Int
lockMemory ptr size = primIO $ prim__lockMemory ptr size

||| Unlocks the given memory region, allowing it to be put on disk.
export
unlockMemory : HasIO io => AnyPtr -> Bits64 -> io Int
unlockMemory ptr size = primIO $ prim__unlockMemory ptr size

-- Memory Protection --

||| Sets the given memory region to no access protections.
export
noAccessMemory : HasIO io => AnyPtr -> io Bool
noAccessMemory = cBoolIO . primIO . prim__memoryNoAccess

||| Sets the given memory region to read only protections.
export
readOnlyMemory : HasIO io => AnyPtr -> io Bool
readOnlyMemory = cBoolIO . primIO . prim__memoryReadOnly

||| Removes any memory protections from the given memory region.
export
readWriteMemory : HasIO io => AnyPtr -> io Bool
readWriteMemory = cBoolIO . primIO . prim__memoryReadWrite

export
setMemoryAccess : HasIO io => ProtectionMode -> AnyPtr -> io Bool
setMemoryAccess NoAccess  = noAccessMemory
setMemoryAccess ReadOnly  = readOnlyMemory
setMemoryAccess ReadWrite = readWriteMemory

-- Memory Padding and Unpadding Routines --

||| Pad the given memory region up to the given block size.
export
padMemory : HasIO io => AnyPtr -> Bits64 -> Bits64 -> Bits64 -> io Bits64
padMemory ptr len bs max = primIO $ prim__padBuffer ptr len bs max

||| Unpads the given memory region back to its original size.
export
unpadMemory : HasIO io => AnyPtr -> Bits64 -> Bits64 -> io Bits64
unpadMemory ptr len bs = primIO $ prim__unpadBuffer ptr len bs
