import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_personal_finance_demo/data/provider/network/api_request_representable.dart';

class ApiProvider {
  static const requestTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);

  final _client = Dio();
  static final _singleton = ApiProvider();
  static ApiProvider get instance => _singleton;
  Future request(ApiRequestRepresentable request) async {
    try {
      final response = await _client.request(
        request.url,
        options: Options(
          sendTimeout: requestTimeout,
          receiveTimeout: receiveTimeout,
          method: request.method.string,
          headers: request.headers,
        ),
        queryParameters: request.query,
        data: request.body,
      );
      return _returnResponse(response);
    } on TimeOutException catch (_) {
      throw TimeOutException('Time Out Exception');
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    }
  }

  dynamic _returnResponse(Response<dynamic> response) {
    switch (response.statusCode) {
      case 200:
        return response.data;
      case 400:
        throw BadRequestException(response.data.toString());
      case 401:
      case 422:
      case 403:
        throw UnauthorisedException(' ${response.data['message']}');
      case 404:
        throw BadRequestException(response.data['message'].toString());
      case 500:
      case 503:
        print("status code 500 and 503 :  ${response.data.toString()}");
        throw FetchDataException('Internal Server Error');
      // ${response.body['message'].toString()}
      default:
        throw FetchDataException(
            'Error occured while Communication with Server');
    }
  }
}

class AppException implements Exception {
  final String code;
  final String message;
  final String details;

  AppException(
      {required this.code, required this.message, required this.details});

  @override
  String toString() {
    return "[$code] : $message \n $details";
  }
}

class FetchDataException extends AppException {
  FetchDataException(String details)
      : super(
            code: 'Fetch-Data',
            message: 'Internal Server Error',
            details: details);
}

class UnauthorisedException extends AppException {
  UnauthorisedException(String details)
      : super(code: 'unauthorised', message: 'Unauthorised', details: details);
}

class InvalidInputException extends AppException {
  InvalidInputException(String details)
      : super(
            code: 'invalid-input', message: 'Invalid Input', details: details);
}

class AuthenticationException extends AppException {
  AuthenticationException(String details)
      : super(
          code: "authentication-failed",
          message: "Authentication Failed",
          details: details,
        );
}

class TimeOutException extends AppException {
  TimeOutException(String details)
      : super(
          code: "request-timeout",
          message: "Request TimeOut",
          details: details,
        );
}

class NoInternetException extends AppException {
  NoInternetException(String details)
      : super(
          code: "no-internet",
          message: "Please Check Your Internet Connection",
          details: details,
        );
}

class BadRequestException extends AppException {
  BadRequestException(String details)
      : super(
          code: "invalid-request",
          message: "Invalid Request",
          details: details,
        );
}
