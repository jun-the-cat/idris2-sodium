module Sodium.Memory

import Sodium.Primitives
import System.FFI

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

||| Data protection modes, for use with setMemoryProtection.
||| 
||| NoAccess  = Memory region cannot be read or written to.
||| ReadOnly  = Memory can be read to, but not written to.
||| ReadWrite = Memory has full privileges.
public export
data ProtectionMode = NoAccess | ReadOnly | ReadWrite

||| Sets the memory protection for the given memory region.
export
setMemoryProtection : HasIO io => ProtectionMode -> AnyPtr -> io Bool
setMemoryProtection NoAccess  ptr = cBoolIO $ primIO $ prim__memoryNoAccess ptr
setMemoryProtection ReadOnly  ptr = cBoolIO $ primIO $ prim__memoryReadOnly ptr
setMemoryProtection ReadWrite ptr = cBoolIO $ primIO $ prim__memoryReadWrite ptr

||| Sets the given memory region to no access protections.
export
noAccessMemory : HasIO io => AnyPtr -> io Bool
noAccessMemory = setMemoryProtection NoAccess

||| Sets the given memory region to read only protections.
export
readOnlyMemory : HasIO io => AnyPtr -> io Bool
readOnlyMemory = setMemoryProtection ReadOnly

||| Removes any memory protections from the given memory region.
export
readWriteMemory : HasIO io => AnyPtr -> io Bool
readWriteMemory = setMemoryProtection ReadWrite

-- Memory Padding and Unpadding Routines --

||| Pad the given memory region up to the given block size.
export
padMemory : HasIO io => AnyPtr -> Bits64 -> Bits64 -> Bits64 -> io Bits64
padMemory ptr len bs max = primIO $ prim__padBuffer ptr len bs max

||| Unpads the given memory region back to its original size.
export
unpadMemory : HasIO io => AnyPtr -> Bits64 -> Bits64 -> io Bits64
unpadMemory ptr len bs = primIO $ prim__unpadBuffer ptr len bs

-- Interface to allow easy mprotect permission changes --

||| Standard way to adjust the protection of a data type.
public export
interface Protected a where
  ||| Marks the given object as NoAccess.
  noAccess       : HasIO io => a -> io Bool
  ||| Marks the given object as ReadOnly.
  readOnly       : HasIO io => a -> io Bool
  ||| Marks the given object as ReadWrite.
  readWrite      : HasIO io => a -> io Bool
  
  ||| For the scope of `f`, the object will be in the protection mode
  ||| specified by `pf`.
  withProtection : HasIO io => (a -> io Bool) -> a -> (a -> b) -> io (Maybe b)
  withProtection pf a1 f = do
    success <- pf a1
    liftIO $ case success of
      False => pure Nothing
      True  =>
        let result = f a1
        in do
          success <- noAccess a1
          pure $ case success of
            False => Nothing
            True  => Just result
  
  withProtectionIO : HasIO io => (a -> io Bool) -> a -> (a -> io b) -> io (Maybe b)
  withProtectionIO pf a1 f = do
    success <- pf a1
    case success of
      False => pure Nothing
      True  => do
        result  <- f a1
        success <- noAccess a1
        pure $ case success of
          False => Nothing
          True  => Just result

  ||| Marks the object as NoAccess for the scope of `f`.
  withNoAccess   : HasIO io => a -> (a -> b) -> io (Maybe b)
  withNoAccess   = withProtection noAccess
  
  withNoAccessIO : HasIO io => a -> (a -> io b) -> io (Maybe b)
  withNoAccessIO = withProtectionIO noAccess
  
  ||| Marks the object as ReadOnly for the scope of `f`.
  withReadOnly   : HasIO io => a -> (a -> b) -> io (Maybe b)
  withReadOnly   = withProtection readOnly
  
  withReadOnlyIO : HasIO io => a -> (a -> io b) -> io (Maybe b)
  withReadOnlyIO = withProtectionIO readOnly
  
  ||| Marks the object as ReadWrite for the scope of `f`.
  withReadWrite   : HasIO io => a -> (a -> b) -> io (Maybe b)
  withReadWrite   = withProtection readWrite
  
  withReadWriteIO : HasIO io => a -> (a -> io b) -> io (Maybe b)
  withReadWriteIO = withProtectionIO readWrite

export
Protected AnyPtr where
  noAccess  = noAccessMemory
  readOnly  = readOnlyMemory
  readWrite = readWriteMemory

export  
Protected GCAnyPtr where
  noAccess  = noAccessMemory . cast
  readOnly  = readOnlyMemory . cast
  readWrite = readWriteMemory . cast
