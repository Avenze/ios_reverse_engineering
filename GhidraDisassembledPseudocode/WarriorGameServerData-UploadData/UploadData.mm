
/* Function Stack Size: 0x20 bytes */

void WarriorSDKUtil::UploadData:Uid:(ID param_1,SEL param_2,ID param_3,ID param_4)

{
  ID IVar1;
  ID IVar2;
  ID IVar3;
  _NSZone *p_Var4;
  class_t *pcVar5;
  
  p_Var4 = (_NSZone *)param_3;
  IVar1 = _objc_retain(param_4,param_2,(_NSZone *)param_3);
  pcVar5 = &objc::class_t::WarriorGameServerData;
  IVar2 = _objc_retain(param_3,param_2,p_Var4);
  FUN_04f863c0(&objc::class_t::WarriorGameServerData);
  _objc_retainAutoreleasedReturnValue();
  IVar3 = _objc_retain(IVar1,param_2,p_Var4);
  FUN_04fa87a0(pcVar5);
  _objc_release(IVar2);
  _objc_release(pcVar5);
  _objc_release(IVar1);
  _objc_release(IVar3);
  return;
}

