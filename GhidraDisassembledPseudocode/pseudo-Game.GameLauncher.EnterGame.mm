void Game.GameLauncher$$EnterGame(long param_1,int param_2)

{
  long lVar1;
  
  if ((DAT_06ce5090 & 1) == 0) {
    thunk_FUN_04c5fbcc(&Game.Plat.DeviceUtil_TypeInfo);
    thunk_FUN_04c5fbcc(&Method$Common.Template.Singleton<ResManager>.get_Instance());
    thunk_FUN_04c5fbcc(&Method$Common.Template.Singleton<LocalizationManager>.get_Instance());
    thunk_FUN_04c5fbcc(&Common.Template.Singleton<LocalizationManager>_TypeInfo);
    thunk_FUN_04c5fbcc(&Common.Template.Singleton<ResManager>_TypeInfo);
    thunk_FUN_04c5fbcc(&Method$Common.Template.UGlobalSingleton<XLuaManager>.get_Instance());
    thunk_FUN_04c5fbcc(&Common.Template.UGlobalSingleton<XLuaManager>_TypeInfo);
    thunk_FUN_04c5fbcc(&StringLiteral_4481);
    DAT_06ce5090 = 1;
  }
  if (*(long *)(param_1 + 0x38) != 0) {
    Game.UpdateView$$SetProgressText(*(long *)(param_1 + 0x38),StringLiteral_4481,0);
    lVar1 = *(long *)(param_1 + 0x38);
    if (param_2 == 0) {
      if (lVar1 != 0) {
        Game.UpdateView$$SetProgress(0,lVar1,0);
        if (((*(ushort *)(Game.Plat.DeviceUtil_TypeInfo + 0x132) >> 10 & 1) != 0) &&
           (*(int *)(Game.Plat.DeviceUtil_TypeInfo + 0xe0) == 0)) {
          thunk_FUN_04c57094();
        }
        Game.Plat.DeviceUtil$$AntiAddiction();
        return;
      }
    }
    else if (lVar1 != 0) {
      Game.UpdateView$$SetProgress(0x41200000,lVar1,0);
      if (((*(ushort *)(Common.Template.Singleton<ResManager>_TypeInfo + 0x132) >> 10 & 1) != 0) &&
         (*(int *)(Common.Template.Singleton<ResManager>_TypeInfo + 0xe0) == 0)) {
        thunk_FUN_04c57094();
      }
      lVar1 = Method$Common.Template.Singleton<ResManager>.get_Instance();
      Common.Template.Singleton<>$$get_Instance();
      if (lVar1 == 0) {
                    /* WARNING: Subroutine does not return */
        FUN_04bfd614();
      }
      Common.Utils.ResManager$$AUnload();
      if (((*(ushort *)(Common.Template.Singleton<LocalizationManager>_TypeInfo + 0x132) >> 10 & 1)
           != 0) && (*(int *)(Common.Template.Singleton<LocalizationManager>_TypeInfo + 0xe0) == 0))
      {
        thunk_FUN_04c57094();
      }
      lVar1 = Method$Common.Template.Singleton<LocalizationManager>.get_Instance();
      Common.Template.Singleton<>$$get_Instance();
      if (lVar1 != 0) {
        UnityEngine.UI.LocalizationManager$$LoadLocalizedText();
        if (((*(ushort *)(Common.Template.UGlobalSingleton<XLuaManager>_TypeInfo + 0x132) >> 10 & 1)
             != 0) && (*(int *)(Common.Template.UGlobalSingleton<XLuaManager>_TypeInfo + 0xe0) == 0)
           ) {
          thunk_FUN_04c57094();
        }
        lVar1 = Method$Common.Template.UGlobalSingleton<XLuaManager>.get_Instance();
        Common.Template.UGlobalSingleton<>$$get_Instance();
        if (lVar1 != 0) {
          Common.Utils.XLuaManager$$RestartLua();
          return;
        }
      }
    }
  }
                    /* WARNING: Subroutine does not return */
  FUN_04bfd614();
}