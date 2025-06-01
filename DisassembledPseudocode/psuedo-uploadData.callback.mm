
/* Function Stack Size: 0x20 bytes */

void WarriorGameServerData::uploadData:callback:
               (ID param_1,SEL param_2,ID param_3,ID param_4,undefined4 param_5)

{
  ID obj;
  ID obj_00;
  class_t *pcVar1;
  class_t *pcVar2;
  MethodInfo *obj_01;
  class_t *pcVar3;
  class_t *pcVar4;
  class_t *pcVar5;
  ID IVar6;
  class_t *obj_02;
  undefined *obj_03;
  class_t *pcVar7;
  undefined *obj_04;
  ID IVar8;
  ID obj_05;
  cfstringStruct *pcVar9;
  _NSZone *p_Var10;
  class_t *pcStack_f8;
  class_t *pcStack_f0;
  ID IStack_e8;
  cfstringStruct *pcStack_e0;
  cfstringStruct *pcStack_d8;
  cfstringStruct *pcStack_d0;
  cfstringStruct *pcStack_c8;
  cfstringStruct *pcStack_c0;
  cfstringStruct *pcStack_b8;
  cfstringStruct *pcStack_b0;
  class_t *pcStack_a8;
  class_t *pcStack_a0;
  cfstringStruct *pcStack_98;
  class_t *pcStack_90;
  ID IStack_88;
  long lStack_80;
  
  lStack_80 = *(long *)PTR____stack_chk_guard_05e7c9a8;
  IVar6 = param_4;
  obj = _objc_retain(param_3,param_2,(_NSZone *)param_3);
  obj_00 = _objc_retain(param_4,param_2,(_NSZone *)param_3);
  pcVar1 = &objc::class_t::WarriorGameServer;
  FUN_04f863c0();
  _objc_retainAutoreleasedReturnValue();
  pcVar2 = pcVar1;
  FUN_04eb63c0();
  _objc_release((intptr_t)pcVar1,(MethodInfo *)param_2);
  if (((ulong)pcVar2 & 1) == 0) {
    obj_01 = (MethodInfo *)FUN_04e98be0((ID)&_OBJC_CLASS_$_NSMutableDictionary,param_2);
    _objc_retainAutoreleasedReturnValue();
    FUN_04f66e40();
  }
  else {
    IVar8 = obj;
    FUN_04ee21e0();
    if ((int)IVar8 == 0) {
      pcVar1 = &objc::class_t::WarriorGameInfo;
      FUN_04f863c0();
      _objc_retainAutoreleasedReturnValue();
      pcVar2 = pcVar1;
      FUN_04eb5580();
      _objc_retainAutoreleasedReturnValue();
      _objc_release((intptr_t)pcVar1,(MethodInfo *)param_2);
      pcVar3 = &objc::class_t::WarriorGameInfo;
      FUN_04f863c0();
      _objc_retainAutoreleasedReturnValue();
      pcVar1 = pcVar3;
      FUN_04eb5580();
      _objc_retainAutoreleasedReturnValue();
      _objc_release((intptr_t)pcVar3,(MethodInfo *)param_2);
      pcVar4 = &objc::class_t::WarriorGameInfo;
      FUN_04f863c0();
      _objc_retainAutoreleasedReturnValue();
      pcVar9 = &cf_warrior_server_channel;
      pcVar3 = pcVar4;
      FUN_04eb5580();
      _objc_retainAutoreleasedReturnValue();
      _objc_release((intptr_t)pcVar4,(MethodInfo *)param_2);
      pcVar5 = &objc::class_t::WarriorGameServer;
      FUN_04f863c0();
      _objc_retainAutoreleasedReturnValue();
      pcVar4 = pcVar5;
      FUN_04ebb240();
      _objc_retainAutoreleasedReturnValue();
      _objc_release((intptr_t)pcVar5,(MethodInfo *)param_2);
      pcVar5 = &objc::class_t::WarriorGameServer;
      FUN_04f863c0();
      _objc_retainAutoreleasedReturnValue();
      IVar6 = FUN_04ebaa80((ID)pcVar5,param_2,(ID)pcVar9,IVar6);
      _objc_retainAutoreleasedReturnValue();
      _objc_release((intptr_t)pcVar5,(MethodInfo *)param_2);
      obj_02 = &objc::class_t::AFHTTPSessionManager;
      FUN_04ef6860();
      _objc_retainAutoreleasedReturnValue();
      pcStack_e0 = &cf_Content-Type;
      pcStack_d8 = &cf_X-WRE-APP-ID;
      pcStack_b0 = &cf_application/json;
      pcStack_d0 = &cf_X-WRE-APP-NAME;
      pcStack_c8 = &cf_X-WRE-VERSION;
      pcStack_98 = &cf_1.0.1;
      pcStack_c0 = &cf_X-WRE-CHANNEL;
      pcStack_b8 = &cf_X-WRE-TOKEN;
      obj_03 = &_OBJC_CLASS_$_NSDictionary;
      pcStack_a8 = pcVar2;
      pcStack_a0 = pcVar1;
      pcStack_90 = pcVar3;
      IStack_88 = IVar6;
      FUN_04e99240();
      _objc_retainAutoreleasedReturnValue();
      pcVar7 = &objc::class_t::WarriorGameServer;
      FUN_04f863c0();
      _objc_retainAutoreleasedReturnValue();
      pcVar5 = pcVar7;
      FUN_04ebafa0();
      _objc_retainAutoreleasedReturnValue();
      _objc_release((intptr_t)pcVar7,(MethodInfo *)param_2);
      pcVar7 = &objc::class_t::AFJSONRequestSerializer;
      FUN_04f3c3a0();
      _objc_retainAutoreleasedReturnValue();
      FUN_04f70f20(obj_02);
      _objc_release((intptr_t)pcVar7,(MethodInfo *)param_2);
      pcVar7 = obj_02;
      FUN_04f2d2c0();
      _objc_retainAutoreleasedReturnValue();
      FUN_04f7b960(0x4024000000000000);
      _objc_release((intptr_t)pcVar7,(MethodInfo *)param_2);
      pcVar7 = &objc::class_t::AFJSONResponseSerializer;
      FUN_04f3c3a0();
      _objc_retainAutoreleasedReturnValue();
      FUN_04f717e0(obj_02);
      _objc_release((intptr_t)pcVar7,(MethodInfo *)param_2);
      obj_04 = &_OBJC_CLASS_$_NSDictionary;
      p_Var10 = (_NSZone *)&pcStack_f8;
      pcStack_f8 = pcVar4;
      pcStack_f0 = pcVar2;
      IStack_e8 = obj;
      FUN_04e99240();
      _objc_retainAutoreleasedReturnValue();
      IVar8 = _objc_retain(obj_00,param_2,p_Var10);
      obj_05 = _objc_retain(IVar8,param_2,p_Var10);
      FUN_04e53da0(obj_02);
      _objc_unsafeClaimAutoreleasedReturnValue();
      _objc_release(obj_05,(MethodInfo *)param_2);
      _objc_release(IVar8,(MethodInfo *)param_2);
      _objc_release((intptr_t)obj_04,(MethodInfo *)param_2);
      _objc_release((intptr_t)pcVar5,(MethodInfo *)param_2);
      _objc_release((intptr_t)obj_03,(MethodInfo *)param_2);
      _objc_release((intptr_t)obj_02,(MethodInfo *)param_2);
      _objc_release(IVar6,(MethodInfo *)param_2);
      _objc_release((intptr_t)pcVar4,(MethodInfo *)param_2);
      _objc_release((intptr_t)pcVar3,(MethodInfo *)param_2);
      _objc_release((intptr_t)pcVar1,(MethodInfo *)param_2);
      _objc_release((intptr_t)pcVar2,(MethodInfo *)param_2);
      goto LAB_04cf1174;
    }
    obj_01 = (MethodInfo *)FUN_04e98be0((ID)&_OBJC_CLASS_$_NSMutableDictionary,param_2);
    _objc_retainAutoreleasedReturnValue();
    FUN_04f66e40();
  }
  FUN_04f66e40(obj_01);
  param_2 = (SEL)obj_01;
  (**(code **)(obj_00 + 0x10))(obj_00);
  _objc_release((intptr_t)obj_01,(MethodInfo *)param_2);
LAB_04cf1174:
  _objc_release(obj_00,(MethodInfo *)param_2);
  _objc_release(obj,(MethodInfo *)param_2);
  if (*(long *)PTR____stack_chk_guard_05e7c9a8 == lStack_80) {
    return;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}

