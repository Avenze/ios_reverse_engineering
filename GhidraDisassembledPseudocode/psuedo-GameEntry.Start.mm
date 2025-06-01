
undefined8 GameEntry.<Start>d__4$$MoveNext(long param_1)

{
  int iVar1;
  undefined8 uVar2;
  long lVar3;
  long *plVar4;
  undefined8 uVar5;
  code *pcVar6;
  ulong uVar7;
  int *piVar8;
  undefined4 uVar9;
  long lVar10;
  long *plVar11;
  
  if ((DAT_06ce4e03 & 1) == 0) {
    thunk_FUN_04c5fbcc(&UnityEngine.Debug_TypeInfo);
    thunk_FUN_04c5fbcc(&Game.GameDefine_TypeInfo);
    thunk_FUN_04c5fbcc(&UnityEngine.ILogger_TypeInfo);
    thunk_FUN_04c5fbcc(&Method$UnityEngine.Object.Instantiate<GameObject>());
    thunk_FUN_04c5fbcc(&UnityEngine.Object_TypeInfo);
    thunk_FUN_04c5fbcc(&Method$UnityEngine.Resources.Load<GameObject>());
    thunk_FUN_04c5fbcc(&Method$Common.Template.Singleton<SDKManager>.get_Instance());
    thunk_FUN_04c5fbcc(&Common.Template.Singleton<SDKManager>_TypeInfo);
    thunk_FUN_04c5fbcc(&Method$Common.Template.UGlobalSingleton<GameLauncher>.get_Instance());
    thunk_FUN_04c5fbcc(&Method$Common.Template.UGlobalSingleton<RunTimeDebug>.get_Instance());
    thunk_FUN_04c5fbcc(&Common.Template.UGlobalSingleton<RunTimeDebug>_TypeInfo);
    thunk_FUN_04c5fbcc(&Common.Template.UGlobalSingleton<GameLauncher>_TypeInfo);
    thunk_FUN_04c5fbcc(&Common.Utils.UnityHelper_TypeInfo);
    thunk_FUN_04c5fbcc(&Game.GameDefine.VersionInfo_TypeInfo);
    thunk_FUN_04c5fbcc(&StringLiteral_12876);
    thunk_FUN_04c5fbcc(&StringLiteral_6138);
    thunk_FUN_04c5fbcc(&StringLiteral_5764);
    thunk_FUN_04c5fbcc(&StringLiteral_13088);
    thunk_FUN_04c5fbcc(&StringLiteral_13089);
    DAT_06ce4e03 = 1;
  }
  uVar2 = 0;
  iVar1 = *(int *)(param_1 + 0x10);
  if (iVar1 == 2) {
    uVar9 = 0xffffffff;
  }
  else {
    if (iVar1 == 1) {
      *(undefined4 *)(param_1 + 0x10) = 0xffffffff;
      lVar10 = Game.GameDefine.VersionInfo_TypeInfo;
      if (((*(ushort *)(Game.GameDefine.VersionInfo_TypeInfo + 0x132) >> 10 & 1) != 0) &&
         (*(int *)(Game.GameDefine.VersionInfo_TypeInfo + 0xe0) == 0)) {
        thunk_FUN_04c57094();
      }
      iVar1 = (int)lVar10;
      Game.GameDefine.VersionInfo$$get_IsDebug();
      if (iVar1 == 0) {
        if (((*(ushort *)(UnityEngine.Debug_TypeInfo + 0x132) >> 10 & 1) != 0) &&
           (*(int *)(UnityEngine.Debug_TypeInfo + 0xe0) == 0)) {
          thunk_FUN_04c57094();
        }
        if (DAT_06a197e1 == '\0') {
          thunk_FUN_04c5fbcc(&UnityEngine.Debug_TypeInfo);
          DAT_06a197e1 = '\x01';
        }
        if (((*(ushort *)(UnityEngine.Debug_TypeInfo + 0x132) >> 10 & 1) != 0) &&
           (*(int *)(UnityEngine.Debug_TypeInfo + 0xe0) == 0)) {
          thunk_FUN_04c57094();
        }
        plVar11 = *(long **)(*(long *)(UnityEngine.Debug_TypeInfo + 0xb8) + 8);
        if (plVar11 == (long *)0x0) goto LAB_0010e568;
        lVar10 = *plVar11;
        uVar7 = (ulong)*(ushort *)(lVar10 + 0x12a);
        if (uVar7 != 0) {
          piVar8 = (int *)(*(long *)(lVar10 + 0xb0) + 8);
          do {
            if (*(long *)(piVar8 + -2) == UnityEngine.ILogger_TypeInfo) {
              plVar4 = (long *)(lVar10 + (long)(*piVar8 + 2) * 0x10 + 0x138);
              goto LAB_0010e3c4;
            }
            piVar8 = piVar8 + 4;
            uVar7 = uVar7 - 1;
          } while (uVar7 != 0);
        }
        plVar4 = plVar11;
        FUN_04c2e960(plVar11,UnityEngine.ILogger_TypeInfo,2);
LAB_0010e3c4:
        pcVar6 = (code *)*plVar4;
        lVar10 = plVar4[1];
        uVar2 = 4;
      }
      else {
        if (((*(ushort *)(UnityEngine.Debug_TypeInfo + 0x132) >> 10 & 1) != 0) &&
           (*(int *)(UnityEngine.Debug_TypeInfo + 0xe0) == 0)) {
          thunk_FUN_04c57094();
        }
        if (DAT_06a197e1 == '\0') {
          thunk_FUN_04c5fbcc(&UnityEngine.Debug_TypeInfo);
          DAT_06a197e1 = '\x01';
        }
        if (((*(ushort *)(UnityEngine.Debug_TypeInfo + 0x132) >> 10 & 1) != 0) &&
           (*(int *)(UnityEngine.Debug_TypeInfo + 0xe0) == 0)) {
          thunk_FUN_04c57094();
        }
        plVar11 = *(long **)(*(long *)(UnityEngine.Debug_TypeInfo + 0xb8) + 8);
        if (plVar11 == (long *)0x0) goto LAB_0010e568;
        lVar10 = *plVar11;
        uVar7 = (ulong)*(ushort *)(lVar10 + 0x12a);
        if (uVar7 != 0) {
          piVar8 = (int *)(*(long *)(lVar10 + 0xb0) + 8);
          do {
            if (*(long *)(piVar8 + -2) == UnityEngine.ILogger_TypeInfo) {
              plVar4 = (long *)(lVar10 + (long)(*piVar8 + 2) * 0x10 + 0x138);
              goto LAB_0010e3a4;
            }
            piVar8 = piVar8 + 4;
            uVar7 = uVar7 - 1;
          } while (uVar7 != 0);
        }
        plVar4 = plVar11;
        FUN_04c2e960(plVar11,UnityEngine.ILogger_TypeInfo,2);
LAB_0010e3a4:
        pcVar6 = (code *)*plVar4;
        lVar10 = plVar4[1];
        uVar2 = 7;
      }
      (*pcVar6)(plVar11,uVar2,lVar10);
      lVar10 = Game.GameDefine.VersionInfo_TypeInfo;
      if (((*(ushort *)(Game.GameDefine.VersionInfo_TypeInfo + 0x132) >> 10 & 1) != 0) &&
         (*(int *)(Game.GameDefine.VersionInfo_TypeInfo + 0xe0) == 0)) {
        thunk_FUN_04c57094();
      }
      iVar1 = (int)lVar10;
      Game.GameDefine.VersionInfo$$get_IsDebug();
      if (iVar1 != 0) {
        uVar2 = StringLiteral_6138;
        UnityEngine.Resources$$Load<Transform>
                  (StringLiteral_6138,Method$UnityEngine.Resources.Load<GameObject>());
        if (((*(ushort *)(UnityEngine.Object_TypeInfo + 0x132) >> 10 & 1) != 0) &&
           (*(int *)(UnityEngine.Object_TypeInfo + 0xe0) == 0)) {
          thunk_FUN_04c57094();
        }
        uVar5 = uVar2;
        UnityEngine.Object$$op_Implicit(uVar2,0);
        if ((int)uVar5 != 0) {
          if (((*(ushort *)(UnityEngine.Object_TypeInfo + 0x132) >> 10 & 1) != 0) &&
             (*(int *)(UnityEngine.Object_TypeInfo + 0xe0) == 0)) {
            thunk_FUN_04c57094();
          }
          UnityEngine.Object$$Instantiate<>
                    (uVar2,Method$UnityEngine.Object.Instantiate<GameObject>());
        }
      }
      if (((*(ushort *)(Common.Template.Singleton<SDKManager>_TypeInfo + 0x132) >> 10 & 1) != 0) &&
         (*(int *)(Common.Template.Singleton<SDKManager>_TypeInfo + 0xe0) == 0)) {
        thunk_FUN_04c57094();
      }
      lVar10 = Method$Common.Template.Singleton<SDKManager>.get_Instance();
      Common.Template.Singleton<>$$get_Instance();
      if (lVar10 == 0) goto LAB_0010e568;
      Game.SDK.SDKManager$$Track();
      if (((*(ushort *)(Common.Template.UGlobalSingleton<GameLauncher>_TypeInfo + 0x132) >> 10 & 1)
           != 0) && (*(int *)(Common.Template.UGlobalSingleton<GameLauncher>_TypeInfo + 0xe0) == 0))
      {
        thunk_FUN_04c57094();
      }
      lVar10 = Method$Common.Template.UGlobalSingleton<GameLauncher>.get_Instance();
      Common.Template.UGlobalSingleton<>$$get_Instance();
      if (lVar10 == 0) goto LAB_0010e568;
      Game.GameLauncher$$CheckUpdate();
      if (((*(ushort *)(Common.Template.UGlobalSingleton<RunTimeDebug>_TypeInfo + 0x132) >> 10 & 1)
           != 0) && (*(int *)(Common.Template.UGlobalSingleton<RunTimeDebug>_TypeInfo + 0xe0) == 0))
      {
        thunk_FUN_04c57094();
      }
      lVar10 = Method$Common.Template.UGlobalSingleton<RunTimeDebug>.get_Instance();
      Common.Template.UGlobalSingleton<>$$get_Instance();
      if (lVar10 == 0) goto LAB_0010e568;
      Common.Utils.RunTimeDebug$$Init();
      uVar9 = 2;
    }
    else {
      if (iVar1 != 0) {
        return 0;
      }
      lVar10 = *(long *)(param_1 + 0x20);
      *(undefined4 *)(param_1 + 0x10) = 0xffffffff;
      if (((*(ushort *)(Common.Template.Singleton<SDKManager>_TypeInfo + 0x132) >> 10 & 1) != 0) &&
         (*(int *)(Common.Template.Singleton<SDKManager>_TypeInfo + 0xe0) == 0)) {
        thunk_FUN_04c57094();
      }
      lVar3 = Method$Common.Template.Singleton<SDKManager>.get_Instance();
      Common.Template.Singleton<>$$get_Instance();
      if (lVar3 == 0) {
LAB_0010e568:
                    /* WARNING: Subroutine does not return */
        FUN_04bfd614();
      }
      Game.SDK.SDKManager$$Track();
      if (((*(ushort *)(Game.GameDefine_TypeInfo + 0x132) >> 10 & 1) != 0) &&
         (*(int *)(Game.GameDefine_TypeInfo + 0xe0) == 0)) {
        thunk_FUN_04c57094();
      }
      lVar3 = 0;
      Game.GameDefine$$get_UICanvas();
      if (((*(ushort *)(Common.Utils.UnityHelper_TypeInfo + 0x132) >> 10 & 1) != 0) &&
         (*(int *)(Common.Utils.UnityHelper_TypeInfo + 0xe0) == 0)) {
        thunk_FUN_04c57094();
      }
      Common.Utils.UnityHelper$$FindTheChild(lVar3,StringLiteral_5764,1,0);
      if ((lVar3 == 0) || (UnityEngine.Component$$get_gameObject(), lVar10 == 0)) goto LAB_0010e568;
      GameEntry$$FixScreenMatching(lVar10,lVar3,0);
      uVar2 = 0;
      Game.GameDefine$$get_UICanvas(0);
      GameEntry$$AdjustMatchWidthOrHeight(lVar10,uVar2,0);
      UnityEngine.Screen$$set_sleepTimeout(0xffffffff,0);
      BetterStreamingAssets$$Initialize(0);
      uVar9 = 1;
    }
    *(undefined8 *)(param_1 + 0x18) = 0;
    thunk_FUN_04bf30c4((undefined8 *)(param_1 + 0x18),0);
    uVar2 = 1;
  }
  *(undefined4 *)(param_1 + 0x10) = uVar9;
  return uVar2;
}

