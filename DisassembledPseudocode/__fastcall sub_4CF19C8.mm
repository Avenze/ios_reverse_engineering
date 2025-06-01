void __fastcall sub_4CF19C8(__int64 a1, int a2, id a3)
{
  id v4; // x20
  void *v5; // x22
  void *v6; // x23

  v4 = objc_retain(a3);
  NSLog(&CFSTR("%@ : requestData success : %@").isa, *(_QWORD *)(*(_QWORD *)(a1 + 32) + 8LL), v4);
  v5 = objc_retainAutoreleasedReturnValue(objc_msgSend(v4, "objectForKey:", CFSTR("data")));
  v6 = objc_retainAutoreleasedReturnValue(+[NSMutableDictionary dictionary](&OBJC_CLASS___NSMutableDictionary, "dictionary"));
  objc_msgSend(v6, "setObject:forKey:", CFSTR("true"), CFSTR("result"));
  objc_msgSend(v6, "setObject:forKey:", v5, CFSTR("data"));
  (*(void (**)(void))(*(_QWORD *)(a1 + 40) + 16LL))();
  objc_release(v6);
  objc_release(v5);
  objc_release(v4);
}