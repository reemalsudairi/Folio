import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio/screens/homePage.dart';
import 'package:image_picker/image_picker.dart';
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
       'profilePhoto': _imageFile != null
           ? await _uploadProfilePhoto(userId)
           : null,
     };

     // Update the Firestore document
     await _firestore
         .collection('reader')
         .doc(userId)
         .set(userProfile, SetOptions(merge: true));

     // Navigate to HomePage
     Navigator.pushReplacement(
       context,
       MaterialPageRoute(builder: (context) => HomePage(userId: userId,)),
     );
   } catch (e) {
     print('Error saving profile: $e');
     // Optionally, display an error message to the user
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Failed to save profile: $e')),
     );
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
             onImagePicked: (File imageFile) {
               setState(() {
                 _imageFile = imageFile;
               });
             },
           ),
           const SizedBox(height: 20),
           Container(
             width: 410,
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: Color(0xFFF8F8F3),
               borderRadius: BorderRadius.circular(40),
             ),
             child: Form(
               key: _formKey,
               child: Column(
                 children: [
                   const SizedBox(height: 40),
                   // Name
                         TextFormField(
                           controller: _nameController,
                           keyboardType: TextInputType.name,
                           autovalidateMode: AutovalidateMode.onUserInteraction,
                       validator: (value) {
   if (value == null || value.isEmpty) {
     return "*"; // Name is required
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
                              filled: true, // Make sure the field is filled with the color
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
                             errorBorder: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(40),
                             borderSide: const BorderSide(color: Color(0xFFF790AD)),
                             ),
                             focusedErrorBorder: OutlineInputBorder(
     borderRadius: BorderRadius.circular(40),
     borderSide: const BorderSide(color: Color(0xFFF790AD)),
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
                       ), filled: true, // Make sure the field is filled with the color
                              fillColor: Colors.white, 
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(40),
                         borderSide: const BorderSide(color: Color(0xFFF790AD)),
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(40),
                         borderSide: const BorderSide(color: Color(0xFFF790AD)),
                       ),
                       enabledBorder: OutlineInputBorder(
                         borderSide: const BorderSide(color: Color(0xFFF790AD)),
                         borderRadius: BorderRadius.circular(40),
                       ),
                     ),
                   ),
                   const SizedBox(height: 20),
                   // Books number
// Books number input field
TextFormField(
 controller: _booksController,
 keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // This ensures only numbers are allowed
 decoration: InputDecoration(
   hintText: "How many books do you want to read in this year?",
   hintStyle: const TextStyle(
     color: Color(0xFF695555),
     fontWeight: FontWeight.w400,
     fontSize: 15,
   ), filled: true, // Make sure the field is filled with the color
                              fillColor: Colors.white, 
   border: OutlineInputBorder(
     borderRadius: BorderRadius.circular(40),
     borderSide: const BorderSide(color: Color(0xFFF790AD)),
   ),
   focusedBorder: OutlineInputBorder(
     borderRadius: BorderRadius.circular(40),
     borderSide: const BorderSide(color: Color(0xFFF790AD)),
   ),
   enabledBorder: OutlineInputBorder(
     borderSide: const BorderSide(color: Color(0xFFF790AD)),
     borderRadius: BorderRadius.circular(40),
   ),
 ),
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
     style: TextStyle(fontWeight: FontWeight.bold),
   ),
 ),
),


                   const SizedBox(height: 20),
                   // Skip profile setup for now?
RichText(
 text: TextSpan(
   children: [
     const TextSpan(
       text: "Skip profile setup for now? ",
       style: TextStyle(
           fontFamily: 'Roboto',
           color: Color(0XFF695555),
           fontWeight: FontWeight.bold),
     ),
     TextSpan(
       text: "Skip",
       style: const TextStyle(
         fontFamily: 'Roboto',
         color: Color(0xFFF790AD),
         fontWeight: FontWeight.bold,
       ),
       recognizer: TapGestureRecognizer()
         ..onTap = () {
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(
               builder: (context) => const HomePage(userId: '',),
             ),
           );
         },
     ),
   ],
 ),
),
                   const SizedBox(
                       height: 150), // Additional space after the text
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
 final Function(File) onImagePicked;
 const ProfilePhotoWidget({super.key, required this.onImagePicked});
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
   builder: (context) => Padding(
     padding: const EdgeInsets.only(bottom: 50.0), // Add padding for better look
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
         ],
       ),
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
       widget.onImagePicked(_imageFile!);
     });
     widget.onImagePicked(_imageFile!); // Notify parent widget
   }
 }
 @override
 Widget build(BuildContext context) {
   return Stack(
     children: [
       // Profile photo with thin border
CircleAvatar(
 radius: 64,
 backgroundImage: _imageFile != null
     ? FileImage(_imageFile!)
     : const AssetImage("assets/images/profile_pic.png") as ImageProvider,
 backgroundColor: const Color(0xFFF790AD),
 child: Container(
   decoration: BoxDecoration(
     shape: BoxShape.circle,
     border: Border.all(color: const Color(0xFFF790AD), width: 3),
   ),
 ),
),
       // Pencil icon for editing
       Positioned(
         bottom: 0,
         right: 0,
         child: IconButton(
           icon: const Icon(Icons.camera_alt),
           onPressed: () => _showImagePickerOptions(context),
         ),
       ),
     ],
   );
 }
}
