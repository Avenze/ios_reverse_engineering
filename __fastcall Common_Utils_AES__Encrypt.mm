System_String_o *__fastcall Common_Utils_AES__Encrypt(
        System_String_o *plainText,
        System_String_o *password,
        System_String_o *salt,
        System_String_o *initialVector,
        const MethodInfo *method)
{
  __int64 v9; // x1
  __int64 v10; // x2
  System_Byte_array *v11; // x19

  if ( (byte_6CE48D1 & 1) == 0 )
  {
    sub_4BFD544(&Common_Utils_AES_TypeInfo, password, salt);
    sub_4BFD544(&System_Convert_TypeInfo, v9, v10);
    byte_6CE48D1 = 1;
  }
  if ( (*(_WORD *)&Common_Utils_AES_TypeInfo->_2.bitflags1 & 0x400) != 0
    && !Common_Utils_AES_TypeInfo->_2.cctor_finished )
  {
    j__il2cpp_runtime_class_init_0();
  }
  v11 = Common_Utils_AES__EncryptToBytes(plainText, password, salt, initialVector, method);
  if ( (*(_WORD *)&System_Convert_TypeInfo->_2.bitflags1 & 0x400) != 0 && !System_Convert_TypeInfo->_2.cctor_finished )
    j__il2cpp_runtime_class_init_0();
  return System_Convert__ToBase64String(v11, 0);
}