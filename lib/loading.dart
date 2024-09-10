import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF89B2CC), // Replace with your desired color
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo-talan.png', // Replace with your logo asset path
              width: 300,
              height: 300,
            ),
            const SizedBox(
                height:
                20), // Add some space between the logo and the loading animation
            LoadingAnimationWidget.staggeredDotsWave(
              color: const Color(0xDFFFF9DF),
              size: 80,
            ),
          ],
        ),
      ),
    );
  }
}
