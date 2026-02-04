module Sodium.Random

import Sodium.Primitives

||| Generates a random 32-bit unsigned integer.
export
randomInteger : HasIO io => io Bits32
randomInteger = primIO $ prim__randomInteger

||| Generates a random integer between 0 and upperBound, a 32-bit unsigned integer.
export
randomUniformInteger : HasIO io => Bits32 -> io Bits32
randomUniformInteger upperBound = primIO $ prim__uniformInteger upperBound

||| Fills the given memory region with random bytes, up to the given size.
export
randomMemory : HasIO io => Bits64 -> AnyPtr -> io Bits64
randomMemory size ptr = do
  primIO $ prim__randomBuffer ptr size
  pure size

||| Like randomBuffer, but allows a static seed. Usually only for testing.
export
deterministicRandomMemory : HasIO io => AnyPtr -> Bits64 -> AnyPtr -> io ()
deterministicRandomMemory ptr size seed =
  primIO $ prim__deterministicBuffer ptr size seed

