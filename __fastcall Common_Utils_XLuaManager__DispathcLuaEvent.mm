void __fastcall Common_Utils_XLuaManager__DispathcLuaEvent(
        Common_Utils_XLuaManager_o *this,
        System_Object_array *args,
        const MethodInfo *method)
{
  XLua_LuaFunction_o *m_pDispatcher; // x0

  m_pDispatcher = this->fields.m_pDispatcher;
  if ( m_pDispatcher )
    XLua_LuaFunction__Call_1565804(m_pDispatcher, args, 0);
}