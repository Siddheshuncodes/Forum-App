import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forum/models/auth.dart';
import 'package:forum/models/comment.dart';
import 'package:forum/models/post.dart';
import 'package:http/http.dart' as http;

final storage = new FlutterSecureStorage();


class RemoteService {
  final api_url = 'http://13.94.152.122:8080/api/v1/';

  var headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };


  Future<List<Post>?> getPostsPage(int page) async {
    var url = Uri.parse('${api_url}post/page/$page');
    var Token = await storage.readAll().then((value) => value['token']);
    headers.addAll({'Authorization': 'Bearer $Token'});

    var response = await http.get(url,headers: headers);
    if (response.statusCode == 200) {
      var json = response.body;
      return postFromJson(json);
    }
  }

    Future<void> register(String user_name, String password) async {
    var url = Uri.parse('${api_url}auth/register');
    final body = jsonEncode(Auth(userName: user_name, password: password).toJson());

    final response = await http.post(url, body: body, headers: headers);
    if (response.statusCode == 200) {
      print('Registration successful');
      var Token = response.body.substring(10,response.body.length-2);
      print('Token: $Token');
      await storage.write(key: 'token', value: Token);
      var date = DateTime.now().add(Duration(hours: 24));
      await storage.write(key: 'expiration', value: date.toString());
    } else {
      print('Registration failed: ${response.statusCode}');
    }
  }

    Future<LoginResponseModel> getToken(String user_name, String password) async {
      print('getToken called');
      var url = Uri.parse('${api_url}auth/authenticate');
      final body = jsonEncode(Auth(userName: user_name, password: password).toJson());
      headers.remove('Authorization');

      final response = await http.post(url, body: body, headers:headers);
      if (response.statusCode == 200) {
        print('LogIn successful');
        var Token = response.body.substring(10,response.body.length-2);
        print('Token: $Token');
        await storage.write(key: 'token', value: Token);
        var date = DateTime.now().add(Duration(hours: 24));
        await storage.write(key: 'expiration', value: date.toString());
         return LoginResponseModel.fromJson(
          json.decode(response.body),
        );
      } else {
        print('LogIn failed: ${response.statusCode}');
        throw Exception('Failed to load post');
      }
    }

  Future<void> addPost({required String title, required String content}) async {
      var url = Uri.parse('${api_url}post/add');
      var Token = await storage.readAll().then((value) => value['token']);
      headers.addAll({'Authorization': 'Bearer $Token'});

      final body = jsonEncode(
        {
          "title": "$title",
          "content": "$content"
        }
      );

      final http.Response response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      if ( response.statusCode== 201) {
        print('Post added');
      } else {
        print('Post failed: ${response.statusCode}');
      }
  }

  Future<List<Post>?> search(String text,int page) async {
    var url = Uri.parse('${api_url}post/search/$text/$page');
    var Token = await storage.readAll().then((value) => value['token']);
    headers.addAll({'Authorization': 'Bearer $Token'});
    var response = await http.get(url,headers: headers);
    if (response.statusCode == 200) {
      var json = response.body;
      return postFromJson(json);
    }
  }

  Future<bool> isLoggedIn() async {
    print('Checking if logged in');
    var expiration = await storage.readAll().then((value) => value['expiration']);
    if (expiration != null) {
      var date = DateTime.parse(expiration);
      if (date.isBefore(DateTime.now())) {
        print('Token expired');
        await storage.deleteAll();
        return false;
      }
    }
    var Token = await storage.readAll().then((value) => value['token']);
    print('Tokkkkk: $Token');
    if ( Token != null) {
      return true;
    } else {
      return false;
    }
  }

  logout() async {
    await storage.deleteAll().then((value) => print('Logged out'));
  }

 Future<List<Comment>> getComments(int page,String post_id) async {
    var url = Uri.parse('${api_url}comment/get/$post_id/$page');
    var Token = await storage.readAll().then((value) => value['token']);
    headers.addAll({'Authorization': 'Bearer $Token'});
  print(url);
    var response = await http.get(url,headers: headers);
    if (response.statusCode == 200) {
      var json = response.body;
      return commentFromJson(json);
    } else {
      print('Failed to get comments: ${response.statusCode}');
      throw Exception('Failed to load post');
    }
  }

  Future<bool> addComment(String id, String text) async {
    var url = Uri.parse('${api_url}comment/add/');
    var Token = await storage.readAll().then((value) => value['token']);
    headers.addAll({'Authorization': 'Bearer $Token'});
    var response = await http.post(url,headers: headers,body: jsonEncode(
        {
          "content": "$text",
          "post_id": "$id"
        }
    ));
    if (response.statusCode == 200) {
      print('Comment added');
      return true;
    } else {
      print('Comment failed: ${response.statusCode}');
      return false;
    }
  }
}

class LoginResponseModel {
  final String token;

  LoginResponseModel({required this.token});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'],
    );
  }
}
