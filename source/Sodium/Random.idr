module Sodium.Random

import Sodium.Primitives

export
randomInteger : HasIO io => io Bits32
randomInteger = primIO $ prim__randomInteger

export
randomUniformInteger : HasIO io => Bits32 -> io Bits32
randomUniformInteger upperBound = primIO $ prim__uniformInteger upperBound
