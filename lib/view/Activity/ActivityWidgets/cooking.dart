import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';

class Cooking extends StatefulWidget {
  final int userAge;
  const Cooking({super.key, required this.userAge});

  @override
  State<Cooking> createState() => _CookingState();
}

// https://thenutritionjunky.com/50-adhd-friendly-recipes/
class _CookingState extends State<Cooking> {
  final List recipes = [
    {
      "name": "Berry Fertility Smoothie",
      "description":
          "A fruity & creamy smoothie blend that packs a nutrition punch to optimize focus and energy.",
      "image": "assets/images/berry_smoothie.jpg",
      "ingredients": [
        "1 cup almond milk (unsweetened)",
        "¼ cup frozen cauliflower",
        "1 cup frozen berries",
        "½ banana",
        "¼ avocado",
        "1 tbsp chia seeds",
        "1 tbsp monkfruit sweetener",
        "1 oz collagen peptides",
        "1 tsp vanilla extract",
      ],
      "instructions": [
        "Place all ingredients into a blender.",
        "Blend until smooth and creamy.",
        "Pour into a glass and enjoy!",
      ],
    },
    {
      "name": "Cookie Energy Balls",
      "description":
          "These no-bake oat balls are packed with protein and simple ingredients. Great for a healthy snack or dessert.",
      "image": "assets/images/energy_balls.jpg",
      "ingredients": [
        "1 cup gluten-free rolled oats",
        "2/3 cup unsweetened toasted coconut flakes",
        "1 tsp cinnamon",
        "Pinch of salt",
        "1/2 cup creamy peanut butter",
        "1 tsp vanilla",
        "1/4 cup chocolate chips or raisins",
      ],
      "instructions": [
        "Mix oats, coconut, cinnamon, and salt in a large bowl.",
        "Stir in peanut butter, vanilla, and then add chocolate chips or raisins.",
        "If the dough is crumbly, add 1–3 tsp of warm water.",
        "Cover and refrigerate for 20 minutes.",
        "Roll into balls (about 2 tbsp each) and enjoy!",
      ],
    },
    {
      "name": "Healthy Banana Ice Cream",
      "description":
          "A two-ingredient base ice cream with multiple flavor options — creamy, dairy-free, and delicious!",
      "image": "assets/images/banana_icecream.jpg",
      "ingredients": [
        "Frozen bananas",
        "Dairy-free milk (almond or coconut)",
        "Vanilla extract",
        "Pinch of salt",
        "Optional: strawberry, peanut butter, or chocolate flavor",
      ],
      "instructions": [
        "Place all ingredients in a high-speed blender or food processor.",
        "Blend until smooth and airy (soft-serve texture).",
        "Transfer to a freezer-safe container and freeze for at least 4 hours.",
        "Let it soften for 10–15 minutes before serving.",
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userAge >= 7 && widget.userAge <= 13) {
        _showCaregiverAlert();
      }
    });
  }

  void _showCaregiverAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Notice",
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontFamily: 'K2D',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Since your age is between 7 and 13, it's best to call a caregiver for guidance.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: BSizes.fontSizeMd,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final randomRecipe = recipes[Random().nextInt(recipes.length)];

    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: Column(
        children: [
          BAppBarTheme.createHeader(
            context: context,
            title: 'Cooking',
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Stack(
              children: [
                // الدائرة الخلفية
                Positioned(
                  bottom: -60,
                  right: -60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: BColors.primary.withOpacity(0.4),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(180),
                      ),
                    ),
                  ),
                ),
                // البوكس الأبيض
                Positioned(
                  top: 5,
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 25,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الاسم والصورة
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      randomRecipe["name"],
                                      style: const TextStyle(
                                        fontFamily: 'K2D',
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: BColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              CircleAvatar(
                                radius: size.width * 0.18,
                                backgroundImage: AssetImage(
                                  randomRecipe["image"],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Text(
                            randomRecipe["description"],
                            style: const TextStyle(
                              fontFamily: 'K2D',
                              fontSize: BSizes.fontSizeMd,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Ingredients
                          Text(
                            "Ingredients:",
                            style: const TextStyle(
                              fontFamily: 'K2D',
                              fontSize: BSizes.fontSizeLg,
                              fontWeight: FontWeight.w700,
                              color: BColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(
                            (randomRecipe["ingredients"] as List).length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "• ",
                                    style: TextStyle(
                                      fontSize: BSizes.fontSizeMd,
                                      fontFamily: 'K2D',
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      randomRecipe["ingredients"][index],
                                      style: const TextStyle(
                                        fontSize: BSizes.fontSizeMd,
                                        fontFamily: 'K2D',
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Instructions
                          Text(
                            "Instructions:",
                            style: const TextStyle(
                              fontFamily: 'K2D',
                              fontSize: BSizes.fontSizeLg,
                              fontWeight: FontWeight.w700,
                              color: BColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(
                            (randomRecipe["instructions"] as List).length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${index + 1}. ",
                                    style: const TextStyle(
                                      fontSize: BSizes.fontSizeMd,
                                      fontFamily: 'K2D',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      randomRecipe["instructions"][index],
                                      style: const TextStyle(
                                        fontSize: BSizes.fontSizeMd,
                                        fontFamily: 'K2D',
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
