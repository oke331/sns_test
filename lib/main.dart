import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      body: StreamBuilder<User>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (!snapshot.hasData || snapshot.data == null)
                    Text('ログイン状態：未ログイン'),
                  if (snapshot.data != null && snapshot.data.isAnonymous)
                    Text('ログイン状態：匿名ユーザー\nユーザーID：${snapshot.data.uid}'),
                  if (snapshot.data != null && !snapshot.data.isAnonymous)
                    Text('ログイン状態：Googleログイン中\nユーザーID：${snapshot.data.uid}'),
                  SizedBox(height: 30),
                  ElevatedButton(
                    child: Text('匿名ログイン'),
                    onPressed: () async {
                      await _auth.signInAnonymously();
                    },
                  ),
                  ElevatedButton(
                    child: Text('Google ログイン'),
                    onPressed: () async {
                      await _handleGoogleSignIn(context);
                    },
                  ),
                  ElevatedButton(
                    child: Text('Google ログイン & 匿名紐付け'),
                    onPressed: () async {
                      await _handleGoogleSignInAndConnectAnonymous(context);
                    },
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    child: Text('サインアウト'),
                    onPressed: () async {
                      _handleSignOut(context);
                    },
                    style: ElevatedButton.styleFrom(primary: Colors.red),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    child: Text('日付とユーザー書き込み'),
                    onPressed: () async {
                      await _setUserIdAndDateTime(context);
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.yellow,
                      onPrimary: Colors.black,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.autorenew),
        onPressed: () => setState(() {}),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
      await _auth.signInWithCredential(credential);
    } on Exception catch (e) {
      final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
      Scaffold.of(context).showSnackBar(snackBar);
      print(e);
    }
  }

  Future<void> _handleGoogleSignInAndConnectAnonymous(
      BuildContext context) async {
    if (_auth.currentUser == null) {
      final snackBar = SnackBar(content: Text('匿名ログインしてからにしてくれい'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }

    try {
      GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
      await _auth.currentUser.linkWithCredential(credential);
      final snackBar = SnackBar(content: Text('リンク完了したかもだぜぇ？'));
      Scaffold.of(context).showSnackBar(snackBar);
    } on Exception catch (e) {
      final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
      Scaffold.of(context).showSnackBar(snackBar);
      print(e);
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await _auth.signOut();
      if (_googleSignIn != null && _googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }
      final snackBar = SnackBar(content: Text('サインアウト成功だぜぇ？'));
      Scaffold.of(context).showSnackBar(snackBar);
    } on Exception catch (e) {
      final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
      Scaffold.of(context).showSnackBar(snackBar);
      print(e);
    }
  }

  Future<void> _setUserIdAndDateTime(BuildContext context) async {
    if (_auth.currentUser == null) {
      final snackBar = SnackBar(content: Text('認証情報がないぜぇ？'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }
    try {
      final fireStore = FirebaseFirestore.instance;
      await fireStore
          .collection('user')
          .doc(_auth.currentUser.uid)
          .collection(DateTime.now().toString())
          .doc()
          .set({
        'test': true,
      }, SetOptions(merge: false));
      final snackBar = SnackBar(content: Text('書き込み完了だぜぇ？'));
      Scaffold.of(context).showSnackBar(snackBar);
    } on Exception catch (e) {
      final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
      Scaffold.of(context).showSnackBar(snackBar);
      print(e);
    }
  }
}
