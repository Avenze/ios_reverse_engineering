void __fastcall Game_Plat_IOS_IOSWapper__OnIOSMessage(
        Game_Plat_IOS_IOSWapper_o *this,
        System_String_o *message,
        const MethodInfo *method)
{
  __int64 v4; // x1
  __int64 v5; // x2
  __int64 v6; // x1
  __int64 v7; // x2
  __int64 v8; // x1
  __int64 v9; // x2
  Common_Utils_XLuaManager_o *Instance; // x20
  __int64 v11; // x0
  System_Object_array *v12; // x21
  __int64 v13; // x0

  if ( (byte_6CE511A & 1) == 0 )
  {
    sub_4BFD544(&object___TypeInfo, message, method);
    sub_4BFD544(&Method_Common_Template_UGlobalSingleton_XLuaManager__get_Instance__, v4, v5);
    sub_4BFD544(&Common_Template_UGlobalSingleton_XLuaManager__TypeInfo, v6, v7);
    sub_4BFD544(&StringLiteral_3773, v8, v9);
    byte_6CE511A = 1;
  }
  if ( (*(_WORD *)&Common_Template_UGlobalSingleton_XLuaManager__TypeInfo->_2.bitflags1 & 0x400) != 0
    && !Common_Template_UGlobalSingleton_XLuaManager__TypeInfo->_2.cctor_finished )
  {
    j__il2cpp_runtime_class_init_0();
  }
  Instance = (Common_Utils_XLuaManager_o *)Common_Template_UGlobalSingleton_XLuaManager___get_Instance(
                                             Method_Common_Template_UGlobalSingleton_XLuaManager__get_Instance__,
                                             message,
                                             method);
  v11 = sub_4BFD554(object___TypeInfo, 2);
  if ( !v11 )
LABEL_16:
    sub_4BFD614();
  v12 = (System_Object_array *)v11;
  if ( StringLiteral_3773 && !sub_4BFD5FC(StringLiteral_3773, *(_QWORD *)(*(_QWORD *)v11 + 64LL)) )
    goto LABEL_17;
  if ( !LODWORD(v12->max_length) )
  {
LABEL_15:
    v13 = sub_4BFD640();
    goto LABEL_18;
  }
  v12->m_Items[0] = (Il2CppObject *)StringLiteral_3773;
  sub_4BFD4E8(v12->m_Items);
  if ( message )
  {
    if ( !sub_4BFD5FC(message, v12->obj.klass->_1.element_class) )
    {
LABEL_17:
      v13 = sub_4BFD634();
LABEL_18:
      sub_4BFD5E0(v13, 0);
    }
  }
  if ( (v12->max_length & 0xFFFFFFFE) == 0 )
    goto LABEL_15;
  v12->m_Items[1] = (Il2CppObject *)message;
  sub_4BFD4E8(&v12->m_Items[1]);
  if ( !Instance )
    goto LABEL_16;
  Common_Utils_XLuaManager__DispathcLuaEvent(Instance, v12, 0);
}