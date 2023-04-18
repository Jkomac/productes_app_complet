// ignore_for_file: unnecessary_this

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'package:http/http.dart' as http;

class ProductsService extends ChangeNotifier{
  final String _baseUrl = "flutter-app-productes-a855d-default-rtdb.europe-west1.firebasedatabase.app";
  final List<Product> products = [];
  late Product selectedProduct;
  File? newPicture;

  bool isLoading = true;
  bool isSaving = false;

  ProductsService(){
    this.loadProduct();
  }

  Future loadProduct() async{
    isLoading = true;
    notifyListeners();
    final url = Uri.https(_baseUrl, 'products.json'); // URL + EndPoint
    final resp = await http.get(url);

    final Map<String, dynamic> productsMap = json.decode(resp.body);
    
    productsMap.forEach((key, value) {
      final tempProduct = Product.fromMap(value);
      tempProduct.id = key;
      products.add(tempProduct);
    });

    isLoading = false;
    notifyListeners();
  }

  // Metodo para crear o actualizar un producto
  Future saveOrCreateProduct(Product product) async{
    isSaving = true;
    notifyListeners();

    if (product.id == null){ // Creacion de un producto
      await createProduct(product);
    } else { // Actualizacion de un producto
      await updateProduct(product);
    }

    isSaving = false;
    notifyListeners();
  }

  // Metodo para actualizar un producto en el servidor de FireBase y en la lista local
  Future<String> updateProduct(Product product) async{
    final url = Uri.https(_baseUrl, 'products/${product.id}.json'); // URL + EndPoint
    final resp = await http.put(url, body: product.toJson());
    final decodedData = resp.body;
    print(decodedData);

    // Actualizar la lista local de productos
    final index = this.products.indexWhere((element) => element.id == product.id);
    this.products[index] = product;

    return product.id!;
  }

  // Metodo para crear un producto en el servidor de FireBase y en la lista local
  Future<String> createProduct(Product product) async{
    final url = Uri.https(_baseUrl, 'products.json');
    final resp = await http.post(url, body: product.toJson());
    final decodedData = json.decode(resp.body);
    product.id = decodedData['name'];
    
    // Incorporar el nuevo producto a la lista local
    this.products.add(product);

    return product.id!;
  }

  // Metodo para subir una imagen
  void updateSelectedImage(String path){
    this.newPicture = File.fromUri(Uri(path: path));
    this.selectedProduct.picture = path;
    notifyListeners();
  }

  // Metodo para guardar la imagen en el servidor
  Future<String?> uploadImage() async{
    if (this.newPicture == null) return null;

    this.isSaving = true;
    notifyListeners();

    final url = Uri.parse('https://api.cloudinary.com/v1_1/drbjmydhs/image/upload?upload_preset=d9ogiwxl');
    final imageUploadRequest = http.MultipartRequest('POST', url);
    final file = await http.MultipartFile.fromPath('file', newPicture!.path);

    imageUploadRequest.files.add(file);

    final streamResponse = await imageUploadRequest.send();

    final resp = await http.Response.fromStream(streamResponse);

    // Comporobar si esta creado
    if (resp.statusCode != 200 && resp.statusCode != 201){
      print('Hi ha un error!');
      print(resp.body);
      return null;
    }

    this.newPicture = null;
    final decodeData = json.decode(resp.body);
    return decodeData['secure_url'];

    print(resp.body);
  }
}