
/* Function Stack Size: 0x10 bytes */

void WarriorGameServer::initSDK(ID param_1,SEL param_2)

{
  class_t *pcVar1;
  class_t *pcVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  
  pcVar1 = &objc::class_t::WarriorGame;
  FUN_04f863c0(&objc::class_t::WarriorGame);
  _objc_retainAutoreleasedReturnValue();
  FUN_04f229e0();
  _objc_release(pcVar1);
  pcVar2 = &objc::class_t::WarriorGameInfo;
  FUN_04f863c0();
  _objc_retainAutoreleasedReturnValue();
  pcVar1 = pcVar2;
  FUN_04eb5580();
  _objc_retainAutoreleasedReturnValue();
  _objc_release(pcVar2);
  if ((pcVar1 == (class_t *)0x0) || (pcVar2 = pcVar1, FUN_04ee21e0(), (int)pcVar2 != 0)) {
    uVar3 = *(undefined8 *)(param_1 + 0x10);
  }
  else {
    FUN_04edbe60(pcVar1);
    uVar3 = *(undefined8 *)(param_1 + 0x10);
  }
  FUN_04f04f20();
  _objc_retainAutoreleasedReturnValue();
  uVar4 = *(undefined8 *)(param_1 + 0x18);
  *(undefined8 *)(param_1 + 0x18) = uVar3;
  _objc_release(uVar4);
  pcVar2 = &objc::class_t::WarriorGame;
  FUN_04f863c0(&objc::class_t::WarriorGame);
  _objc_retainAutoreleasedReturnValue();
  FUN_04f229e0();
  _objc_release(pcVar2);
  FUN_04eb5540(param_1);
  _objc_release(pcVar1);
  return;
}

