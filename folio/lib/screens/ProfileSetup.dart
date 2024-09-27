// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, curly_braces_in_flow_control_structures, library_private_types_in_public_api
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio/screens/login.dart';
import 'package:image_picker/image_picker.dart';

class CustomTextInputFormatter extends TextInputFormatter {
 @override
 TextEditingValue formatEditUpdate(
     TextEditingValue oldValue, TextEditingValue newValue) {
   if (newValue.text.isEmpty) {
     return newValue;
   }

   int? value = int.tryParse(newValue.text);
   if (value == null || value < 0 || value > 1000) {
     return oldValue;
   }

   return newValue;
 }
}

                    

class ProfileSetup extends StatefulWidget {
 final String userId;
 const ProfileSetup({super.key, required this.userId});
 @override
 _ProfileSetupState createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
 final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
 final TextEditingController _nameController = TextEditingController();
 final TextEditingController _bioController = TextEditingController();
 final TextEditingController _booksController = TextEditingController();
 File? _imageFile;
 final ImagePicker _picker = ImagePicker();
 // Firebase Auth instance
 final _auth = FirebaseAuth.instance;
 // Firestore instance
 final _firestore = FirebaseFirestore.instance;
 // Dispose controllers to prevent memory leaks
 @override
 void dispose() {
   _nameController.dispose();
   _bioController.dispose();
   _booksController.dispose();
   super.dispose();
 }

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
             leading: const Icon(Icons.camera),
             title: const Text('Take a Photo'),
             onTap: () {
               _pickImage(ImageSource.camera);
               Navigator.of(context).pop();
             },
           ),
           ListTile(
             leading: const Icon(Icons.photo_library),
             title: const Text('Choose from Gallery'),
             onTap: () {
               _pickImage(ImageSource.gallery);
               Navigator.of(context).pop();
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
  String? _errorMessage;
void _showConfirmationMessage() {
   showDialog(
     context: context,
     barrierDismissible: true,
     builder: (context) => Dialog(
       backgroundColor: Colors.transparent,
       child: Container(
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
           color: Colors.lightGreen.withOpacity(0.7),
           borderRadius: BorderRadius.circular(30),
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Icon(
               Icons.check,
               color: Colors.white,
               size: 40,
             ),
             const SizedBox(height: 10),
             const Text(
               'Signup Successful!',
               style: TextStyle(
                 color: Colors.white,
                 fontWeight: FontWeight.bold,
                 fontSize: 18,
               ),
               textAlign: TextAlign.center,
             ),
           ],
         ),
       ),
     ),
   );

   // Automatically close the dialog after 2 seconds
   Future.delayed(const Duration(seconds: 1), () {
     Navigator.pop(context);
   });
 }
 void _saveProfile() async {
   if (_formKey.currentState?.validate() ?? false) {
     try {
       final userId = widget.userId; // Use the passed userId

       // Prepare the profile data
       final userProfile = {
         'name': _nameController.text,
         'bio': _bioController.text,
         // Only parse booksController if the field is not empty
         'books': _booksController.text.isNotEmpty
             ? int.tryParse(_booksController.text)
             : null, // If empty, set to null
         'profilePhoto':
             _imageFile != null ? await _uploadProfilePhoto(userId) : null,
       };

       // Update the Firestore document
       await _firestore
           .collection('reader')
           .doc(userId)
           .set(userProfile, SetOptions(merge: true));

            // Show confirmation message on successful login
       _showConfirmationMessage();

       // Wait for the confirmation message dialog to close
       await Future.delayed(const Duration(seconds: 2));

       // Navigate to HomePage
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(
             builder: (context) => LoginPage() ));
       
     } catch (e) {
       print('Error saving profile: $e');
       // display an error message to the user
       updateErrorMessage('Failed to save profile');
       
     }
    
   }
 }

 // Upload profile photo to Firebase Storage
 Future<String?> _uploadProfilePhoto(String userId) async {
   if (_imageFile != null) {
     try {
       final ref = FirebaseStorage.instance
           .ref()
           .child('profile_photos')
           .child('$userId.jpg');
       await ref.putFile(_imageFile!);
       return await ref.getDownloadURL();
     } catch (e) {
       print('Error uploading profile photo: $e');
       return null;
     }
   }
   return null;
 }
void updateErrorMessage(String message) {
 
   WidgetsBinding.instance.addPostFrameCallback((_) {
   setState(() {
     _errorMessage = message;
   });
 });
 
}

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: const Color(0xFFF8F8F3),
     body: SingleChildScrollView(
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.center,
         children: [
           const SizedBox(height: 100),
           // Profile photo with pencil icon
            ProfilePhotoWidget(
 onImagePicked: (File? imageFile) {
   setState(() {
     _imageFile = imageFile; // Handle null when deleting the photo
   });
 }, initialImage: '',
),
const SizedBox(height: 20),
           
           Container(
             width: 410,
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: const Color(0xFFF8F8F3),
               borderRadius: BorderRadius.circular(40),
             ),
             child: Form(
               key: _formKey,
               child: Column(
                 children: [
                   if (_errorMessage != null)
                        Container(
                        width: 350,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                       _errorMessage!,
                        style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                       ),
                     ),
                    ),

                   const SizedBox(height: 20),
                   // Name
                   TextFormField(
                     controller: _nameController,
                     keyboardType: TextInputType.name,
                     autovalidateMode: AutovalidateMode.onUserInteraction,
                   
                     validator: (value) {
                       if (value == null || value.isEmpty) {
                     
                         return "Please enter your Name"; // Name is required
                       }
                       if (value.trim().isEmpty) {
                         return "Name cannot contain only spaces";
                       }
                       if (value.startsWith(' ')) {
                         return "Name cannot start with spaces";
                       }
                       
                       return null; // Input is valid
                     },
                     maxLength: 50, // Set maximum length of name field
                     decoration: InputDecoration(
                       hintText: "Name",

                       hintStyle: const TextStyle(
                         color: Color(0xFF695555),
                         fontWeight: FontWeight.w400,
                         fontSize: 20,
                       ),
                       filled:
                           true, // Make sure the field is filled with the color
                       fillColor: Colors.white,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(40),
                         borderSide:
                             const BorderSide(color: Color(0xFFF790AD)),
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(40),
                         borderSide:
                             const BorderSide(color: Color(0xFFF790AD)),
                       ),
                       enabledBorder: OutlineInputBorder(
                         borderSide:
                             const BorderSide(color: Color(0xFFF790AD)),
                         borderRadius: BorderRadius.circular(40),
                       ),
                        suffixIcon: Padding(
     padding: const EdgeInsets.only(right: 45.0,top: 10.0), // Right padding
     child: RichText(
       text: TextSpan(
         text: '*',
         style: TextStyle(color: Colors.red, fontSize: 20),
       ),
     ),
 ),
                     ),
                   ),

                   const SizedBox(height: 20),
                   
                   // Bio
                   TextFormField(
                     controller: _bioController,
                     keyboardType: TextInputType.text,

                     maxLines: 4,
                     maxLength: 152,
                     decoration: InputDecoration(
                       hintText: "Bio",
                       hintStyle: const TextStyle(
                         color: Color(0xFF695555),
                         fontSize: 20,
                       ),
                       filled:
                           true, // Make sure the field is filled with the color
                       fillColor: Colors.white,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(40),
                         borderSide:
                             const BorderSide(color: Color(0xFFF790AD)),
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(40),
                         borderSide:
                             const BorderSide(color: Color(0xFFF790AD)),
                       ),
                       enabledBorder: OutlineInputBorder(
                         borderSide:
                             const BorderSide(color: Color(0xFFF790AD)),
                         borderRadius: BorderRadius.circular(40),
                       ),
                     ),
                   ),
                   const SizedBox(height: 20),
                   
                  // Books number input field
                   TextFormField(
                     controller: _booksController,
                     keyboardType: TextInputType.number,
                     inputFormatters: [
                       FilteringTextInputFormatter.digitsOnly, CustomTextInputFormatter(),
                     ], 
                     // This ensures only numbers are allowed
                     decoration: InputDecoration(
                       hintText:"Yearly books goal (Max: 1000)",
                       hintStyle: const TextStyle(
                         color: Color(0xFF695555),
                         fontWeight: FontWeight.w400,
                         fontSize: 15,
                       ),
                       filled:
                           true, // Make sure the field is filled with the color
                       fillColor: Colors.white,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(40),
                         borderSide:
                             const BorderSide(color: Color(0xFFF790AD)),
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(40),
                         borderSide:
                             const BorderSide(color: Color(0xFFF790AD)),
                       ),
                       enabledBorder: OutlineInputBorder(
                         borderSide:
                             const BorderSide(color: Color(0xFFF790AD)),
                         borderRadius: BorderRadius.circular(40),
                       ),
                      
                     ),
                     validator: (value) {
                      if (value == null || value.isEmpty) {
                      return null;}
                      final number = int.parse(value); // No need for tryParse since input is restricted to digits only
                      if (number > 1000) {
                      return 'The number of books cannot exceed 1000';}
                      return null; // Input is valid
                       },
                   ),

                   const SizedBox(height: 20),

                   // Save button
                   SizedBox(
                     width: 410, // Match the width of the TextField
                     child: MaterialButton(
                       color: const Color(0xFFF790AD),
                       textColor: const Color(0xFFFFFFFF),
                       height: 50,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(40),
                       ),
                       onPressed: _saveProfile,
                       child: const Text(
                         "Save",
                         style: TextStyle(fontFamily: 'Roboto',
                               fontWeight: FontWeight.w700,
                               fontSize: 20,
                               color: Colors.white,),
                       ),
                     ),
                   ),


                   const SizedBox(height: 150), // Additional space after the text
                 ],
               ),
             ),
           ),
         ],
       ),
     ),
   );
 }
}

class ProfilePhotoWidget extends StatefulWidget {
 final Function(File?) onImagePicked;

 const ProfilePhotoWidget({super.key, required this.onImagePicked, required Object initialImage});

 @override
 _ProfilePhotoWidgetState createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
 File? _imageFile;
 final ImagePicker _picker = ImagePicker();
 late ImageProvider<Object> _currentImage;

 @override
 void initState() {
   super.initState();
   _currentImage = const AssetImage('assets/images/profile_pic.png');
 }

 // Function to show options for picking an image
 Future<void> _showImagePickerOptions(BuildContext context) async {
   // Check if the current image is the default image
   bool isDefaultImage = _imageFile == null;

   showModalBottomSheet(
     context: context,
     builder: (context) => Padding(
       padding: const EdgeInsets.only(bottom: 50.0),
       child: BottomSheet(
         onClosing: () {},
         builder: (context) => Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             ListTile(
               leading: const Icon(Icons.camera),
               title: const Text('Take a Photo'),
               onTap: () {
                 _pickImage(ImageSource.camera);
                 Navigator.of(context).pop();
               },
             ),
             ListTile(
               leading: const Icon(Icons.photo_library),
               title: const Text('Choose from Gallery'),
               onTap: () {
                 _pickImage(ImageSource.gallery);
                 Navigator.of(context).pop();
               },
             ),
             if (!isDefaultImage)
               ListTile(
                 leading: const Icon(Icons.delete),
                 title: const Text('Delete Photo'),
                 onTap: () {
                   _deletePhoto();
                   Navigator.of(context).pop();
                 },
               ),
           ],
         ),
       ),
     ),
   );
 }

 // Function to pick an image from the camera or gallery
 Future<void> _pickImage(ImageSource source) async {
   final pickedFile = await _picker.pickImage(source: source);
   if (pickedFile != null) {
     setState(() {
       _imageFile = File(pickedFile.path);
       _currentImage = FileImage(_imageFile!);
     });
     widget.onImagePicked(_imageFile); // Notify parent widget with the picked image
   }
 }

 // Function to delete the selected photo and revert to the default image
 void _deletePhoto() {
   setState(() {
     _imageFile = null;
     _currentImage = const AssetImage('assets/images/profile_pic.png');
   });
   widget.onImagePicked(null); // Notify parent widget that the photo is deleted
 }

 @override
 Widget build(BuildContext context) {
   return Stack(
     children: [
       // Display profile photo with a border
       CircleAvatar(
         radius: 64,
         backgroundImage: _currentImage,
         backgroundColor: const Color(0xFFF790AD),
       ),
       // Button to edit or change the photo
       Positioned(
         bottom: 0,
         right: 0,
         child: IconButton(
           icon: const Icon(Icons.camera_alt, color: Color.fromARGB(255, 53, 31, 31)),
           onPressed: () => _showImagePickerOptions(context),
         ),
       ),
     ],
   );
 }
}
