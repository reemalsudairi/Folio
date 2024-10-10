import 'dart:math';

import 'package:flutter/material.dart';
import 'package:folio/constant/callInfo.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';


final userId = Random().nextInt(9999);
class CallPage extends StatelessWidget {
  const CallPage({Key? key, required this.callID, }) : super(key: key);
  final String callID;


  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: CallInfo.appId, // Fill in the appID that you get from ZEGOCLOUD Admin Console.
      appSign: CallInfo.appsign, // Fill in the appSign that you get from ZEGOCLOUD Admin Console.
      userID: userId.toString(),
      userName: 'user_name',
      callID: callID,
      // You can also use groupVideo/groupVoice/oneOnOneVoice to make more types of calls.
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }
}
