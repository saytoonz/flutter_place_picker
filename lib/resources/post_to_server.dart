import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class Post {
  late Response response;
  late String progress;
  Dio dio = Dio();

  Future<String> toServer(
    String url,
    Map<String, dynamic> data,
  ) async {
    try {
      response = await dio.post(
        url,
        data: FormData.fromMap(data),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          },
        ),
        onSendProgress: (int sent, int total) {
          String percentage = (sent / total * 100).toStringAsFixed(2);

          progress = "$sent" " Bytes of " "$total Bytes - " +
              percentage +
              " % uploaded";
          debugPrint("================$progress");
        },
      );
      debugPrint("================${response.toString()};");
      debugPrint("================${url.toString()};");
      if (response.statusCode == 200) {
        return response.toString();
      } else {
        return jsonEncode(
            {"error": true, "msg": "Error during connection to server."});
      }
    } catch (e) {
      debugPrint('error from server: $e');
      return jsonEncode({
        "error": true,
        "msg":
            "Oops! Seems you might have an internet connectivity problem, Kindly check your connection."
      });
    }
  }
}
