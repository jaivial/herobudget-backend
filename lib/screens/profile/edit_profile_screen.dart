import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../../services/signin_service.dart';
import '../../utils/extensions.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  late TextEditingController _nameController;
  late TextEditingController _givenNameController;
  late TextEditingController _familyNameController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  // Estado
  bool _isLoading = false;
  bool _isPasswordLoading = false;
  String? _errorMessage;
  String? _passwordErrorMessage;
  File? _imageFile;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Inicializar controladores con los valores actuales
    _nameController = TextEditingController(text: widget.user.name);
    _givenNameController = TextEditingController(
      text: widget.user.givenName ?? '',
    );
    _familyNameController = TextEditingController(
      text: widget.user.familyName ?? '',
    );
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _givenNameController.dispose();
    _familyNameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Método para seleccionar una imagen de la galería o la cámara
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // Convertir la imagen a base64
        _base64Image = await ProfileService.imageFileToBase64(_imageFile!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  // Método para mostrar el BottomSheet de selección de imagen
  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    context.tr.translate('select_image_source'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(context.tr.translate('gallery')),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(context.tr.translate('camera')),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Método para mostrar el diálogo de selección de imagen
  void _showImageSourceDialog() {
    _showImageSourceBottomSheet();
  }

  // Método para guardar los cambios del perfil
  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificamos si hay una nueva imagen seleccionada
      String? imageBase64ToSend;
      if (_imageFile != null && _base64Image != null) {
        // Asegurarse de que la imagen en base64 sea válida
        imageBase64ToSend = _base64Image;
        print(
          'Enviando nueva imagen de perfil (longitud base64): ${imageBase64ToSend!.length}',
        );
      } else {
        print('No hay nueva imagen para enviar');
      }

      // Llamar al servicio para actualizar el perfil
      final updatedUser = await ProfileService.updateProfile(
        userId: int.parse(widget.user.id),
        name: _nameController.text.trim(),
        givenName: _givenNameController.text.trim(),
        familyName: _familyNameController.text.trim(),
        profileImageBase64: imageBase64ToSend,
      );

      if (mounted) {
        // Asegurarnos de que la imagen actualizada esté en el modelo de usuario
        UserModel finalUserToReturn = updatedUser;

        // Si tenemos una nueva imagen pero no está en el modelo actualizado, la añadimos manualmente
        if (_imageFile != null &&
            _base64Image != null &&
            (updatedUser.displayImage == null ||
                updatedUser.displayImage!.isEmpty)) {
          print('Aplicando manualmente la imagen al modelo de usuario');
          // Crear una copia del usuario con la imagen actualizada
          finalUserToReturn = updatedUser.copyWith(displayImage: _base64Image);
        }

        // Sincronizar los datos del usuario en el almacenamiento local
        await ProfileService.syncUserLocalData(finalUserToReturn);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.translate('profile_updated_successfully')),
          ),
        );
        // Volver a la pantalla anterior con el usuario actualizado
        Navigator.of(context).pop(finalUserToReturn);
      }
    } catch (e) {
      print('Error al actualizar perfil: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Método para actualizar la contraseña
  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordErrorMessage = context.tr.translate('passwords_do_not_match');
      });
      return;
    }

    setState(() {
      _isPasswordLoading = true;
      _passwordErrorMessage = null;
    });

    try {
      await ProfileService.updatePassword(
        userId: int.parse(widget.user.id),
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        // Actualizar el modelo de usuario con la nueva contraseña
        final updatedUser = widget.user.copyWith(
          password: _newPasswordController.text,
          updatedAt: DateTime.now(),
        );

        // Sincronizar la información actualizada en el almacenamiento local
        await ProfileService.syncUserLocalData(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.translate('password_updated_successfully'),
            ),
          ),
        );

        // Limpiar los campos
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      setState(() {
        _passwordErrorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPasswordLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.translate('edit_profile')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr.translate('profile_info')),
            Tab(text: context.tr.translate('password')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de información de perfil
          _buildProfileInfoTab(),

          // Pestaña de cambio de contraseña
          _buildPasswordTab(),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar con botón para cambiar imagen
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    backgroundImage: _getProfileImage(),
                    child: _getAvatarChild(),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Campos de texto para la información del perfil
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.tr.translate('full_name'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr.translate('name_required');
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _givenNameController,
              decoration: InputDecoration(
                labelText: context.tr.translate('given_name'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _familyNameController,
              decoration: InputDecoration(
                labelText: context.tr.translate('family_name'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.family_restroom),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 24),

            // Botón para guardar cambios
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfileChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(context.tr.translate('save_changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.translate('change_password'),
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.tr.translate('current_password'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr.translate('current_password_required');
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.tr.translate('new_password'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr.translate('new_password_required');
                }
                if (value.length < 6) {
                  return context.tr.translate('password_too_short');
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.tr.translate('confirm_password'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr.translate('confirm_password_required');
                }
                if (value != _newPasswordController.text) {
                  return context.tr.translate('passwords_do_not_match');
                }
                return null;
              },
            ),

            if (_passwordErrorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _passwordErrorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 24),

            // Botón para actualizar contraseña
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPasswordLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isPasswordLoading
                        ? const CircularProgressIndicator()
                        : Text(context.tr.translate('update_password')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para obtener la imagen de perfil
  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      print('EditProfileScreen: Mostrando imagen desde archivo');
      return FileImage(_imageFile!);
    }

    print('EditProfileScreen: Mostrando imagen desde modelo de usuario');
    return widget.user.getProfileImage();
  }

  // Método para obtener el contenido del avatar si no hay imagen
  Widget? _getAvatarChild() {
    if (_imageFile != null) {
      return null;
    }

    if (widget.user.displayImage == null && widget.user.picture == null) {
      return Icon(
        Icons.person,
        size: 60,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return null;
  }
}
