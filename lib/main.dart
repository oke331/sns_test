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
  String _email;
  String _pass;
  bool _isEmailVerified;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<User>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (!snapshot.hasData || snapshot.data == null)
                      Text('ログイン状態：未ログイン'),
                    SizedBox(height: 30),
                    if (snapshot.hasData && snapshot.data.isAnonymous)
                      Text('ログイン状態：匿名ログイン'),
                    if (snapshot.hasData)
                      for (UserInfo user in snapshot.data.providerData)
                        Column(
                          children: [
                            if (_isEmailVerified != null && _isEmailVerified)
                              Text('メール確認済'),
                            if (_isEmailVerified != null && !_isEmailVerified)
                              Column(
                                children: [
                                  Text('メール未確認'),
                                  ElevatedButton(
                                      onPressed: () async =>
                                          await _sendEmailVerification(),
                                      child: Text('認証メールを送る'))
                                ],
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Text(
                                  'ログイン状態：${user.providerId}\nuid：${user.uid}\nemail:${user.email}'),
                            ),
                          ],
                        ),
                    if (snapshot.hasData)
                      Text('Firebase上のuid：${snapshot.data.uid}'),
                    SizedBox(height: 30),
                    ElevatedButton(
                      child: Text('匿名ログイン'),
                      onPressed: () async {
                        try {
                          await _auth.signInAnonymously();
                        } on Exception catch (e) {
                          final snackBar =
                              SnackBar(content: Text('おっと失敗したようだ'));
                          Scaffold.of(context).showSnackBar(snackBar);
                          print(e);
                        }
                      },
                    ),
                    ElevatedButton(
                      child: Text('Google ログイン'),
                      onPressed: () async {
                        await _handleGoogleSignIn(context);
                      },
                    ),
                    ElevatedButton(
                      child: Text('Google紐付け'),
                      onPressed: () async {
                        await _handleGoogleSignInAndLink(context);
                      },
                    ),
                    SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(labelText: 'email'),
                      onChanged: (val) {
                        _email = val;
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'pass'),
                      onChanged: (val) {
                        _pass = val;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          child: Text('サインアップ'),
                          onPressed: () async {
                            await _emailSignUp(context);
                          },
                          style: ElevatedButton.styleFrom(primary: Colors.red),
                        ),
                        ElevatedButton(
                          child: Text('ログイン'),
                          onPressed: () async {
                            await _emailLogin(context);
                          },
                          style: ElevatedButton.styleFrom(primary: Colors.red),
                        ),
                        ElevatedButton(
                          child: Text('メール紐付け'),
                          onPressed: () async {
                            await _handleEmailSignInAndLink(context);
                          },
                          style: ElevatedButton.styleFrom(primary: Colors.red),
                        ),
                      ],
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
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      child: Text('サインアウト'),
                      onPressed: () async {
                        await _handleSignOut(context);
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.pink),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      child: Text('Googleのリンク解除'),
                      onPressed: () async {
                        await _unlinkGoogle(context);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                        onPrimary: Colors.white,
                      ),
                    ),
                    ElevatedButton(
                      child: Text('メールのリンク解除'),
                      onPressed: () async {
                        await _unlinkMail(context);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                        onPrimary: Colors.white,
                      ),
                    ),
                  ],
                ),
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

  Future<void> _handleGoogleSignInAndLink(BuildContext context) async {
    if (_auth.currentUser == null) {
      final snackBar = SnackBar(content: Text('ログインしてからにしてくれい'));
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
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final snackBar = SnackBar(content: Text('エラー：すでに紐づいているとのこと'));
        await _googleSignIn.signOut();
        Scaffold.of(context).showSnackBar(snackBar);
      } else {
        final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
        Scaffold.of(context).showSnackBar(snackBar);
      }
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

  Future<void> _unlinkGoogle(BuildContext context) async {
    if (_auth.currentUser == null) {
      final snackBar = SnackBar(content: Text('認証情報がないぜぇ？'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }
    try {
      final providerData = _auth.currentUser.providerData;
      for (UserInfo userInfo in providerData) {
        if (userInfo.providerId == 'google.com') {
          _auth.currentUser.unlink(userInfo.providerId);
          await _googleSignIn.signOut();
          final snackBar = SnackBar(content: Text('Googleのunlink完了だぜぇ？'));
          Scaffold.of(context).showSnackBar(snackBar);
        }
      }
    } on Exception catch (e) {
      final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
      Scaffold.of(context).showSnackBar(snackBar);
      print(e);
    }
  }

  Future<void> _unlinkMail(BuildContext context) async {
    if (_auth.currentUser == null) {
      final snackBar = SnackBar(content: Text('認証情報がないぜぇ？'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }
    try {
      final providerData = _auth.currentUser.providerData;
      for (UserInfo userInfo in providerData) {
        if (userInfo.providerId == 'password') {
          _auth.currentUser.unlink(userInfo.providerId);
          final snackBar = SnackBar(content: Text('mailのunlink完了だぜぇ？'));
          Scaffold.of(context).showSnackBar(snackBar);
        }
      }
    } on Exception catch (e) {
      final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
      Scaffold.of(context).showSnackBar(snackBar);
      print(e);
    }
  }

  Future<void> _emailSignUp(BuildContext context) async {
    if (_email == null && _pass == null && _pass.length > 5) {
      final snackBar = SnackBar(content: Text('ちゃんと入力して！'));
      Scaffold.of(context).showSnackBar(snackBar);
    }
    try {
      await _auth.createUserWithEmailAndPassword(
          email: _email, password: _pass);
    } on Exception catch (e) {
      final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
      Scaffold.of(context).showSnackBar(snackBar);
      print(e);
    }
  }

  Future<void> _emailLogin(BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(email: _email, password: _pass);
    } on Exception catch (e) {
      final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
      Scaffold.of(context).showSnackBar(snackBar);
      print(e);
    }
  }

  Future<void> _handleEmailSignInAndLink(BuildContext context) async {
    if (_auth.currentUser == null) {
      final snackBar = SnackBar(content: Text('ログインしてからにしてくれい'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }

    try {
      final AuthCredential credential =
          EmailAuthProvider.credential(email: _email, password: _pass);
      await _auth.currentUser.linkWithCredential(credential);
      final snackBar = SnackBar(content: Text('リンク完了したかもだぜぇ？'));
      Scaffold.of(context).showSnackBar(snackBar);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        final snackBar = SnackBar(content: Text('エラー：すでに紐づいているとのこと'));
        Scaffold.of(context).showSnackBar(snackBar);
      } else {
        final snackBar = SnackBar(content: Text('おっと失敗したようだ'));
        Scaffold.of(context).showSnackBar(snackBar);
      }
      print(e);
    }
  }

  Future<void> _sendEmailVerification() async {
    if (_auth.currentUser == null) {
      final snackBar = SnackBar(content: Text('ログインしてからにしてくれい'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }
    final providerData = _auth.currentUser.providerData;
    final providers = providerData.map((e) => e.providerId);
    if (!providers.contains('password')) {
      final snackBar = SnackBar(content: Text('メール認証がまだ終わってないぞ'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }

    if (_auth.currentUser.emailVerified) {
      final snackBar = SnackBar(content: Text('すでに確認済です'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }

    await _auth.currentUser.sendEmailVerification();
  }
}
