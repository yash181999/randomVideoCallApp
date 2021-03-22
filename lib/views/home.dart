import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:random_video_call/resources/color.dart';
import 'package:random_video_call/services/add_state.dart';
import 'package:random_video_call/services/login_service.dart';
import 'package:random_video_call/views/video_call.dart';


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  BannerAd bannerAd;

  LoginService authService = LoginService();

  String userId;

  String userName;

 



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

  _login() async {
    dynamic authResult = await authService.googleSignIn();
    setState(() {
      userId = authResult.uid;
      userName = authResult.displayName;
    });
    if (authResult != null) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => VideoCall(
                    userName: userName,
                  )));
    }
  }


   

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0.0,
        title: Text(
          "Login",
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      ),
      body: Container(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 10,
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              "Welcome!",
              style: TextStyle(fontSize: 24),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              "Login To Continue",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.50,
            width: MediaQuery.of(context).size.height * 0.40,
            child: Image(
              image: AssetImage('assets/videocall_icon.png'),
            ),
          ),
          Container(
            padding: EdgeInsets.all(30),
            child: MaterialButton(
                onPressed: _login,
                color: white,
                child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(top: 20, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 20,
                          width: 20,
                          child: Image(
                            image: AssetImage(
                              "assets/google_icon.png",
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Login With Google")
                      ],
                    ))),
          ),
          if (bannerAd == null)
            SizedBox(
              height: 50,
            )
          else
            Container(
              height: 50,
              child: AdWidget(
                ad: bannerAd,
              ),
            )
        ],
      )),
    );
  }
}
