
void Game.GameLauncher.<>d__3$$MoveNext(long param_1)

{
  undefined8 *puVar1;
  int iVar2;
  undefined8 uVar3;
  long lVar4;
  long *plVar5;
  ulong uVar6;
  long lVar7;
  undefined4 uVar8;
  long lVar9;
  
  if ((DAT_06ce4e12 & 1) == 0) {
    thunk_FUN_04c5fbcc(&UnityEngine.Debug_TypeInfo);
    thunk_FUN_04c5fbcc(&Method$System.Collections.Generic.Dictionary<string,-string>..ctor());
    thunk_FUN_04c5fbcc(&Method$System.Collections.Generic.Dictionary<string,-string>.set_Item());
    thunk_FUN_04c5fbcc(&System.Collections.Generic.Dictionary<string,-string>_TypeInfo);
    thunk_FUN_04c5fbcc(&Game.GameDefine_TypeInfo);
    thunk_FUN_04c5fbcc(&
                       Method$Common.Utils.HTTPManager.DecodeResult<ServerListData<DeviceResource>>( )
                      );
    thunk_FUN_04c5fbcc(&Method$Common.Utils.HTTPManager.DecodeResult<ServerListData<string>>());
    thunk_FUN_04c5fbcc(&Common.Utils.HTTPManager_TypeInfo);
    thunk_FUN_04c5fbcc(&Method$UnityEngine.JsonUtility.FromJson<WarriorHotUpdateData>());
    thunk_FUN_04c5fbcc(&Method$Common.Template.Singleton<HTTPManager>.get_Instance());
    thunk_FUN_04c5fbcc(&Method$Common.Template.Singleton<LocalizationManager>.get_Instance());
    thunk_FUN_04c5fbcc(&Common.Template.Singleton<HTTPManager>_TypeInfo);
    thunk_FUN_04c5fbcc(&Common.Template.Singleton<LocalizationManager>_TypeInfo);
    thunk_FUN_04c5fbcc(&Game.GameDefine.VersionInfo_TypeInfo);
    thunk_FUN_04c5fbcc(&StringLiteral_7275);
    thunk_FUN_04c5fbcc(&StringLiteral_8790);
    thunk_FUN_04c5fbcc(&StringLiteral_11811);
    thunk_FUN_04c5fbcc(&StringLiteral_8796);
    thunk_FUN_04c5fbcc(&StringLiteral_8794);
    thunk_FUN_04c5fbcc(&StringLiteral_2284);
    thunk_FUN_04c5fbcc(&StringLiteral_8792);
    thunk_FUN_04c5fbcc(&StringLiteral_8793);
    thunk_FUN_04c5fbcc(&StringLiteral_10616);
    thunk_FUN_04c5fbcc(&StringLiteral_11483);
    thunk_FUN_04c5fbcc(&StringLiteral_9642);
    thunk_FUN_04c5fbcc(&StringLiteral_872);
    thunk_FUN_04c5fbcc(&StringLiteral_11810);
    thunk_FUN_04c5fbcc(&StringLiteral_8795);
    thunk_FUN_04c5fbcc(&StringLiteral_10029);
    thunk_FUN_04c5fbcc(&StringLiteral_3452);
    thunk_FUN_04c5fbcc(&StringLiteral_11809);
    thunk_FUN_04c5fbcc(&StringLiteral_10611);
    thunk_FUN_04c5fbcc(&StringLiteral_4);
    thunk_FUN_04c5fbcc(&StringLiteral_11808);
    thunk_FUN_04c5fbcc(&StringLiteral_909);
    DAT_06ce4e12 = 1;
  }
  if (3 < *(uint *)(param_1 + 0x10)) {
    return;
  }
  lVar9 = *(long *)(param_1 + 0x28);
  uVar8 = 0xffffffff;
  switch(*(uint *)(param_1 + 0x10)) {
  case 0:
    *(undefined4 *)(param_1 + 0x10) = 0xffffffff;
    iVar2 = *(int *)(param_1 + 0x20);
    if (((*(ushort *)(Game.GameDefine_TypeInfo + 0x132) >> 10 & 1) != 0) &&
       (*(int *)(Game.GameDefine_TypeInfo + 0xe0) == 0)) {
      thunk_FUN_04c57094();
    }
    lVar7 = 0;
    Game.GameDefine$$get_CDN();
    if (lVar7 != 0) {
      if (*(int *)(lVar7 + 0x18) <= iVar2) {
        return;
      }
      lVar7 = Game.GameDefine.VersionInfo_TypeInfo;
      if (((*(ushort *)(Game.GameDefine.VersionInfo_TypeInfo + 0x132) >> 10 & 1) != 0) &&
         (*(int *)(Game.GameDefine.VersionInfo_TypeInfo + 0xe0) == 0)) {
        thunk_FUN_04c57094();
      }
      iVar2 = (int)lVar7;
      Game.GameDefine.VersionInfo$$get_EnableUpdate();
      if (iVar2 == 0) {
        return;
      }
      if (((*(ushort *)(Game.GameDefine_TypeInfo + 0x132) >> 10 & 1) != 0) &&
         (*(int *)(Game.GameDefine_TypeInfo + 0xe0) == 0)) {
        thunk_FUN_04c57094();
      }
      lVar7 = 0;
      Game.GameDefine$$get_CDN();
      if (lVar7 != 0) {
        if (*(uint *)(lVar7 + 0x18) <= *(uint *)(param_1 + 0x20)) {
          thunk_FUN_04c413d0();
                    /* WARNING: Subroutine does not return */
          FUN_04bfd5e0();
        }
        if (*(long *)(lVar7 + (long)(int)*(uint *)(param_1 + 0x20) * 8 + 0x20) == 0) {
          return;
        }
        if (((*(ushort *)(Game.GameDefine_TypeInfo + 0x132) >> 10 & 1) != 0) &&
           (*(int *)(Game.GameDefine_TypeInfo + 0xe0) == 0)) {
          thunk_FUN_04c57094();
        }
        lVar7 = 0;
        Game.GameDefine$$get_CDN();
        if (lVar7 != 0) {
          FUN_014644e0();
          plVar5 = (long *)(param_1 + 0x38);
          *plVar5 = lVar7;
          thunk_FUN_04bf30c4(plVar5,lVar7);
          if (lVar9 != 0) {
            lVar9 = *(long *)(lVar9 + 0x38);
            if (((*(ushort *)(Common.Template.Singleton<LocalizationManager>_TypeInfo + 0x132) >> 10
                 & 1) != 0) &&
               (*(int *)(Common.Template.Singleton<LocalizationManager>_TypeInfo + 0xe0) == 0)) {
              thunk_FUN_04c57094();
            }
            lVar7 = Method$Common.Template.Singleton<LocalizationManager>.get_Instance();
            Common.Template.Singleton<>$$get_Instance();
            if ((lVar7 != 0) && (UnityEngine.UI.LocalizationManager$$GetValue(), lVar9 != 0)) {
              Game.UpdateView$$SetProgressText(lVar9,lVar7,0);
              if (((*(ushort *)(Common.Utils.HTTPManager_TypeInfo + 0x132) >> 10 & 1) != 0) &&
                 (*(int *)(Common.Utils.HTTPManager_TypeInfo + 0xe0) == 0)) {
                thunk_FUN_04c57094();
              }
              lVar9 = *plVar5;
              if (lVar9 != 0) {
                System.String$$Contains(lVar9,StringLiteral_11483,0);
                if ((int)lVar9 != 0) {
                  lVar9 = System.Collections.Generic.Dictionary<string,-string>_TypeInfo;
                  thunk_FUN_04c31c30();
                  System.Collections.Generic.Dictionary<>$$.ctor();
                  if (lVar9 == 0) goto LAB_00112a34;
                  System.Collections.Generic.Dictionary<>$$set_Item
                            (lVar9,StringLiteral_10029,StringLiteral_9642,
                             Method$System.Collections.Generic.Dictionary<string,-string>.set_Item()
                            );
                  iVar2 = 0;
                  UnityEngine.Application$$get_platform();
                  puVar1 = (undefined8 *)&StringLiteral_11811;
                  if (iVar2 != 8) {
                    puVar1 = &StringLiteral_11810;
                  }
                  System.Collections.Generic.Dictionary<>$$set_Item
                            (lVar9,StringLiteral_8792,*puVar1,
                             Method$System.Collections.Generic.Dictionary<string,-string>.set_Item()
                            );
                  iVar2 = 0;
                  UnityEngine.Application$$get_platform();
                  puVar1 = (undefined8 *)&StringLiteral_11811;
                  if (iVar2 != 8) {
                    puVar1 = &StringLiteral_11810;
                  }
                  System.Collections.Generic.Dictionary<>$$set_Item
                            (lVar9,StringLiteral_8793,*puVar1,
                             Method$System.Collections.Generic.Dictionary<string,-string>.set_Item()
                            );
                  uVar3 = 0;
                  Game.Plat.DeviceInfo$$GetResVersion(0);
                  System.Collections.Generic.Dictionary<>$$set_Item
                            (lVar9,StringLiteral_8796,uVar3,
                             Method$System.Collections.Generic.Dictionary<string,-string>.set_Item()
                            );
                  iVar2 = 0;
                  UnityEngine.Application$$get_platform();
                  puVar1 = (undefined8 *)&StringLiteral_10611;
                  if (iVar2 != 0xb) {
                    puVar1 = &StringLiteral_10616;
                  }
                  System.Collections.Generic.Dictionary<>$$set_Item
                            (lVar9,StringLiteral_8794,*puVar1,
                             Method$System.Collections.Generic.Dictionary<string,-string>.set_Item()
                            );
                  System.Collections.Generic.Dictionary<>$$set_Item
                            (lVar9,StringLiteral_8795,StringLiteral_4,
                             Method$System.Collections.Generic.Dictionary<string,-string>.set_Item()
                            );
                  System.Collections.Generic.Dictionary<>$$set_Item
                            (lVar9,StringLiteral_8790,StringLiteral_4,
                             Method$System.Collections.Generic.Dictionary<string,-string>.set_Item()
                            );
                  System.Collections.Generic.Dictionary<>$$set_Item
                            (lVar9,StringLiteral_3452,StringLiteral_909,
                             Method$System.Collections.Generic.Dictionary<string,-string>.set_Item()
                            );
                }
                if (((*(ushort *)(Common.Template.Singleton<HTTPManager>_TypeInfo + 0x132) >> 10 & 1
                     ) != 0) &&
                   (*(int *)(Common.Template.Singleton<HTTPManager>_TypeInfo + 0xe0) == 0)) {
                  thunk_FUN_04c57094();
                }
                lVar9 = Method$Common.Template.Singleton<HTTPManager>.get_Instance();
                Common.Template.Singleton<>$$get_Instance();
                if (lVar9 != 0) {
                  Common.Utils.HTTPManager$$SendGet();
                  plVar5 = (long *)(param_1 + 0x40);
                  *plVar5 = lVar9;
                  thunk_FUN_04bf30c4(plVar5,lVar9);
                  if (*plVar5 != 0) {
                    UnityEngine.Networking.UnityWebRequest$$set_timeout(*plVar5,5,0);
                    lVar9 = *plVar5;
                    if (lVar9 != 0) {
                      UnityEngine.Networking.UnityWebRequest$$SendWebRequest(lVar9,0);
                      *(long *)(param_1 + 0x18) = lVar9;
                      thunk_FUN_04bf30c4();
                      uVar8 = 1;
                      goto switchD_00112324_caseD_3;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    goto LAB_00112a34;
  case 2:
    *(undefined4 *)(param_1 + 0x10) = 0xffffffff;
    goto LAB_001127e0;
  case 3:
    goto switchD_00112324_caseD_3;
  }
  *(undefined4 *)(param_1 + 0x10) = 0xffffffff;
  lVar4 = StringLiteral_2284;
  UnityEngine.PlayerPrefs$$GetString(StringLiteral_2284,0);
  lVar7 = StringLiteral_4;
  if (lVar4 != 0) {
    lVar7 = lVar4;
  }
  if (((*(ushort *)(Game.GameDefine_TypeInfo + 0x132) >> 10 & 1) != 0) &&
     (*(int *)(Game.GameDefine_TypeInfo + 0xe0) == 0)) {
    thunk_FUN_04c57094();
  }
  plVar5 = (long *)(*(long *)(Game.GameDefine_TypeInfo + 0xb8) + 0x28);
  *plVar5 = lVar7;
  thunk_FUN_04bf30c4(plVar5,lVar7);
  uVar6 = *(ulong *)(param_1 + 0x40);
  if (uVar6 == 0) goto LAB_00112a34;
  UnityEngine.Networking.UnityWebRequest$$get_isHttpError(uVar6,0);
  if ((uVar6 & 1) == 0) {
    lVar7 = *(long *)(param_1 + 0x40);
    if (lVar7 == 0) goto LAB_00112a34;
    UnityEngine.Networking.UnityWebRequest$$get_isNetworkError(lVar7,0);
    if ((int)lVar7 == 0) {
      lVar9 = *(long *)(param_1 + 0x38);
      if (lVar9 == 0) goto LAB_00112a34;
      System.String$$Contains(lVar9,StringLiteral_11483,0);
      if ((int)lVar9 == 0) {
        if (((*(ushort *)(Common.Template.Singleton<HTTPManager>_TypeInfo + 0x132) >> 10 & 1) != 0)
           && (*(int *)(Common.Template.Singleton<HTTPManager>_TypeInfo + 0xe0) == 0)) {
          thunk_FUN_04c57094();
        }
        lVar9 = Method$Common.Template.Singleton<HTTPManager>.get_Instance();
        Common.Template.Singleton<>$$get_Instance();
        if (lVar9 == 0) goto LAB_00112a34;
        Common.Utils.HTTPManager$$DecodeResult<object>();
        if ((lVar9 != 0) && (lVar9 = *(long *)(lVar9 + 0x20), lVar9 != 0)) {
          DeviceResource$$GetUrl(lVar9,0);
          if (((*(ushort *)(Game.GameDefine_TypeInfo + 0x132) >> 10 & 1) != 0) &&
             (*(int *)(Game.GameDefine_TypeInfo + 0xe0) == 0)) {
            thunk_FUN_04c57094();
          }
          plVar5 = (long *)(*(long *)(Game.GameDefine_TypeInfo + 0xb8) + 0x28);
          *plVar5 = lVar9;
          thunk_FUN_04bf30c4(plVar5,lVar9);
          lVar9 = *(long *)(Game.GameDefine_TypeInfo + 0xb8);
          goto LAB_00112a20;
        }
      }
      else {
        if (((*(ushort *)(Common.Template.Singleton<HTTPManager>_TypeInfo + 0x132) >> 10 & 1) != 0)
           && (*(int *)(Common.Template.Singleton<HTTPManager>_TypeInfo + 0xe0) == 0)) {
          thunk_FUN_04c57094();
        }
        lVar9 = Method$Common.Template.Singleton<HTTPManager>.get_Instance();
        Common.Template.Singleton<>$$get_Instance();
        if (lVar9 == 0) goto LAB_00112a34;
        Common.Utils.HTTPManager$$DecodeResult<object>();
        if ((lVar9 != 0) && (lVar9 = *(long *)(lVar9 + 0x20), lVar9 != 0)) {
          UnityEngine.JsonUtility$$FromJson<>
                    (lVar9,Method$UnityEngine.JsonUtility.FromJson<WarriorHotUpdateData>());
          lVar7 = Game.GameDefine.VersionInfo_TypeInfo;
          if (((*(ushort *)(Game.GameDefine.VersionInfo_TypeInfo + 0x132) >> 10 & 1) != 0) &&
             (*(int *)(Game.GameDefine.VersionInfo_TypeInfo + 0xe0) == 0)) {
            thunk_FUN_04c57094();
          }
          iVar2 = (int)lVar7;
          Game.GameDefine.VersionInfo$$get_IsDebug();
          if (iVar2 == 0) {
            if (lVar9 == 0) goto LAB_00112a34;
            lVar9 = *(long *)(lVar9 + 0x18);
          }
          else {
            if ((lVar9 == 0) || (lVar9 = *(long *)(lVar9 + 0x18), lVar9 == 0)) goto LAB_00112a34;
            System.String$$Replace(lVar9,StringLiteral_11808,StringLiteral_11809,0);
          }
          lVar7 = Game.GameDefine.VersionInfo_TypeInfo;
          if (((*(ushort *)(Game.GameDefine.VersionInfo_TypeInfo + 0x132) >> 10 & 1) != 0) &&
             (*(int *)(Game.GameDefine.VersionInfo_TypeInfo + 0xe0) == 0)) {
            thunk_FUN_04c57094();
          }
          Game.GameDefine.VersionInfo$$get_Platform();
          System.String$$Concat(lVar9,StringLiteral_872,lVar7,0);
          if (((*(ushort *)(Game.GameDefine_TypeInfo + 0x132) >> 10 & 1) != 0) &&
             (*(int *)(Game.GameDefine_TypeInfo + 0xe0) == 0)) {
            thunk_FUN_04c57094();
          }
          plVar5 = (long *)(*(long *)(Game.GameDefine_TypeInfo + 0xb8) + 0x28);
          *plVar5 = lVar9;
          thunk_FUN_04bf30c4(plVar5,lVar9);
          if (((*(ushort *)(Game.GameDefine_TypeInfo + 0x132) >> 10 & 1) != 0) &&
             (*(int *)(Game.GameDefine_TypeInfo + 0xe0) == 0)) {
            thunk_FUN_04c57094();
          }
          lVar9 = *(long *)(Game.GameDefine_TypeInfo + 0xb8);
LAB_00112a20:
          UnityEngine.PlayerPrefs$$SetString(StringLiteral_2284,*(undefined8 *)(lVar9 + 0x28),0);
        }
      }
LAB_001127e0:
      *(undefined8 *)(param_1 + 0x18) = 0;
      thunk_FUN_04bf30c4((undefined8 *)(param_1 + 0x18),0);
      uVar8 = 3;
      goto switchD_00112324_caseD_3;
    }
  }
  lVar7 = *(long *)(param_1 + 0x40);
  if (lVar7 != 0) {
    UnityEngine.Networking.UnityWebRequest$$get_error(lVar7,0);
    if (((*(ushort *)(UnityEngine.Debug_TypeInfo + 0x132) >> 10 & 1) != 0) &&
       (*(int *)(UnityEngine.Debug_TypeInfo + 0xe0) == 0)) {
      thunk_FUN_04c57094();
    }
    UnityEngine.Debug$$LogError(lVar7,0);
    if (lVar9 != 0) {
      Game.GameLauncher$$GetDownloadServerUrl
                (lVar9,*(int *)(param_1 + 0x20) + 1,*(undefined8 *)(param_1 + 0x30),0);
      *(long *)(param_1 + 0x18) = lVar9;
      thunk_FUN_04bf30c4();
      uVar8 = 2;
switchD_00112324_caseD_3:
      *(undefined4 *)(param_1 + 0x10) = uVar8;
      return;
    }
  }
LAB_00112a34:
                    /* WARNING: Subroutine does not return */
  FUN_04bfd614();
}

