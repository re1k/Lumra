import 'package:flutter/material.dart';
import '../../theme/base_themes/colors.dart';
import '../../theme/custom_themes/text_theme.dart';
import '../Homepage/Account/viewProfile.dart';
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      backgroundColor: BColors.light,

      appBar: AppBar(
        title: const Text("Account"),
        centerTitle: true,
        backgroundColor: BColors.light,
          elevation: 0,
          foregroundColor: BColors.texBlack,
      ),
      body: Column(
        
        
             children: [ 
              const SizedBox(height: 20), 

                 //to add profile photo 
               Center(
                  child: CircleAvatar(
                   radius: 100,
                    backgroundImage: AssetImage('assets/images/profile_image.jpeg'),
                      ),
                   ),
               const SizedBox(height: 20), 

               //Name of user 
                  Text(
                   "Latifa Bahafid",
                      style:  BTextTheme.lightTextTheme.headlineMedium,
                   ) ,

                const SizedBox(height: 20), 


                // go to view profile page 
                  _buildOption(
                 icon: Icons.edit,   
                 text: "Profile Information",
                 onTap: () {
                  Navigator.push(
                    context,
                   MaterialPageRoute(builder: (context) => const ViewProfile()),
                      );
                    },
                   ),
          
                const SizedBox(height: 10),  

               // go to view posts page 
                   _buildOption(
                 icon: Icons.article, 
                 text: "Posts",
                 onTap: () {
                  
                   },
                   ),
                   
                const SizedBox(height: 10),  

                 // go to view save posts page 

                  _buildOption(
                 icon: Icons.bookmark,   
                 text: "Saved Posts",
                 onTap: () {
                  
                   },
                   ),
                 
                  const SizedBox(height: 10),

                  // go to generate QR 

                    _buildOption(
                 icon: Icons.qr_code,   
                 text: "Generate QR Code For Caregiver",
                 onTap: () {
                  
                   },
                   ),
                   
                 const SizedBox(height: 30),
                   
                 Padding(
                 padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                      icon: const Icon(Icons.logout),
                       label: const Text("Sign Out"),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: BColors.primary,
                           foregroundColor: BColors.textwhite,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                             textStyle: BTextTheme.lightTextTheme.headlineSmall, // نص الزر
                               ),
                           ),
                       ),
                   ),




                 
          ],
        ),
      );
  }
}

Widget _buildOption({required IconData icon, required String text, VoidCallback? onTap}) {
  return ListTile(
    leading: Icon(icon, color: BColors.iconColor),
    title: Text(text, style:  BTextTheme.lightTextTheme.headlineSmall),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: BColors.iconColor),
    onTap: onTap,
  );
}