import 'dart:io';
import 'package:dio/dio.dart';

import '../../core/error/error.dart';

/// Menguraikan DioException menjadi pesan yang ramah pengguna dan kode status HTTP.
///
/// Mengembalikan Map dengan 'message' (String) dan 'statusCode' (int?).
AppError parseDioException(DioException error) {
  String errorMessage =
      "Terjadi kesalahan yang tidak terduga. Silakan coba lagi.";
  int? statusCode = error.response?.statusCode;

  switch (error.type) {
    case DioExceptionType.connectionError:
      // Error koneksi seperti SocketException (tidak ada internet, host tidak reachable)
      if (error.error is SocketException) {
        errorMessage =
            "Tidak ada koneksi internet. Mohon periksa koneksi Anda dan coba lagi.";
      } else if (error.error is HandshakeException) {
        errorMessage =
            "Kesalahan dalam koneksi aman (SSL/TLS). Mohon coba lagi.";
      } else {
        errorMessage = "Koneksi ke server gagal. Mohon coba lagi nanti.";
      }
      break;

    case DioExceptionType.connectionTimeout:
      errorMessage =
          "Waktu koneksi habis. Server tidak merespons dalam waktu yang ditentukan.";
      break;

    case DioExceptionType.sendTimeout:
      errorMessage = "Waktu pengiriman data habis. Mohon periksa koneksi Anda.";
      break;

    case DioExceptionType.receiveTimeout:
      errorMessage =
          "Waktu penerimaan data habis. Mungkin ada masalah dengan server atau koneksi Anda.";
      break;

    case DioExceptionType.badResponse:
      // Respons dari server diterima, tetapi ada masalah pada status code (4xx, 5xx)
      statusCode = error.response?.statusCode;
      switch (statusCode) {
        case 400:
          errorMessage =
              "Permintaan tidak valid. Mohon periksa data yang Anda kirim.";
          break;
        case 401:
          errorMessage =
              "Anda tidak memiliki otorisasi untuk mengakses ini. Mohon login kembali.";
          break;
        case 403:
          errorMessage =
              "Akses ditolak. Anda tidak memiliki izin untuk melakukan tindakan ini.";
          break;
        case 404:
          errorMessage =
              "Sumber daya tidak ditemukan. Endpoint atau data yang Anda cari tidak ada.";
          break;
        case 405:
          errorMessage =
              "Metode tidak diizinkan. Server tidak mendukung metode HTTP ini.";
          break;
        case 408: // Request Timeout
          errorMessage =
              "Permintaan habis waktu. Server tidak merespons dalam waktu yang ditentukan.";
          break;
        case 409: // Conflict
          errorMessage =
              "Terjadi konflik data. Mungkin data yang Anda masukkan sudah ada.";
          break;
        case 422: // Unprocessable Entity (sering digunakan untuk validasi gagal)
          errorMessage =
              "Data yang Anda kirim tidak dapat diproses. Mohon periksa kembali input Anda.";
          break;
        case 429: // Too Many Requests
          errorMessage =
              "Anda telah mengirim terlalu banyak permintaan. Mohon tunggu sebentar dan coba lagi.";
          break;
        case 500:
          errorMessage =
              "Kesalahan server internal. Server sedang mengalami masalah.";
          break;
        case 502:
          errorMessage =
              "Bad Gateway. Server menerima respons tidak valid dari upstream.";
          break;
        case 503:
          errorMessage =
              "Layanan tidak tersedia. Server sedang dalam pemeliharaan atau terlalu sibuk.";
          break;
        case 504:
          errorMessage =
              "Gateway Timeout. Server tidak menerima respons tepat waktu.";
          break;
        default:
          errorMessage =
              "Terjadi kesalahan pada server dengan status kode: $statusCode. Mohon coba lagi.";
      }

      // TODO
      // Coba ambil pesan dari response body jika ada dan bisa di-parse
      try {
        if (error.response?.data != null) {
          // Asumsi response.data adalah Map atau memiliki 'message'/'error' key
          // Sesuaikan ini dengan struktur error API Anda
          if (error.response!.data is Map &&
              error.response!.data.containsKey('message')) {
            errorMessage = error.response!.data['message'].toString();
          } else if (error.response!.data is Map &&
              error.response!.data.containsKey('error')) {
            errorMessage = error.response!.data['error'].toString();
          } else if (error.response!.data is String &&
              error.response!.data.isNotEmpty) {
            errorMessage = error
                .response!
                .data; // Jika response body langsung string error
          }
        }
      } catch (e) {
        // Gagal parse response data, gunakan pesan default
        // debugPrint("Failed to parse DioException badResponse data: $e");
      }
      // END TODO
      break;

    case DioExceptionType.cancel:
      errorMessage = "Permintaan telah dibatalkan.";
      break;

    case DioExceptionType.badCertificate:
      errorMessage =
          "Sertifikat SSL/TLS tidak valid. Koneksi aman tidak dapat dibuat.";
      break;

    case DioExceptionType.unknown:
      // Error lain yang tidak dikategorikan oleh Dio
      if (error.error is SocketException) {
        // Ini bisa terjadi jika tidak ada koneksi internet atau masalah DNS
        errorMessage =
            "Tidak dapat terhubung ke server. Mohon periksa koneksi internet Anda.";
      } else if (error.error is FormatException) {
        // Error saat parsing JSON
        errorMessage =
            "Respons dari server tidak dapat diproses. Terjadi kesalahan format data.";
      } else if (error.error != null) {
        // Jika ada error objek lain yang spesifik
        errorMessage =
            "Terjadi kesalahan tidak dikenal: ${error.error.toString()}.";
      } else {
        errorMessage =
            "Terjadi kesalahan yang tidak diketahui. Mohon coba lagi.";
      }
      break;
  }

  return AppError(message: errorMessage, statusCode: statusCode ?? -1);
}
