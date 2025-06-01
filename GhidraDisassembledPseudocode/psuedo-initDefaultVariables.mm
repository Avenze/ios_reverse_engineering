/* Function Stack Size: 0x10 bytes */

void WarriorGameServer::initDefaultVariables(ID param_1,SEL param_2)

{
  undefined8 uVar1;
  undefined *puVar2;
  long lVar3;
  
  lVar3 = *(long *)PTR____stack_chk_guard_05e7c9a8;
  uVar1 = *(undefined8 *)(param_1 + 8);
  *(cfstringStruct **)(param_1 + 8) = &cf_WarriorGameServer;
  _objc_release(uVar1);
  puVar2 = &_OBJC_CLASS_$_NSArray;
  FUN_04e6ca80();
  _objc_retainAutoreleasedReturnValue();
  uVar1 = *(undefined8 *)(param_1 + 0x10);
  *(undefined **)(param_1 + 0x10) = puVar2;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x18);
  *(cfstringStruct **)(param_1 + 0x18) = &cf_https://guigu1.loveballs.club;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x20);
  *(cfstringStruct **)(param_1 + 0x20) = &cf_/gameapi/v1/users/login/v2;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x28);
  *(cfstringStruct **)(param_1 + 0x28) = &cf_/gameapi/v1/data/game;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x30);
  *(cfstringStruct **)(param_1 + 0x30) = &cf_/gameapi/v1/data/getGameDataByUserId;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x38);
  *(cfstringStruct **)(param_1 + 0x38) = &cf_/gameapi/v1/data/clear;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x40);
  *(cfstringStruct **)(param_1 + 0x40) = &cf_/gameapi/v1/code/getAward;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x48);
  *(cfstringStruct **)(param_1 + 0x48) = &cf_/gameapi/v1/code/costCode;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x50);
  *(cfstringStruct **)(param_1 + 0x50) = &cf_/gameapi/v1/payment/createRecharge;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x58);
  *(cfstringStruct **)(param_1 + 0x58) = &cf_/gameapi/v1/payment/ios;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x60);
  *(cfstringStruct **)(param_1 + 0x60) = &cf_/gameapi/v1/payment/cost;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x68);
  *(cfstringStruct **)(param_1 + 0x68) = &cf_/gameapi/v1/payment/add/v2;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x70);
  *(cfstringStruct **)(param_1 + 0x70) = &cf_/gameapi/v1/mail/getUserMail;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x78);
  *(cfstringStruct **)(param_1 + 0x78) = &cf_/gameapi/v1/mail/changeMailState;
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x80);
  *(cfstringStruct **)(param_1 + 0x80) = &cf_"";
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x88);
  *(cfstringStruct **)(param_1 + 0x88) = &cf_"";
  _objc_release(uVar1);
  uVar1 = *(undefined8 *)(param_1 + 0x90);
  *(cfstringStruct **)(param_1 + 0x90) = &cf_"";
  _objc_release(uVar1);
  *(undefined2 *)(param_1 + 0x98) = 0;
  *(undefined1 *)(param_1 + 0x9a) = 0;
  if (*(long *)PTR____stack_chk_guard_05e7c9a8 == lVar3) {
    return;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}