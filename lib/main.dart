import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'ログイン検証アプリ'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _googleSignIn = new GoogleSignIn();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_auth == null) Text('ログイン状態：未ログイン'),
            if (_auth != null && _auth.currentUser.isAnonymous)
              Text('ログイン状態：匿名ユーザー'),
            if (_auth != null && _auth.currentUser.displayName != null)
              Text(
                  'ログイン状態：Googleログイン中\nユーザー名：${_auth.currentUser.displayName}'),
            ElevatedButton(
              child: Text('匿名ログイン'),
              onPressed: () async {
                await _auth.signInAnonymously();
              },
            ),
            ElevatedButton(
              child: Text('Google ログイン'),
              onPressed: () async {
                await _handleGoogleSignIn();
              },
            ),
            ElevatedButton(
              child: Text('匿名ユーザーサインアウト'),
              onPressed: () async {
                if (_auth != null && _auth.currentUser.isAnonymous) {
                  await _auth.signOut();
                }
              },
            ),
            ElevatedButton(
              child: Text('Googleユーザーサインアウト'),
              onPressed: () async {
                _handleGoogleSignOut();
              },
            ),
            ElevatedButton(
              child: Text('日付とユーザー書き込み'),
              onPressed: () async {
                await _setUserIdAndDateTime(context);
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
    await _auth.signInWithCredential(credential);
    setState(() {});
  }

  Future<void> _handleGoogleSignOut() async {
    await _auth.signOut();
    if (_googleSignIn != null && _googleSignIn.currentUser != null) {
      await _googleSignIn.signOut();
    }
  }

  Future<void> _setUserIdAndDateTime(BuildContext context) async {
    if (_auth == null) {
      final snackBar = SnackBar(content: Text('認証情報がありません！'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }
    final fireStore = FirebaseFirestore.instance;
    await fireStore.collection('user').doc(_auth.currentUser.uid).set({
      'datetime': DateTime.now(),
    }, SetOptions(merge: false));
  }
}
