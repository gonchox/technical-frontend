Map<String, String> headers() {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',    
  };
  return headers;
}

String url() {
  return "http://localhost:8080/api/";
}