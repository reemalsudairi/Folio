// ignore_for_file: prefer_const_constructors

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:folio/screens/homePage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';




void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  GlobalKey<FormState> formstate=GlobalKey();
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFF8F8F3),
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 36),

                // Back icon
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      print("on pressed");
                    },
                    iconSize: 50,
                    icon: Icon(Icons.arrow_back_ios),
                  ),
                ),

                

                //profile photo with pwncil icon
                ProfilePhotoWidget(),
                
                SizedBox(height: 20),

                // Form fields

Container(
  width: 410,
  padding: EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Color(0xFFFFFFFF),
    borderRadius: BorderRadius.circular(40),
  ),
  child: SingleChildScrollView( // Add SingleChildScrollView here
    child: ConstrainedBox( // Wrap the content in ConstrainedBox
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height , // Adjust the height to be scrollable based on screen size
      ),
      child:Form(
        key: formstate, 
      child: Column(
        children: [
          SizedBox(height: 40),

          // Name
          TextFormField(
            keyboardType: TextInputType.name,
            maxLength: 50,// i don't know why 50...
            enabled: true,
            decoration: InputDecoration(
              hintText: "Name",
              hintStyle: TextStyle(
                color: Color(0xFF9B9B9B),
                fontWeight: FontWeight.w400,
                fontSize: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF790AD)),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          SizedBox(height: 40),

          // Bio
          TextFormField(
            keyboardType: TextInputType.text,
            maxLines: 4,
            maxLength: 152,
            
            enabled: true,
            decoration: InputDecoration(
              
              hintText: "Bio",
              hintStyle: TextStyle(
                color: Color(0xFF9B9B9B),
                fontWeight: FontWeight.w400,
                fontSize: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF790AD)),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          SizedBox(height: 40),

          // Books number
          TextFormField(
            keyboardType: TextInputType.number,
            enabled: true,
            decoration: InputDecoration(
              hintText: "How many books do you want to read in 2024?",
              hintStyle: TextStyle(
                color: Color(0xFF9B9B9B),
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Color(0xFFF790AD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF790AD)),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          SizedBox(height: 20),

          
          

          SizedBox(height: 20),

          // Save button
         Container(
            width: 410,  // Match the width of the TextField
            child: MaterialButton(
              color: Color(0xFFF790AD),
              textColor: Color(0xFFFFFFFF),
              height: 50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              onPressed: () {
                print("Navigate to profile setup");
              },
              child: Text("Save",style: TextStyle(fontWeight: FontWeight.bold )),),
            ),
    
  
  

          SizedBox(height: 20),

          //Skip profil set uo for now?
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Skip profil set up for now? ",
                  style: TextStyle(fontFamily: 'Roboto',color: Color(0XFF695555),fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: "Skip",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFFF790AD),
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Navigate to login page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(),
                        ),
                      );
                    },
                ),
              ],
            ),
          ),
          SizedBox(height: 20), // Additional space after the text
        ],
      ),),
    ),
  ),
      ),
              ]
              )
              )
              )
              )
              );
              }
              }
              class ProfilePhotoWidget extends StatefulWidget {
  @override
  _ProfilePhotoWidgetState createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Function to pick image from gallery or camera
  Future<void> _showImagePickerOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        onClosing: () {},
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Take a Photo'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop(); // Close the bottom sheet
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop(); // Close the bottom sheet
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to pick an image
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile photo (CircleAvatar)
        CircleAvatar(
          radius: 64,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : NetworkImage(
                      "https://i.pinimg.com/564x/c5/07/8e/c5078ec7b5679976947d90e4a19e1bbb.jpg")
                  as ImageProvider,
        ),

        // Pencil icon for editing
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              _showImagePickerOptions(context); // Show the option to pick image
            },
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Color(0xFFF790AD),
              ),
              child: Icon(Icons.edit, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
