import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:random_video_call/resources/color.dart';
import 'package:random_video_call/services/add_state.dart';
import 'package:random_video_call/services/database_service.dart';
import 'package:random_video_call/views/video_call_service/pages/index.dart';

class VideoCall extends StatefulWidget {
  final userName;
  VideoCall({this.userName});
  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> with WidgetsBindingObserver {
  BannerAd bannerAd;

  bool clicked = false;
  String userId = "";
  StreamSubscription<dynamic> _eventsSubscription;

  var element;
  Timer timer, timer2;
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);
    adState.initialization.then((status) {
      setState(() {
        bannerAd = BannerAd(
          size: AdSize.banner,
          adUnitId: adState.bannerAdUnitId,
          listener: adState.adListener,
          request: AdRequest(),
        )..load();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getUserID();
  }

  getUserID() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();

    setState(() {
      userId = user.uid;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      DatabaseService().updateOnlineStatus(userId: userId, status: false);
    } else if (state == AppLifecycleState.detached) {
      DatabaseService().updateOnlineStatus(userId: userId, status: false);
    } else if (state == AppLifecycleState.resumed && userId != null) {
      DatabaseService().updateOnlineStatus(userId: userId, status: true);
    } else if (state == AppLifecycleState.inactive) {
      DatabaseService().updateOnlineStatus(userId: userId, status: true);
    }

    super.didChangeAppLifecycleState(state);
  }

  _onbackPressed() async {
    var result = await DatabaseService()
        .updateOnlineStatus(userId: userId, status: false);
    print(result);
  }

  hell() {
    print("hello");
  }

  searchUser() async {
    var _random = new Random();

    print("currentuserId : " + userId);
    bool flag = true;
    Timer(Duration(seconds: 15), (() {
      setState(() {
        clicked = false;
        flag = false;
        Get.snackbar("No User Found", "Try Again Later",
            snackPosition: SnackPosition.BOTTOM);
        return;
      });
    }));

    await Firestore.instance
        .collection('Users')
        .where("online", isEqualTo: true)
        .getDocuments()
        .then((value) async {
      //change while founded userId == current Userid

      dynamic tempElement =
          value.documents[_random.nextInt(value.documents.length)];

      if (value.documents.length > 1) {
        while ((tempElement['userId'] == userId ||
                tempElement['callStatus'] == true) &&
            flag == true) {
          if (flag == false) break;
          tempElement =
              value.documents[_random.nextInt(value.documents.length)];
        }
      }

      //update status.....
      if (tempElement != null && tempElement['userId'] != userId) {
        setState(() {
          element = tempElement;
        });

        dynamic ans = await DatabaseService().updateCallingStatus(
            callFromId: userId, callToId: element['userId']);
        print(ans);
      }
    });

    if (element != null) {}
  }

  searchRandomPerson() async {
    int count = 0;
    // timer = new Timer.periodic(const Duration(seconds: 2), (t) {
    //       count++;
    //       print(count);
    //       if(count == 4) {
    //         timer.cancel();
    //         setState(() {
    //           clicked = false;
    //         });
    //       }

    // });

    await searchUser();

    print("Searching");

    print(count);

    if (timer != null) timer.cancel();

    print(element['userId']);

    if (element == null) {
      timer = new Timer.periodic(Duration(seconds: 1), (t) async {
        await searchUser();
        count++;
        print(count);
        if (element != null) {
          print(element['userId']);
          callUser();
          timer.cancel();
        } else if (count == 15 && element != null) {
          setState(() {
            clicked = false;
          });
          print("User Found on 15th second");
          timer.cancel();
        } else if (count == 15) {
          setState(() {
            clicked = false;
          });
          Get.snackbar("No User Found", " Please Try again after some time",
              snackPosition: SnackPosition.BOTTOM);
          print("NO user Found");
          timer.cancel();
        }
      });
    }

    if (count == 15) {
      timer.cancel();
    }

    if (timer != null) timer.cancel();

    callUser();
  }

  callUser() {
    if (element != null && element['userId'] != null) {
      _eventsSubscription = Firestore.instance
          .collection("Users")
          .document(userId)
          .snapshots()
          .listen((event) {
        print(event.data['callStatus']);

        if (event.data['callStatus'] == true) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => IndexPage(
                  videoId: userId,
                ),
              ));
        } else if (event.data['rejected'] == true) {
          Get.snackbar("Rejected", "User Found but call Rejected");
        }
      });

      Timer(Duration(seconds: 10), (() async {
        _eventsSubscription.cancel();
        await DatabaseService()
            .updateCallingStatus(callFromId: null, callToId: element['userId']);
        Get.snackbar("Call not answerd", "Try again later",
            snackPosition: SnackPosition.BOTTOM);
        setState(() {
          clicked = false;
        });
      }));
    }
  }

  _acceptCall(String callId) async {
    await Firestore.instance.collection("Users").document(callId).updateData({
      "callStatus": true,
    });

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IndexPage(
            videoId: callId,
            userId: userId,
          ),
        ));
  }

  _rejectCall(String callId) async {
    await Firestore.instance.collection("Users").document(callId).updateData({
      "callStatus": null,
      "rejected": true,
    });
    DatabaseService().updateCallingStatus(
        callFromId: null, callToId: userId, callStatus: null);
  }

  @override
  Widget build(BuildContext context) {
    String wellcomeString =
        "Hi,\n ${widget.userName != null ? widget.userName : ' '} Welcome! Lets talk with people and improve your communication skills..... ";

    return WillPopScope(
      onWillPop: () async {
        _onbackPressed();
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text("Home Screen"),
          ),
          body: Column(
            children: [
              SizedBox(
                height: 40,
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: Text(
                  wellcomeString,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(height: 100),
              Container(
                alignment: Alignment.center,
                child: StreamBuilder(
                  stream: Firestore.instance
                      .collection("Users")
                      .where("userId", isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data.documents[0]['calling'] != null) {
                      return Container(
                        child: Column(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              child: Text(
                                " Hey, Incoming Call ",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 50,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                RawMaterialButton(
                                  shape: CircleBorder(),
                                  fillColor: Colors.green,
                                  constraints: BoxConstraints(
                                      maxHeight: 1000,
                                      minHeight: 100,
                                      minWidth: 100,
                                      maxWidth: 1000),
                                  onPressed: () {
                                    _acceptCall(
                                        snapshot.data.documents[0]['calling']);
                                  },
                                  child: Icon(
                                    Icons.call,
                                    color: white,
                                  ),
                                ),
                                RawMaterialButton(
                                    shape: CircleBorder(),
                                    fillColor: Colors.red,
                                    constraints: BoxConstraints(
                                        maxHeight: 1000,
                                        minHeight: 100,
                                        minWidth: 100,
                                        maxWidth: 1000),
                                    onPressed: () {
                                      _rejectCall(snapshot.data.documents[0]
                                          ['calling']);
                                    },
                                    child: Icon(
                                      Icons.call_end,
                                      color: white,
                                    ))
                              ],
                            ),
                          ],
                        ),
                      );
                    } else {
                      return clicked == false ||
                              snapshot.data.documents[0]['rejected'] == true
                          ? Container(
                              child: RawMaterialButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              padding: EdgeInsets.all(25),
                              fillColor: Colors.blue,
                              child: Text(
                                "Connect to a Random Person",
                                style: TextStyle(color: white, fontSize: 18),
                              ),
                              onPressed: () {
                                setState(() {
                                  clicked = true;
                                });
                                searchRandomPerson();
                              },
                            ))
                          : Container(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
              SizedBox(
                height: 100,
              ),
              Container(
                alignment: Alignment.bottomCenter,
                child: bannerAd == null
                    ? SizedBox(
                        height: 50,
                      )
                    : Container(
                        height: 50,
                        child: AdWidget(
                          ad: bannerAd,
                        ),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
