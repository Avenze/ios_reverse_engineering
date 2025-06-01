void __cdecl +[WarriorSDKUtil DownloadData:](id a1, SEL a2, id a3)
{
  id v3; // x19
  WarriorGameServerData *v4; // x20
  id v5; // x19
  _QWORD v6[4]; // [xsp+8h] [xbp-38h] BYREF
  id v7; // [xsp+28h] [xbp-18h]

  v3 = objc_retain(a3);
  v4 = objc_retainAutoreleasedReturnValue(+[WarriorGameServerData sharedInstance](&OBJC_CLASS___WarriorGameServerData, "sharedInstance"));
  v6[0] = _NSConcreteStackBlock;
  v6[1] = 3254779904LL;
  v6[2] = sub_16AB46C;
  v6[3] = &unk_5F8A010;
  v7 = v3;
  v5 = objc_retain(v3);
  -[WarriorGameServerData requestData:](v4, "requestData:", v6);
  objc_release(v4);
  objc_release(v7);
  objc_release(v5);
}