import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  Firestore db = Firestore.instance;

  Future<dynamic> createUserInDatabase(
      {String email, bool online, String userId}) async {
    try {
      await db.collection('Users').document(userId).setData({
        'email': email,
        'online': online,
        'userId': userId,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<dynamic> updateCallingStatus(
      {String callToId, String callFromId,  bool callStatus}) async {
    try {
      await db.collection("Users").document(callToId).updateData({
        'calling': callFromId,
        'callStatus' : callStatus,
      });
      return true;
    } catch (e) {
      print("Connetion error : " + e);
      return false;
    }
  }

  Future<dynamic> updateOnlineStatus({String userId, bool status}) async {
    try {
      await db.collection("Users").document(userId).updateData({
        'online': status,
      });
      return true;
    } catch (e) {
      print("Connetion error : " + e);
      return false;
    }
  }
}
