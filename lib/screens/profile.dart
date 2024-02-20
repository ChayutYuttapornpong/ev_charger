import 'dart:typed_data';

import 'package:ev_charger/main.dart';
import 'package:ev_charger/provider/sign_in_provider.dart';
import 'package:ev_charger/utils/next_Screen.dart';
import 'package:ev_charger/utils/upload_image.dart';
import 'package:ev_charger/widgetd/custombutton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'Signin.dart';

class profile extends StatefulWidget {
  const profile({super.key});
  @override
  State<profile> createState() => _profileState();
}

class _profileState extends State<profile> {
  Future getData() async {
    final sp = context.read<SignInProvide>();
    sp.getDataFromSharedPreferences();
  }

  final TextEditingController _emailcontroller = TextEditingController();
  Future passwordReset() async {
    {
      try {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: _emailcontroller.text.trim());
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text('Password reset link sent! check your email'),
            );
          },
        );
      } on FirebaseAuthException catch (e) {
        print(e);
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(e.message.toString()),
            );
          },
        );
      }
    }
  }

  /*Future uploadImage() async {
    if (_image != null) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        String uid = user?.uid ?? '';
        Reference storageReference = FirebaseStorage.instance.ref().child('profile_images/$uid');
        await storageReference.putFile(_image!);
        print('Image uploaded successfully.');
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }*/

  void saveprofile() async {
    String resp = await SignInProvide().saveData(file: _image!);
  }

  Uint8List? _image;

  void selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SignInProvide>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textmain3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
            child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Stack(
                children: [
                  /* CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage("${sp.imageUrl}"),
                    radius: 64,
                  ),*/

                  /* CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.white,
                      backgroundImage: sp.imageUrl.isNotEmpty
                          ? NetworkImage("${sp.imageUrl}")
                          : NetworkImage(
                              "https://cdn.pixabay.com/photo/2016/08/08/09/17/avatar-1577909_640.png")),*/
                  sp.imageUrl != null
                      ? CircleAvatar(
                          radius: 64,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage("${sp.imageUrl}"))
                      : const CircleAvatar(
                          radius: 64,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage("images/profile_img.jpg"),
                        ),
                  /* Positioned(
                    child: IconButton(
                      onPressed: () {
                        selectImage();
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Save Upload Image'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('ยกเลิก'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      saveprofile();
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('ยืนยัน'),
                                  ),
                                ],
                              );
                            });
                      },
                      icon: Icon(
                        Icons.add_a_photo,
                        //color: buttoncolors,
                      ),
                    ),
                    bottom: -10,
                    left: 80,
                  ),*/
                ],
              ),
              Container(
                width: MediaQuery.of(context).size.width,
              ),
              const SizedBox(
                height: 30,
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Persinal Information',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: textmain,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      padding: EdgeInsets.all(5),
                      height: 70,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFFF7F0F0)),
                      child: ListTile(
                        leading: const Icon(
                          Icons.person_outlined,
                          color: buttoncolors,
                        ),
                        title: const Text('Username'),
                        trailing: Text(
                          '${sp.name}',
                          style: TextStyle(color: buttoncolors),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(5),
                      height: 70,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFFF7F0F0)),
                      child: ListTile(
                        leading: const Icon(
                          Icons.email_outlined,
                          color: buttoncolors,
                        ),
                        title: const Text(
                          'Email',
                        ),
                        trailing: Text(
                          '${sp.email}',
                          style: TextStyle(color: buttoncolors, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Security',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: textmain,
                            fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: EdgeInsets.all(5),
                      height: 70,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFFF7F0F0)),
                      child: ListTile(
                          leading: Icon(
                            Icons.lock_outline,
                            color: buttoncolors,
                          ),
                          title: Text('Reset Password'),
                          trailing: IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Reset Password'),
                                    content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            controller: _emailcontroller,
                                            autofillHints: [
                                              AutofillHints.email
                                            ],
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            cursorColor: buttoncolors,
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.5,
                                                color: Text1),
                                            decoration: const InputDecoration(
                                              label: Text("Enter your email"),
                                              labelStyle: TextStyle(
                                                fontSize: 14,
                                                color: textmain2,
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: 1,
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: buttoncolors,
                                                ),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: buttoncolors,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text(
                                          'ยกเลิก',
                                          style: TextStyle(color: textmain),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  buttoncolors),
                                        ),
                                        onPressed: () {
                                          passwordReset();
                                          _emailcontroller.clear();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('ยืนยัน'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.chevron_right_outlined),
                          )),
                    ),
                    SizedBox(height: 50),
                    CustomButton(
                        text: "LogOut",
                        onPressed: () {
                          sp.userSignout();
                          nextScreenReplace(context, const sign_in());
                        })
                  ],
                ),
              )
            ],
          ),
        )),
      ),
    );
  }

  Widget textfilewidget({
    required IconData leading,
    required String title,
    required String trailing,
  }) =>
      ListTile(
        shape: RoundedRectangleBorder(
            side: BorderSide(width: 2, color: Colors.lightBlue),
            borderRadius: BorderRadius.circular(20)),
        leading: Icon(leading),
        title: Text(title),
        trailing: Text(trailing),
      );
}
