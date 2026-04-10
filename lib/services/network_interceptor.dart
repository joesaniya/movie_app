import 'dart:math';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

final _logger = Logger('NetworkInterceptor');

class NetworkInterceptor extends Interceptor {
  static const int _maxRetries = 3;
  static const int _initialDelayMs = 100;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _logger.info('REQUEST[${options.method}] => URL: ${options.uri}');
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    _logger.info(
      'RESPONSE[${response.statusCode}] => URL: ${response.requestOptions.uri}',
    );
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _logger.severe(
      'ERROR[${err.response?.statusCode}] => URL: ${err.requestOptions.uri}',
      err,
    );

    
    if (err.requestOptions.method.toUpperCase() == 'GET') {
      final statusCode = err.response?.statusCode;
      final isNetworkError =
          err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.unknown;
      final isServerError = statusCode != null && statusCode >= 500;

      
      if (isNetworkError || isServerError) {
        return _retryRequest(err, handler);
      }
    }

    return handler.next(err);
  }

  Future<void> _retryRequest(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    int retryCount = requestOptions.extra['retryCount'] ?? 0;

    if (retryCount < _maxRetries) {
      retryCount++;
      requestOptions.extra['retryCount'] = retryCount;

      final delayMs = _initialDelayMs * pow(2, retryCount - 1).toInt();
      _logger.info(
        'Retrying request #$retryCount after ${delayMs}ms: ${requestOptions.uri}',
      );

      await Future.delayed(Duration(milliseconds: delayMs));

      try {
        final response = await Dio().request(
          requestOptions.uri.toString(),
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            extra: requestOptions.extra,
            contentType: requestOptions.contentType,
          ),
          data: requestOptions.data,
        );
        return handler.resolve(response);
      } on DioException catch (e) {
        return _retryRequest(e, handler);
      }
    }

    return handler.next(err);
  }
}

class SimulatedFailureInterceptor extends Interceptor {
  static const double _failureRate = 0.3; 

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
   
    if (options.method.toUpperCase() == 'GET') {
      if (_shouldSimulateFailure()) {
        _simulateRandomFailure(options, handler);
        return;
      }
    }
    return handler.next(options);
  }

  void _simulateRandomFailure(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final failureType = Random().nextInt(2);
    if (failureType == 0) {
     
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          message: 'Simulated network failure',
        ),
      );
    } else {
      
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 500,
          statusMessage: 'Simulated Internal Server Error',
        ),
      );
    }
  }

  bool _shouldSimulateFailure() {
    return Random().nextDouble() < _failureRate;
  }
}
