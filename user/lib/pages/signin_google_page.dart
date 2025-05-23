import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: 'YOUR_CLIENT_ID_HERE', // kalau Flutter Web
    scopes: ['email', 'profile'],
  );

  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print('Sign in error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _currentUser == null
            ? ElevatedButton(
                onPressed: _handleSignIn,
                child: Text('Sign in with Google'),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Signed in as ${_currentUser!.displayName}'),
                  ElevatedButton(
                    onPressed: () async {
                      await _googleSignIn.signOut();
                      setState(() {
                        _currentUser = null;
                      });
                    },
                    child: Text('Sign out'),
                  ),
                ],
              ),
      ),
    );
  }
}
