

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'database_service.dart';

class LoginService{
  GoogleSignIn _googleSignIn = GoogleSignIn();
  DatabaseService databaseService = DatabaseService();
  FirebaseAuth _auth  = FirebaseAuth.instance;


  Future<FirebaseUser> googleSignIn() async {
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    AuthCredential credential = GoogleAuthProvider.getCredential(idToken:googleAuth.idToken,
        accessToken: googleAuth.accessToken);

    AuthResult result = await _auth.signInWithCredential(credential);
  
    FirebaseUser user  =  result.user;
    await databaseService.createUserInDatabase(email: user.email,userId:user.uid,online: true);

    return user;
  }

}