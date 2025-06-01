System_String_o *__fastcall Common_Utils_AES__Decrypt(
        System_String_o *cipherText,
        System_String_o *password,
        System_String_o *salt,
        System_String_o *initialVector,
        const MethodInfo *method)
{
  System_String_o *v7; // x21
  __int64 v8; // x1
  __int64 v9; // x2
  __int64 v10; // x1
  __int64 v11; // x2
  System_String_o *v12; // x21
  System_String_o *v13; // x2
  const MethodInfo *v14; // x4
  System_Byte_array *v15; // x21
  System_String_o *v16; // x19

  v7 = cipherText;
  if ( (byte_6CE48D4 & 1) == 0 )
  {
    sub_4BFD544(&Common_Utils_AES_TypeInfo, password, salt);
    sub_4BFD544(&char___TypeInfo, v8, v9);
    cipherText = (System_String_o *)sub_4BFD544(&System_Convert_TypeInfo, v10, v11);
    byte_6CE48D4 = 1;
  }
  if ( !v7 )
    goto LABEL_12;
  v12 = System_String__Replace(v7, 0x20u, 0x2Bu, 0);
  if ( (*(_WORD *)&System_Convert_TypeInfo->_2.bitflags1 & 0x400) != 0 && !System_Convert_TypeInfo->_2.cctor_finished )
    j__il2cpp_runtime_class_init_0();
  v15 = System_Convert__FromBase64String(v12, 0);
  if ( (*(_WORD *)&Common_Utils_AES_TypeInfo->_2.bitflags1 & 0x400) != 0
    && !Common_Utils_AES_TypeInfo->_2.cctor_finished )
  {
    j__il2cpp_runtime_class_init_0();
  }
  v16 = Common_Utils_AES__Decrypt_137260(v15, password, v13, initialVector, v14);
  cipherText = (System_String_o *)sub_4BFD554(char___TypeInfo, 1);
  if ( !v16 )
LABEL_12:
    sub_4BFD614(cipherText, password, salt, initialVector, method);
  return System_String__TrimEnd(v16, (System_Char_array *)cipherText, 0);
}