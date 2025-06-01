void __cdecl -[WarriorGameServerData requestData:](WarriorGameServerData *self, SEL a2, id a3)
{
  id v4; // x19
  WarriorGameServer *v5; // x20
  unsigned __int8 v6; // w21
  WarriorGameInfo *v7; // x21
  id v8; // x20
  WarriorGameInfo *v9; // x21
  WarriorGameInfo *v10; // x21
  WarriorGameServer *v11; // x21
  WarriorGameServer *v12; // x21
  id v13; // x24
  WarriorGameServer *v14; // x21
  id v15; // x26
  id v16; // x27
  NSDictionary *v17; // x28
  WarriorGameServer *v18; // x22
  id v19; // x23
  NSString *v20; // x21
  id v21; // x22
  void *v22; // x22
  id v23; // x22
  id v24; // x22
  id v25; // x0
  void *v26; // x20
  id v27; // [xsp+18h] [xbp-158h]
  id v28; // [xsp+20h] [xbp-150h]
  id v29; // [xsp+28h] [xbp-148h]
  _QWORD v30[5]; // [xsp+30h] [xbp-140h] BYREF
  id v31; // [xsp+58h] [xbp-118h]
  _QWORD v32[5]; // [xsp+60h] [xbp-110h] BYREF
  id v33; // [xsp+88h] [xbp-E8h]
  _QWORD v34[7]; // [xsp+90h] [xbp-E0h] BYREF
  _QWORD v35[7]; // [xsp+C8h] [xbp-A8h] BYREF

  v4 = objc_retain(a3);
  v5 = objc_retainAutoreleasedReturnValue(+[WarriorGameServer sharedInstance](&OBJC_CLASS___WarriorGameServer, "sharedInstance"));
  v6 = -[WarriorGameServer getIsLogin](v5, "getIsLogin");
  objc_release(v5);
  if ( (v6 & 1) != 0 )
  {
    v7 = objc_retainAutoreleasedReturnValue(+[WarriorGameInfo sharedInstance](&OBJC_CLASS___WarriorGameInfo, "sharedInstance"));
    v8 = objc_retainAutoreleasedReturnValue(-[WarriorGameInfo getGameParam:](v7, "getGameParam:", CFSTR("warrior_server_app_id")));
    objc_release(v7);
    v9 = objc_retainAutoreleasedReturnValue(+[WarriorGameInfo sharedInstance](&OBJC_CLASS___WarriorGameInfo, "sharedInstance"));
    v29 = objc_retainAutoreleasedReturnValue(-[WarriorGameInfo getGameParam:](v9, "getGameParam:", CFSTR("warrior_server_app_name")));
    objc_release(v9);
    v10 = objc_retainAutoreleasedReturnValue(+[WarriorGameInfo sharedInstance](&OBJC_CLASS___WarriorGameInfo, "sharedInstance"));
    v28 = objc_retainAutoreleasedReturnValue(-[WarriorGameInfo getGameParam:](v10, "getGameParam:", CFSTR("warrior_server_channel")));
    objc_release(v10);
    v11 = objc_retainAutoreleasedReturnValue(+[WarriorGameServer sharedInstance](&OBJC_CLASS___WarriorGameServer, "sharedInstance"));
    v27 = objc_retainAutoreleasedReturnValue(-[WarriorGameServer getUuid](v11, "getUuid"));
    objc_release(v11);
    v12 = objc_retainAutoreleasedReturnValue(+[WarriorGameServer sharedInstance](&OBJC_CLASS___WarriorGameServer, "sharedInstance"));
    v13 = objc_retainAutoreleasedReturnValue(-[WarriorGameServer getUserId](v12, "getUserId"));
    objc_release(v12);
    v14 = objc_retainAutoreleasedReturnValue(+[WarriorGameServer sharedInstance](&OBJC_CLASS___WarriorGameServer, "sharedInstance"));
    v15 = objc_retainAutoreleasedReturnValue(-[WarriorGameServer getToken](v14, "getToken"));
    objc_release(v14);
    v16 = objc_retainAutoreleasedReturnValue(+[AFHTTPSessionManager manager](&OBJC_CLASS___AFHTTPSessionManager, "manager"));
    v34[0] = CFSTR("Content-Type");
    v34[1] = CFSTR("X-WRE-APP-ID");
    v35[0] = CFSTR("application/json");
    v35[1] = v8;
    v34[2] = CFSTR("X-WRE-APP-NAME");
    v34[3] = CFSTR("X-WRE-VERSION");
    v35[2] = v29;
    v35[3] = CFSTR("1.0.1");
    v34[4] = CFSTR("X-WRE-CHANNEL");
    v34[5] = CFSTR("X-WRE-TOKEN");
    v35[4] = v28;
    v35[5] = v15;
    v34[6] = CFSTR("USERID");
    v35[6] = v13;
    v17 = objc_retainAutoreleasedReturnValue(
            +[NSDictionary dictionaryWithObjects:forKeys:count:](
              &OBJC_CLASS___NSDictionary,
              "dictionaryWithObjects:forKeys:count:",
              v35,
              v34,
              7));
    v18 = objc_retainAutoreleasedReturnValue(+[WarriorGameServer sharedInstance](&OBJC_CLASS___WarriorGameServer, "sharedInstance"));
    v19 = objc_retainAutoreleasedReturnValue(-[WarriorGameServer getRequestDataUrl](v18, "getRequestDataUrl"));
    v20 = objc_retainAutoreleasedReturnValue(
            +[NSString stringWithFormat:](
              &OBJC_CLASS___NSString,
              "stringWithFormat:",
              CFSTR("%@?uuid=%@&appId=%@"),
              v19,
              v27,
              v8));
    objc_release(v19);
    objc_release(v18);
    v21 = objc_retainAutoreleasedReturnValue(+[AFJSONRequestSerializer serializer](&OBJC_CLASS___AFJSONRequestSerializer, "serializer"));
    objc_msgSend(v16, "setRequestSerializer:", v21);
    objc_release(v21);
    v22 = objc_retainAutoreleasedReturnValue(objc_msgSend(v16, "requestSerializer"));
    objc_msgSend(v22, "setTimeoutInterval:", 10.0);
    objc_release(v22);
    v23 = objc_retainAutoreleasedReturnValue(+[AFJSONResponseSerializer serializer](&OBJC_CLASS___AFJSONResponseSerializer, "serializer"));
    objc_msgSend(v16, "setResponseSerializer:", v23);
    objc_release(v23);
    v24 = objc_retain(__NSDictionary0__);
    v32[0] = _NSConcreteStackBlock;
    v32[1] = 3254779904LL;
    v32[2] = sub_4CF19C8;
    v32[3] = &unk_613B2F0;
    v32[4] = self;
    v33 = objc_retain(v4);
    v30[0] = _NSConcreteStackBlock;
    v30[1] = 3254779904LL;
    v30[2] = sub_4CF1AA0;
    v30[3] = &unk_613B1C0;
    v30[4] = self;
    v31 = objc_retain(v33);
    v25 = objc_unsafeClaimAutoreleasedReturnValue(
            objc_msgSend(
              v16,
              "GET:parameters:headers:progress:success:failure:",
              v20,
              v24,
              v17,
              &stru_613B320,
              v32,
              v30));
    objc_release(v31);
    objc_release(v33);
    objc_release(v24);
    objc_release(v20);
    objc_release(v17);
    objc_release(v16);
    objc_release(v15);
    objc_release(v13);
    objc_release(v27);
    objc_release(v28);
    objc_release(v29);
    objc_release(v8);
  }
  else
  {
    v26 = objc_retainAutoreleasedReturnValue(+[NSMutableDictionary dictionary](&OBJC_CLASS___NSMutableDictionary, "dictionary"));
    objc_msgSend(v26, "setObject:forKey:", CFSTR("false"), CFSTR("result"));
    objc_msgSend(v26, "setObject:forKey:", CFSTR("1000"), CFSTR("errorCode"));
    (*((void (__fastcall **)(id, void *))v4 + 2))(v4, v26);
    objc_release(v26);
  }
  objc_release(v4);
}