module Sodium.SecretBox

import Sodium.Primitives

import Sodium.SecureBuffer
import Sodium.KeyManagement

SecretBoxKeySize : Nat
SecretBoxKeySize = cast prim__crypto_secretbox_keybytes

newSecretBoxKey : HasIO io =>
                  (mode : ProtectionMode) -> io (Maybe (Key SecretBoxKeySize mode))
newSecretBoxKey = generateKey SecretBoxKeySize
