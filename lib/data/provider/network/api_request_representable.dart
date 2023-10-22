enum HttpMethod { get, post, delete, put, patch }

extension HttpMethodString on HttpMethod {
  String get string {
    switch (this) {
      case HttpMethod.get:
        return 'get';
      case HttpMethod.post:
        return 'post';
      case HttpMethod.delete:
        return 'delete';
      case HttpMethod.put:
        return 'put';
      case HttpMethod.patch:
        return 'patch';
    }
  }
}

abstract class ApiRequestRepresentable {
  String get url;
  String get baseUrl;
  String get endPoint;
  HttpMethod get method;
  Map<String, String>? get headers;
  Map<String, dynamic>? get query;
  dynamic get body;
  Future request();
}
