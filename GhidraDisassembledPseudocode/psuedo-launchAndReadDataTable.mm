
/* Function Stack Size: 0x10 bytes */

void __thiscall
WarriorGameInfo::launchAndReadDataTable(WarriorGameInfo *this,ID param_1,SEL param_2)

{
  long lVar1;
  cfstringStruct *pcVar2;
  undefined8 uVar3;
  cfstringStruct *pcVar4;
  ulong uVar5;
  undefined *puVar6;
  class_t *pcVar7;
  class_t *pcVar8;
  class_t *pcVar9;
  class_t *pcVar10;
  class_t *pcVar11;
  bool bVar12;
  undefined8 uVar13;
  ulong uVar14;
  class_t *pcVar15;
  undefined8 in_d0;
  
  FUN_04eba960();
  *(undefined8 *)(param_1 + 0x28) = in_d0;
  FUN_04eba960(param_1);
  *(undefined8 *)(param_1 + 0x40) = in_d0;
  lVar1 = *(long *)(param_1 + 0x58);
  FUN_04e891c0();
  if (lVar1 == 0) {
    pcVar4 = &cf_"";
  }
  else {
    uVar14 = 0;
    bVar12 = true;
    pcVar4 = &cf_"";
    do {
      pcVar2 = pcVar4;
      if (!bVar12) {
        FUN_04f95c80();
        _objc_retainAutoreleasedReturnValue();
        _objc_release(pcVar4);
      }
      uVar3 = *(undefined8 *)(param_1 + 0x58);
      FUN_04f04f20(uVar3);
      _objc_retainAutoreleasedReturnValue();
      pcVar4 = pcVar2;
      FUN_04f95c80();
      _objc_retainAutoreleasedReturnValue();
      _objc_release(pcVar2);
      _objc_release(uVar3);
      uVar14 = uVar14 + 1;
      uVar5 = *(ulong *)(param_1 + 0x58);
      FUN_04e891c0();
      bVar12 = false;
    } while (uVar14 < uVar5);
  }
  puVar6 = &_OBJC_CLASS_$_NSString;
  FUN_04f96440();
  _objc_retainAutoreleasedReturnValue();
  pcVar7 = &objc::class_t::SQLiteDatabaseTools;
  FUN_04f863c0();
  _objc_retainAutoreleasedReturnValue();
  pcVar8 = pcVar7;
  FUN_04f20400();
  _objc_retainAutoreleasedReturnValue();
  _objc_release(pcVar7);
  pcVar9 = &objc::class_t::WarriorGame;
  FUN_04f863c0();
  _objc_retainAutoreleasedReturnValue();
  pcVar7 = pcVar9;
  FUN_04eb3f20();
  _objc_release(pcVar9);
  if (((ulong)pcVar7 & 1) != 0) {
    _NSLog(&cf_%@,GameInfoSql:%@);
  }
  pcVar7 = pcVar8;
  FUN_04e891c0();
  if (pcVar7 != (class_t *)0x0) {
    pcVar7 = (class_t *)0x0;
    do {
      pcVar9 = pcVar8;
      FUN_04f04f20();
      _objc_retainAutoreleasedReturnValue();
      uVar3 = *(undefined8 *)(param_1 + 0x58);
      FUN_04f04f20(uVar3);
      _objc_retainAutoreleasedReturnValue();
      pcVar10 = pcVar9;
      FUN_04f050a0();
      _objc_retainAutoreleasedReturnValue();
      _objc_release(uVar3);
      uVar3 = *(undefined8 *)(param_1 + 0x60);
      FUN_04f04f20(uVar3);
      _objc_retainAutoreleasedReturnValue();
      pcVar15 = pcVar10;
      FUN_04ee21e0();
      _objc_release(uVar3);
      if ((int)pcVar15 == 0) {
        uVar3 = *(undefined8 *)(param_1 + 0x60);
        FUN_04f04f20(uVar3);
        _objc_retainAutoreleasedReturnValue();
        pcVar15 = pcVar10;
        FUN_04ee21e0();
        _objc_release(uVar3);
        if ((int)pcVar15 == 0) {
          uVar3 = *(undefined8 *)(param_1 + 0x60);
          FUN_04f04f20(uVar3);
          _objc_retainAutoreleasedReturnValue();
          pcVar15 = pcVar10;
          FUN_04ee21e0();
          _objc_release(uVar3);
          if ((int)pcVar15 == 0) {
            uVar3 = *(undefined8 *)(param_1 + 0x60);
            FUN_04f04f20(uVar3);
            _objc_retainAutoreleasedReturnValue();
            pcVar15 = pcVar10;
            FUN_04ee21e0();
            _objc_release(uVar3);
            if ((int)pcVar15 == 0) {
              uVar3 = *(undefined8 *)(param_1 + 0x60);
              FUN_04f04f20(uVar3);
              _objc_retainAutoreleasedReturnValue();
              pcVar15 = pcVar10;
              FUN_04ee21e0();
              _objc_release(uVar3);
              if ((int)pcVar15 == 0) {
                uVar3 = *(undefined8 *)(param_1 + 0x60);
                FUN_04f04f20(uVar3);
                _objc_retainAutoreleasedReturnValue();
                pcVar15 = pcVar10;
                FUN_04ee21e0();
                _objc_release(uVar3);
                if ((int)pcVar15 == 0) goto LAB_04cfd840;
                pcVar15 = *(class_t **)(param_1 + 0x58);
                FUN_04f04f20(pcVar15);
                _objc_retainAutoreleasedReturnValue();
                pcVar11 = pcVar9;
                FUN_04f050a0();
                _objc_retainAutoreleasedReturnValue();
                uVar3 = *(undefined8 *)(param_1 + 0x98);
                *(class_t **)(param_1 + 0x98) = pcVar11;
                _objc_release(uVar3);
              }
              else {
                uVar3 = *(undefined8 *)(param_1 + 0x58);
                FUN_04f04f20(uVar3);
                _objc_retainAutoreleasedReturnValue();
                pcVar15 = pcVar9;
                FUN_04f050a0();
                _objc_retainAutoreleasedReturnValue();
                _objc_release(uVar3);
                pcVar11 = pcVar15;
                FUN_04edbe60();
                *(int *)(param_1 + 0x90) = (int)pcVar11;
              }
            }
            else {
              pcVar15 = (class_t *)&_OBJC_CLASS_$_NSDecimalNumber;
              uVar3 = *(undefined8 *)(param_1 + 0x58);
              FUN_04f04f20(uVar3);
              _objc_retainAutoreleasedReturnValue();
              pcVar11 = pcVar9;
              FUN_04f050a0(pcVar9);
              _objc_retainAutoreleasedReturnValue();
              FUN_04e931a0(&_OBJC_CLASS_$_NSDecimalNumber);
              _objc_retainAutoreleasedReturnValue();
              _objc_release(pcVar11);
              _objc_release(uVar3);
              FUN_04e9dfc0(pcVar15);
              *(undefined8 *)(param_1 + 0x88) = in_d0;
            }
          }
          else {
            pcVar15 = (class_t *)&_OBJC_CLASS_$_NSDecimalNumber;
            uVar3 = *(undefined8 *)(param_1 + 0x58);
            FUN_04f04f20(uVar3);
            _objc_retainAutoreleasedReturnValue();
            pcVar11 = pcVar9;
            FUN_04f050a0(pcVar9);
            _objc_retainAutoreleasedReturnValue();
            FUN_04e931a0(&_OBJC_CLASS_$_NSDecimalNumber);
            _objc_retainAutoreleasedReturnValue();
            _objc_release(pcVar11);
            _objc_release(uVar3);
            FUN_04e9dfc0(pcVar15);
            *(undefined8 *)(param_1 + 0x80) = in_d0;
          }
          goto LAB_04cfd83c;
        }
        uVar3 = *(undefined8 *)(param_1 + 0x58);
        FUN_04f04f20(uVar3);
        _objc_retainAutoreleasedReturnValue();
        pcVar15 = pcVar9;
        FUN_04f050a0();
        _objc_retainAutoreleasedReturnValue();
        uVar13 = *(undefined8 *)(param_1 + 0x78);
        *(class_t **)(param_1 + 0x78) = pcVar15;
        _objc_release(uVar13);
        _objc_release(uVar3);
        pcVar11 = &objc::class_t::WarriorGame;
        FUN_04f863c0();
        _objc_retainAutoreleasedReturnValue();
        pcVar15 = pcVar11;
        FUN_04eb3f20();
        _objc_release(pcVar11);
        if ((int)pcVar15 != 0) {
          _NSLog(&::cf_%);
        }
      }
      else {
        pcVar15 = (class_t *)&_OBJC_CLASS_$_NSDecimalNumber;
        uVar3 = *(undefined8 *)(param_1 + 0x58);
        FUN_04f04f20(uVar3);
        _objc_retainAutoreleasedReturnValue();
        pcVar11 = pcVar9;
        FUN_04f050a0(pcVar9);
        _objc_retainAutoreleasedReturnValue();
        FUN_04e931a0(&_OBJC_CLASS_$_NSDecimalNumber);
        _objc_retainAutoreleasedReturnValue();
        _objc_release(pcVar11);
        _objc_release(uVar3);
        FUN_04e9dfc0(pcVar15);
        *(undefined8 *)(param_1 + 0x38) = in_d0;
LAB_04cfd83c:
        _objc_release(pcVar15);
      }
LAB_04cfd840:
      _objc_release(pcVar10);
      _objc_release(pcVar9);
      pcVar7 = (class_t *)((long)&pcVar7->isa + 1);
      pcVar9 = pcVar8;
      FUN_04e891c0();
    } while (pcVar7 < pcVar9);
  }
  _objc_release(pcVar8);
  _objc_release(puVar6);
  _objc_release(pcVar4);
  return;
}