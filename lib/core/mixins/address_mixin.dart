import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

mixin AddressMixin<T extends StatefulWidget> on State<T> {
  final cepController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> cities = [];
  String? selectedState;
  String? selectedCity;

  final phoneFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text.replaceAll(RegExp(r'\D'), '');
      String newText = '';
      for (int i = 0; i < text.length; i++) {
        if (i == 0) newText += '(';
        if (i == 2) newText += ') ';
        if (i == 7) newText += '-';
        newText += text[i];
      }
      return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
    });

  // CEP Mask
  final cepFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 5) newText += '-';
      newText += text[i];
    }
    return newText.length > 9 ? oldValue : TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  });

  Future<void> fetchStates() async {
    final response = await http.get(Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome'));
    if (response.statusCode == 200) {
      setState(() => states = List<Map<String, dynamic>>.from(json.decode(response.body)));
    }
  }

  Future<void> fetchCities(String uf) async {
    final response = await http.get(Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$uf/municipios'));
    if (response.statusCode == 200) {
      setState(() => cities = List<Map<String, dynamic>>.from(json.decode(response.body)));
    }
  }

  Future<void> fetchAddressByCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) return;

    final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['erro'] == true) return;
      
      await fetchCities(data['uf']);
      setState(() {
        selectedState = data['uf'];
        selectedCity = data['localidade'];
        cepController.text = cep;
      });
    }
  }
}