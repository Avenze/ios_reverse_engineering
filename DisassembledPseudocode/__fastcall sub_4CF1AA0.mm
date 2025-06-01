void __fastcall sub_4CF1AA0(__int64 a1, __int64 a2, __int64 a3)
{
  void *v4; // x20

  NSLog(&CFSTR("%@ : requestData failed : %@").isa, *(_QWORD *)(*(_QWORD *)(a1 + 32) + 8LL), a3);
  v4 = objc_retainAutoreleasedReturnValue(+[NSMutableDictionary dictionary](&OBJC_CLASS___NSMutableDictionary, "dictionary"));
  objc_msgSend(v4, "setObject:forKey:", CFSTR("false"), CFSTR("result"));
  objc_msgSend(v4, "setObject:forKey:", CFSTR("1002"), CFSTR("errorCode"));
  (*(void (**)(void))(*(_QWORD *)(a1 + 40) + 16LL))();
  objc_release(v4);
}