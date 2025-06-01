syntax = "proto2";
//package PackagePlayer;

message msg_mail_item 
{
	optional int32           id          = 1;   //物品ID
	optional int32           num         = 2;   //数量
};

message msg_mail_info 
{
	optional int32 id = 1;
	optional string subject = 2;
	optional string body = 3;
	optional string sender = 4;
	optional int32 date = 5;
	repeated msg_mail_item attachment = 6;
	optional int32 state = 7;
};
//客户端请求所有邮件
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_MAIL_INFO, 1050) //req nil 1050

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_MAIL_INFO, 1050) //ack msg_s2c_ack_mail_info
message msg_s2c_ack_mail_info
{
	optional int32            errno     = 1;
	repeated msg_mail_info	mail_info = 2;
};

//客户端读取邮件
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_MAIL_READ, 1051) //req msg_c2s_req_mail_read 1051
message msg_c2s_req_mail_read
{
	optional int32 id = 1;
};

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_MAIL_READ, 1051) //ack msg_s2c_ack_mail_read
message msg_s2c_ack_mail_read
{
	optional int32            errno     = 1;
};

//客户端删除邮件
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_MAIL_DELETE, 1052) //req msg_c2s_req_mail_delete 1052
message msg_c2s_req_mail_delete
{
	repeated int32 ids = 1;
};

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_MAIL_DELETE, 1052) //ack msg_s2c_ack_mail_delete
message msg_s2c_ack_mail_delete
{
	optional int32            errno     = 1;
};

//客户端领取邮件附件
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_MAIL_TAKE, 1053) //req msg_c2s_req_mail_take 1053
message msg_c2s_req_mail_take
{
	repeated int32 ids = 1;
};

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_MAIL_TAKE, 1053) //ack msg_s2c_ack_mail_take
message msg_s2c_ack_mail_take
{
	optional int32            errno     = 1;
	repeated msg_mail_item items = 2;
};



//上报分数 新版
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_REPORT_RANK, 1061) //req msg_c2s_req_report_rank 1061
message msg_c2s_req_report_rank
{
	optional string          user_id = 1;
	optional string          version = 2;
	optional int32           score = 3;
	optional string          language = 4;
	optional string          scene_id = 5;
	optional string          username = 6;
	optional int32           gender = 7;
	optional int32           skin = 8;
	optional int32           hat = 9;
	optional int32           bag = 10;
	optional int32           instance_id = 11;
	optional int32           instance_index = 12;
	optional string          total_rent = 13;
	optional int32           max_develop_country_building_id = 14;
};

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_REPORT_RANK, 1061) //ack msg_s2c_ack_report_rank 1061
message msg_s2c_ack_report_rank
{
	optional int32            errno = 1; //0:成功， 3-服务器协议和客户端不匹配
	//	optional string 					version = 2;
	repeated RankData      	  rank_data = 5; // 排名数据
	optional string           group_key = 6;
	optional int32            group_created_at = 7;
};

message RankData {
	required string 		 user_id = 1;
	required string 		 username = 2;
	required float 			 score = 3;
	required int32 			 gender = 4;
	required int32 			 skin = 5;
	required int32 			 hat = 6;
	required int32 			 bag = 7;
	optional string          total_rent = 13;
	optional int32           max_develop_country_building_id = 14;
}

//排行榜前几名
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_GET_RANK, 1062) //req msg_c2s_req_get_report_rank 1062
message msg_c2s_req_get_report_rank
{
	optional string          user_id = 1;
	optional string          version = 2;
	optional string          language = 3;
	optional string          scene_id = 4;
	optional int32           instance_id = 11;
	optional int32           instance_index = 12;
};

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_GET_RANK, 1062) //ack msg_s2c_ack_get_report_rank 1062
message msg_s2c_ack_get_report_rank
{
	optional int32            errno = 1; //0:成功， 3-服务器协议和客户端不匹配
	//	optional string 				version = 2;
	//  optional string 				rank_type = 3; // 排行榜类型，即是哪一类排行榜
	//  optional int32 					rank_offset = 4; // 排行榜偏移量，即是 0为 当天或当周，-1为 昨天或上周， -2为 前天或上上周等
	repeated RankData         rank_data = 5; // 排名数据
	optional string           group_key = 6;
	optional int32            group_created_at = 7;
};

//作弊通知服务器
//BEGIN_MSG_DEFINE(MSG_C2S_REQ_CHEAT_TAG, 1063) //req msg_c2s_req_cheat_tag 1063
message msg_c2s_req_cheat_tag
{
	optional string           user_id = 1;
	optional string           version = 2;
	optional int32            instance_id = 11;
	optional int32            instance_index = 12;
};

//BEGIN_MSG_DEFINE(MSG_S2C_ACK_CHEAT_TAG, 1063) //ack msg_s2c_ack_cheat_tag
message msg_s2c_ack_cheat_tag
{
	optional int32          errno = 1;
	//	optional string					version = 2;
};
