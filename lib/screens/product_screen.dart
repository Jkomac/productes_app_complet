// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:productes_app/providers/product_form_provider.dart';
import 'package:productes_app/widgets/widgets.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../ui/input_decorations.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductsService>(context);

    return ChangeNotifierProvider(
      create: (_) => ProductFormProvider(productService.selectedProduct),
      child: _ProductScreenBody(productService: productService),
    );
  }
}

class _ProductScreenBody extends StatelessWidget {
  const _ProductScreenBody({
    Key? key,
    required this.productService,
  }) : super(key: key);

  final ProductsService productService;

  @override
  Widget build(BuildContext context) {
    final productForm = Provider.of<ProductFormProvider>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                ProductImage(url: productService.selectedProduct.picture),
                Positioned(
                  top: 60,
                  left: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 20,
                  child: IconButton(
                    onPressed: () async {
                      // Implementar funcionalitat de cercar imatge de la galeria
                      final ImagePicker picker = ImagePicker();
                      // Pick an image.
                      //final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      // Capture a photo.
                      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                      //print(photo!.path);
                      productService.updateSelectedImage(photo!.path);

                    },
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            _ProductForm(),
            SizedBox(
              height: 100,
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
          child: productService.isSaving
            ? CircularProgressIndicator(color: Colors.white) // Mientras se guarda, el icono cambia
            : Icon(Icons.save_outlined),
          onPressed: productService.isSaving
              ? null // Mientras esta guardando, inhabilita el boton
              : () async {
                  // Guardar un producto
                  if (!productForm.isValidForm()) return;
                  final String? imageUrl = await productService.uploadImage();
                  //print(imageUrl);
                  if (imageUrl != null) {
                    productForm.tempProduct.picture = imageUrl;
                  }
                  productService.saveOrCreateProduct(productForm.tempProduct);
                }),
    );
  }
}

class _ProductForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productForm = Provider.of<ProductFormProvider>(context);
    final tempProduct = productForm.tempProduct;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        decoration: _buildBoxDecoration(),
        child: Form(
          key: productForm.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, // Validar el formulario despues de la interaccion del usuario
          child: Column(
            children: [
              SizedBox(height: 10),
              TextFormField(
                initialValue: tempProduct.name,
                onChanged: (value) => tempProduct.name = value,
                validator: (value) {
                  if (value == null || value.length < 1) return "El nombre es obligatorio";
                },
                decoration: InputDecorations.authInputDecoration(
                    hintText: 'Nom del producte', labelText: 'Nom:'),
              ),
              SizedBox(height: 30),
              TextFormField(
                initialValue: '${tempProduct.price}',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')) // RegExp para solo poner 2 decimales
                ],
                onChanged: (value) {
                  if (double.tryParse(value) == null){ // Si no se puede convertir en nulo, establecer el precio de 0€
                    tempProduct.price = 0;
                  } else{
                    tempProduct.price = double.parse(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.length < 1) return "El precio es obligatorio";
                },
                keyboardType: TextInputType.number,
                decoration: InputDecorations.authInputDecoration(
                    hintText: '99€', labelText: 'Preu:'),
              ),
              SizedBox(height: 30),
              SwitchListTile.adaptive(
                value: tempProduct.available,
                title: Text('Disponible'),
                activeColor: Colors.indigo,
                onChanged: productForm.updateAvailability // Sin (value) ya que se puede cuando solo se usa un parametro
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBoxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(25),
          bottomLeft: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: Offset(0, 5),
              blurRadius: 5),
        ],
      );
}
