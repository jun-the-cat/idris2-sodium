#include "shim.h"

/**
 * Wrapper around "sodium_pad" that returns the padded length, instead of passing it
 * through a pointer. This allows Idris code to actually use the returned length.
 */
size_t
shim_pad(unsigned char *buf,
         size_t unpadded_buf_len,
         size_t block_size,
         size_t max_buf_len)
{
  size_t padded_buf_len;

  if (sodium_pad(&padded_buf_len, buf, unpadded_buf_len, block_size, max_buf_len) != 0)
    return 0;

  return padded_buf_len;
}

/**
 * Wrapper around "sodium_unpad" that returns the unpadded length, to allow use in
 * Idris code.
 */
size_t
shim_unpad(unsigned char *buf,
           size_t padded_buf_len,
           size_t block_size)
{
  size_t unpadded_buf_len;

  if (sodium_unpad(&unpadded_buf_len, buf, padded_buf_len, block_size) != 0)
    return 0;

  return unpadded_buf_len;
}

/**
 * Used to unwrap GCAnyPtr and GCPtr t in Idris, as there seems to be no way otherwise.
 */
void *
shim_unwrap_gc(void * const pointer)
{
  return pointer;
}

/**
 * Forcibly converts a pointer to a string, which will then be copied into the
 * Idris runtime. Therefore, if this pointer is not GC'd it MUST BE FREED MANUALLY.
 */
char *
shim_stringify(void * const pointer) 
{
  return (char *) pointer;
}

/**
 * Peek into the given pointer, returning the relevant byte.
 */
uint8_t
shim_peek(char * const pointer, size_t index, size_t size)
{
  if (index >= size) return 0;
  return pointer[index];
}

/**
 * Poke a new value into the given pointer, returning the old value.
 */
uint8_t
shim_poke(char * pointer, size_t index, uint8_t value, size_t size)
{
  uint8_t old;
  if (index >= size) return 0;

  old = pointer[index];
  pointer[index] = value;
  return old;
}
