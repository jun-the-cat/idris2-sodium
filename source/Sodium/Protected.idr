module Sodium.Protected

||| Data protection modes, for use with setMemoryProtection.
||| 
||| NoAccess  = Memory region cannot be read or written to.
||| ReadOnly  = Memory can be read to, but not written to.
||| ReadWrite = Memory has full privileges.
public export
data ProtectionMode = NoAccess | ReadOnly | ReadWrite

||| Mock interface for enforcing the correct permissions on
||| a function boundary. For Read permissions.
export
interface CanRead (mode : ProtectionMode) where
  canRead : Bool
  canRead = True

||| Mock interface for enforcing the correct permissions on
||| a function boundary. For Write permissions. 
export 
interface CanWrite (mode : ProtectionMode) where
  canWrite : Bool
  canWrite = True

export
CanRead  ReadOnly where
  canRead = True
  
export
CanRead  ReadWrite where
  canRead = True

export
CanWrite ReadWrite where
  canWrite = True

-- Interface to allow easy mprotect permission changes --

||| Standard way to adjust the protection of a data type.
public export
interface Protected (0 object : ProtectionMode -> Type) where
  ||| Marks the given object as NoAccess.
  noAccess       : HasIO io => object mode -> io (Maybe (object NoAccess))
  ||| Marks the given object as ReadOnly.
  readOnly       : HasIO io => object mode -> io (Maybe (object ReadOnly))
  ||| Marks the given object as ReadWrite.
  readWrite      : HasIO io => object mode -> io (Maybe (object ReadWrite))
  
  ||| For the scope of `f`, the object will be in the protection mode
  ||| specified by `pf`.
  private
  withProtection : HasIO io =>
                   (object am -> io (Maybe (object pm))) ->
                   object am -> (object pm -> b) -> io (Maybe b)
  withProtection pf a1 f = do
    success <- pf a1
    liftIO $ case success of
      Nothing => pure Nothing
      Just a2 =>
        let result = f a2
        in do
          success <- noAccess a2
          pure $ case success of
            Nothing => Nothing
            Just _  => Just result
  
  private
  withProtectionIO : HasIO io =>
                     (object am -> io (Maybe (object pm))) ->
                     object am -> (object pm -> io b) -> io (Maybe b)
  withProtectionIO pf a1 f = do
    success <- pf a1
    case success of
      Nothing => pure Nothing
      Just a2 => do
        result  <- f a2
        success <- noAccess a2
        pure $ case success of
          Nothing => Nothing
          Just _  => Just result

  ||| Marks the object as NoAccess for the scope of `f`.
  withNoAccess   : HasIO io => object mode -> (object NoAccess -> b) -> io (Maybe b)
  withNoAccess   = withProtection noAccess
  
  withNoAccessIO : HasIO io => object mode -> (object NoAccess -> io b) -> io (Maybe b)
  withNoAccessIO = withProtectionIO noAccess
  
  ||| Marks the object as ReadOnly for the scope of `f`.
  withReadOnly   : HasIO io => object mode -> (object ReadOnly -> b) -> io (Maybe b)
  withReadOnly   = withProtection readOnly
  
  withReadOnlyIO : HasIO io => object mode -> (object ReadOnly -> io b) -> io (Maybe b)
  withReadOnlyIO = withProtectionIO readOnly
  
  ||| Marks the object as ReadWrite for the scope of `f`.
  withReadWrite   : HasIO io => object mode -> (object ReadWrite -> b) -> io (Maybe b)
  withReadWrite   = withProtection readWrite
  
  withReadWriteIO : HasIO io => object mode -> (object ReadWrite -> io b) -> io (Maybe b)
  withReadWriteIO = withProtectionIO readWrite
