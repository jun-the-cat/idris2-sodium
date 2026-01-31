||| Direct FFI bindings to LibSodium
module Sodium.Primitives

import Data.Bits

-- Initialization Bindings

||| Helper function to define FFI bindings, takes in a function
||| name and outputs the correct FFI String for use with %foreign.
|||
||| @ fn The relevant function name to bind to.
libsodium : String -> String
libsodium fn = "C:" ++ fn ++ ",libsodium,sodium.h"

||| Primitive binding to initialize LibSodium, returns an integer.
%foreign (libsodium "sodium_init")
export
prim__initSodium : PrimIO Int

-- Encoding Bindings

||| Encodes the provided byte array as a hex string, in the provided string.
%foreign (libsodium "sodium_bin2hex")
export
prim__binToHex : String -> Bits64 -> AnyPtr -> Bits64 -> String

||| Decodes the provided hex string into the provided pointer.
%foreign (libsodium "sodium_hex2bin")
export
prim__hexToBin : AnyPtr -> Bits64 -> String -> Bits64 -> String -> Bits64 -> AnyPtr -> Int

-- Memory Bindings

||| Constant time memory comparison algorithm.
%foreign (libsodium "sodium_memcmp")
export
prim__compareMemory : AnyPtr -> AnyPtr -> Bits64 -> Int

%foreign (libsodium "sodium_memzero")
export
prim__zeroMemory : AnyPtr -> Bits64 -> PrimIO ()

%foreign (libsodium "sodium_mlock")
export
prim__lockMemory : AnyPtr -> Bits64 -> PrimIO Int

%foreign (libsodium "sodium_munlock")
export
prim__unlockMemory : AnyPtr -> Bits64 -> PrimIO Int

%foreign (libsodium "sodium_malloc")
export
prim__secureMalloc : Bits64 -> PrimIO AnyPtr

%foreign (libsodium "sodium_allocarray")
export
prim__allocateArray : Bits64 -> Bits64 -> PrimIO AnyPtr

%foreign (libsodium "sodium_free")
export
prim__freeMemory : AnyPtr -> PrimIO ()

%foreign (libsodium "sodium_mprotect_noaccess")
export
prim__memoryNoAccess : AnyPtr -> PrimIO Int

%foreign (libsodium "sodium_mprotect_readonly")
export
prim__memoryReadOnly : AnyPtr -> PrimIO Int

%foreign (libsodium "sodium_mprotect_readwrite")
export
prim__memoryReadWrite : AnyPtr -> PrimIO Int

-- Randomness Bindings

%foreign (libsodium "randombytes_random")
export
prim__randomInteger : PrimIO Bits32

%foreign (libsodium "randombytes_uniform")
export
prim__uniformInteger : Bits32 -> PrimIO Bits32

%foreign (libsodium "randombytes_buf")
export
prim__randomBuffer : AnyPtr -> Bits64 -> PrimIO ()

%foreign (libsodium "randombytes_buf_deterministic")
export
prim__deterministicBuffer : AnyPtr -> Bits64 -> AnyPtr -> PrimIO ()

export
prim__randomSeedSize : Bits32
prim__randomSeedSize = 32

-- Shim Bindings

libshim : String -> String
libshim fn = "C:" ++ fn ++ ",libshim,shim.h"

%foreign (libshim "shim_pad")
export
prim__padBuffer : AnyPtr -> Bits64 -> Bits64 -> Bits64 -> PrimIO Bits64

%foreign (libshim "shim_unpad")
export
prim__unpadBuffer : AnyPtr -> Bits64 -> Bits64 -> PrimIO Bits64

%foreign (libshim "shim_unwrap_gc")
export
prim__unwrapAnyPtr : GCAnyPtr -> AnyPtr

%foreign (libshim "shim_unwrap_gc")
export
prim__unwrapPtr : GCPtr t -> Ptr t

%foreign (libshim "shim_peek")
export
prim__peek : AnyPtr -> Bits64 -> Bits64 -> Bits8

%foreign (libshim "shim_poke")
export
prim__poke : AnyPtr -> Bits64 -> Bits8 -> Bits64 -> PrimIO Bits8

-- Pointer conversion.

public export
Cast GCAnyPtr AnyPtr where
  cast f = prim__unwrapAnyPtr f

public export
Cast (GCPtr t) (Ptr t) where
  cast f = prim__unwrapPtr f
