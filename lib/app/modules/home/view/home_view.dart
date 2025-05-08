import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:machineteest/app/modules/home/controllers/home_controller.dart';
import 'package:machineteest/data/models/user_model.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Getting screen size
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profiles'),
        backgroundColor:
            Colors.transparent, // Transparent app bar to show gradient
        elevation: 0, // Removes the default shadow from app bar
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshData,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            _buildLocationHeader(controller),
            Expanded(child: _buildUserList(controller, context, screenWidth)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(
    HomeController controller,
    BuildContext context,
    double screenWidth,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: SpinKitFadingCircle(
            color: Get.theme.colorScheme.primary,
            size: 40.0,
          ),
        );
      }

      if (controller.hasError.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading users', style: Get.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage.value,
                style: Get.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.fetchUsers,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (controller.users.isEmpty) {
        return const Center(child: Text('No users found'));
      }

      return RefreshIndicator(
        onRefresh: controller.fetchUsers,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: screenWidth > 600 ? 32 : 16,
          ), // More padding for larger screens
          itemCount: controller.users.length,
          itemBuilder: (context, index) {
            final user = controller.users[index];
            return _buildUserCard(user, context, controller, screenWidth);
          },
        ),
      );
    });
  }

  Widget _buildUserCard(
    UserModel user,
    BuildContext context,
    HomeController controller,
    double screenWidth,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 32 : 16,
        vertical: 8,
      ), // More spacing for larger screens
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUserAvatar(user, context, controller),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: Get.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(user.email, style: Get.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'User ID: ${user.id}',
                    style: Get.textTheme.bodyMedium!.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(
    UserModel user,
    BuildContext context,
    HomeController controller,
  ) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: SizedBox(
            width: 80,
            height: 80,
            child:
                user.hasLocalImage
                    ? Image.file(File(user.localImagePath!), fit: BoxFit.cover)
                    : CachedNetworkImage(
                      imageUrl: user.avatar,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) =>
                              const Center(child: Icon(Icons.error)),
                    ),
          ),
        ),
        GestureDetector(
          onTap: () => controller.showImageSourceDialog(context, user.id),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHeader(HomeController controller) {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child:
            controller.isLocationLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.hasLocationError
                ? const Center(child: Text('Location unavailable'))
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.locationString,
                      style: Get.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Address: ${controller.addressString}',
                      style: Get.textTheme.bodyMedium,
                    ),
                  ],
                ),
      );
    });
  }
}
