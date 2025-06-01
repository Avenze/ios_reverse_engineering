syntax = "proto2";
//package login;

//获得游戏服地址
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_LOGIN_ADDR, 1000) //req msg_c2s_req_login_addr 1000
message msg_c2s_req_login_addr 
{
  optional string userid = 1; //玩家的ID
  optional string bundleid = 2;  //包的唯一标识符
  optional string platform = 3;  //当前客户端平台，IOS, Android, UnityEditor
  optional string version = 4;   //协议版本号
};

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_LOGIN_ADDR, 1000) //ack msg_s2c_req_login_addr
message msg_s2c_req_login_addr 
{
  optional int32 errno            = 1;   //0:成功 1维护 2服务器关闭中, 3服务器协议和客户端不匹配
  optional string ip = 2;
  optional int32 port = 3;	
  optional string token = 4;
  optional string version = 5;          //服务器协议版本号
};

//登录
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_LOGIN, 1001) //req msg_c2s_req_login 1001
message msg_c2s_req_login 
{
  optional string userid = 1;
  optional string username = 2;
  optional int32 startlvl = 3;
  optional string version = 4;	
};

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_LOGIN, 1001) //ack msg_s2c_req_login 1001
message msg_s2c_req_login
{
  optional int32 errno = 1; //0:成功， 3-服务器协议和客户端不匹配
  optional string userid = 2;
};

//登出游戏服务器
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_LOGOUT, 1002) //req msg_c2s_req_logout
message msg_c2s_req_logout
{
  optional string userid = 1; //玩家的ID
  optional string version = 4;
};

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_LOGOUT, 1002) //ack msg_s2c_ack_logout
message msg_s2c_ack_logout
{
  optional int32 errno = 1; //0:成功， 3-服务器协议和客户端不匹配
};

