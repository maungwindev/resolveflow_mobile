import 'dart:math';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:resolveflow/src/config/app_secrets.dart';
import 'package:resolveflow/src/config/appwrite_collections.dart';
import 'package:resolveflow/src/models/technician_member.dart';
import 'package:resolveflow/src/utils/failure.dart';
import 'package:resolveflow/src/utils/logger.dart';
import 'package:resolveflow/src/utils/typedefs.dart';

abstract class UserProvisioningService {
  /// Lists all technicians assigned to the company's technician team.
  FutureEither<List<TechnicianMember>> getTechnicians();

  /// Creates a new technician account in Appwrite and assigns them to the 'technicians' team.
  FutureEither<TechnicianMember> createTechnician({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  /// Deletes a technician's user account and team membership.
  FutureEither<void> deleteTechnician({
    required String userId,
    required String membershipId,
  });

  /// Updates/resets a technician's password from the manager console.
  FutureEither<void> updateTechnicianPassword({
    required String userId,
    required String newPassword,
  });

  /// Reactivates an inactive technician account.
  FutureEither<void> reactivateTechnician({
    required String userId,
  });
}

class UserProvisioningServiceImpl implements UserProvisioningService {
  UserProvisioningServiceImpl({Dio? dioClient})
      : _dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: AppSecrets.endpoint.endsWith('/')
                    ? AppSecrets.endpoint.substring(0, AppSecrets.endpoint.length - 1)
                    : AppSecrets.endpoint,
                headers: {
                  'X-Appwrite-Project': AppSecrets.projectId,
                  'X-Appwrite-Key': AppSecrets.adminApiKey,
                  'Content-Type': 'application/json',
                },
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  final Dio _dio;

  String _generateUserId() {
    final randomHex = List.generate(
      20,
      (_) => Random().nextInt(16).toRadixString(16),
    ).join();
    return randomHex;
  }

  /// Automatically prepends '+' and cleans digits from backside
  String? _formatPhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final digitsOnly = phone.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return null;
    return '+$digitsOnly';
  }

  @override
  FutureEither<List<TechnicianMember>> getTechnicians() async {
    try {
      AppLogger.info('UserProvisioningService: Fetching technicians team memberships');
      final response = await _dio.get('/teams/${AppwriteConstants.teamTechnicians}/memberships');

      // Fetch users to enrich memberships with actual Auth active status, phone, and labels
      final Map<String, dynamic> usersById = {};
      try {
        final usersRes = await _dio.get(
          '/users',
          queryParameters: {'queries': ['limit(100)']},
        );
        final usersList = usersRes.data?['users'] as List<dynamic>? ?? [];
        for (final u in usersList) {
          if (u is Map<String, dynamic> && u['\$id'] != null) {
            usersById[u['\$id'].toString()] = u;
          }
        }
      } catch (userFetchErr) {
        AppLogger.warning('UserProvisioningService: User list fetch fallback: $userFetchErr');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final memberships = data['memberships'] as List<dynamic>? ?? [];

        final list = memberships.map((m) {
          final mMap = Map<String, dynamic>.from(m as Map<String, dynamic>);
          final uid = mMap['userId']?.toString() ?? '';
          if (usersById.containsKey(uid)) {
            final u = usersById[uid] as Map<String, dynamic>;
            mMap['status'] = u['status'];
            mMap['labels'] = u['labels'];
            if (u['phone'] != null && u['phone'].toString().isNotEmpty) {
              mMap['userPhone'] = u['phone'];
            }
          }
          return TechnicianMember.fromJson(mMap);
        }).toList();

        return right(list);
      }

      return right(<TechnicianMember>[]);
    } on DioException catch (e, st) {
      AppLogger.error('UserProvisioningService: getTechnicians error', error: e, stackTrace: st);
      final message = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to list technicians';
      return left(ServerFailure(message));
    } catch (e, st) {
      AppLogger.error('UserProvisioningService: getTechnicians unexpected error', error: e, stackTrace: st);
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<TechnicianMember> createTechnician({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final formattedPhone = _formatPhoneNumber(phone);

    try {
      String createdUserId = '';

      // 1. Create or resolve user in Appwrite Auth
      try {
        final generatedId = _generateUserId();
        AppLogger.info('UserProvisioningService: Creating user account for $cleanEmail (phone: $formattedPhone)');

        final Map<String, dynamic> userData = {
          'userId': generatedId,
          'email': cleanEmail,
          'password': password,
          'name': cleanName,
          'emailVerification': true,
        };

        if (formattedPhone != null) {
          userData['phone'] = formattedPhone;
        }

        final userResponse = await _dio.post('/users', data: userData);
        createdUserId = userResponse.data?['\$id']?.toString() ?? generatedId;
      } on DioException catch (userErr) {
        // If user was already created previously in Auth (HTTP 409 Conflict), lookup existing user
        final isConflict = userErr.response?.statusCode == 409 ||
            (userErr.response?.data?['message']?.toString().contains('already exists') ?? false);

        if (isConflict) {
          AppLogger.info('User already exists in Appwrite Auth. Retrieving existing user for team assignment...');
          final searchRes = await _dio.get(
            '/users',
            queryParameters: {'search': cleanEmail},
          );

          final usersList = searchRes.data?['users'] as List<dynamic>? ?? [];
          final matched = usersList.firstWhere(
            (u) => u['email']?.toString().toLowerCase() == cleanEmail,
            orElse: () => usersList.isNotEmpty ? usersList.first : null,
          );

          if (matched != null) {
            createdUserId = matched['\$id']?.toString() ?? '';
            AppLogger.info('Found existing userId: $createdUserId');

            // If phone provided, update phone on existing user
            if (formattedPhone != null && formattedPhone.isNotEmpty) {
              try {
                await _dio.patch(
                  '/users/$createdUserId/phone',
                  data: {'phone': formattedPhone},
                );
              } catch (phoneErr) {
                AppLogger.warning('Could not update phone on existing user: $phoneErr');
              }
            }
          } else {
            return left(const ServerFailure('User already exists in Auth. Please verify email.'));
          }
        } else {
          final errorMsg = userErr.response?.data?['message']?.toString() ??
              userErr.message ??
              'Failed to create user account';
          return left(ServerFailure(errorMsg));
        }
      }

      if (createdUserId.isEmpty) {
        return left(const ServerFailure('Unable to determine user ID for technician.'));
      }

      // 2. Set label 'technicians' on the user
      try {
        await _dio.put(
          '/users/$createdUserId/labels',
          data: {
            'labels': ['technicians'],
          },
        );
      } catch (labelError) {
        AppLogger.warning('UserProvisioningService: Label assignment warning: $labelError');
      }

      // 3. Add user directly to the 'technicians' team without invalid web URL
      AppLogger.info('UserProvisioningService: Enrolling user $createdUserId into team ${AppwriteConstants.teamTechnicians}');
      Map<String, dynamic> membershipData = {};

      try {
        final teamResponse = await _dio.post(
          '/teams/${AppwriteConstants.teamTechnicians}/memberships',
          data: {
            'userId': createdUserId,
            'roles': ['technician'],
          },
        );
        membershipData = teamResponse.data as Map<String, dynamic>? ?? {};
      } on DioException catch (teamErr) {
        AppLogger.warning('Direct userId enrollment failed: ${teamErr.response?.data}. Retrying with email payload...');
        final teamResponse = await _dio.post(
          '/teams/${AppwriteConstants.teamTechnicians}/memberships',
          data: {
            'userId': createdUserId,
            'email': cleanEmail,
            'roles': ['technician'],
            'name': cleanName,
          },
        );
        membershipData = teamResponse.data as Map<String, dynamic>? ?? {};
      }

      final technician = TechnicianMember(
        id: membershipData['\$id']?.toString() ?? createdUserId,
        userId: createdUserId,
        name: cleanName,
        email: cleanEmail,
        phone: formattedPhone,
        roles: const ['technician'],
        joinedAt: DateTime.now(),
        isConfirmed: true,
      );

      AppLogger.info('UserProvisioningService: Successfully enrolled technician ${technician.email}');
      return right(technician);
    } on DioException catch (e, st) {
      AppLogger.error('UserProvisioningService: createTechnician error', error: e, stackTrace: st);
      final errorMsg = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to provision technician';
      return left(ServerFailure(errorMsg));
    } catch (e, st) {
      AppLogger.error('UserProvisioningService: createTechnician unexpected error', error: e, stackTrace: st);
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<void> deleteTechnician({
    required String userId,
    required String membershipId,
  }) async {
    try {
      AppLogger.info('UserProvisioningService: Deactivating technician (userId: $userId, membershipId: $membershipId)');

      // 1. Invalidate all active sessions for this user on the server
      if (userId.isNotEmpty) {
        try {
          await _dio.delete('/users/$userId/sessions');
        } catch (sessErr) {
          AppLogger.warning('User sessions revoke warning: $sessErr');
        }

        // 2. Soft-delete: Mark user account as inactive (status: false) so records remain easy to audit in DB
        await _dio.patch(
          '/users/$userId/status',
          data: {'status': false},
        );

        try {
          await _dio.put(
            '/users/$userId/labels',
            data: {'labels': ['inactive']},
          );
        } catch (_) {}
      }

      // Note: We retain team membership record so that manager can view inactive accounts under Inactive filter
      AppLogger.info('UserProvisioningService: Successfully deactivated technician $userId');
      return right(null);
    } on DioException catch (e, st) {
      AppLogger.error('UserProvisioningService: deleteTechnician error', error: e, stackTrace: st);
      final errorMsg = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to delete technician';
      return left(ServerFailure(errorMsg));
    } catch (e, st) {
      AppLogger.error('UserProvisioningService: deleteTechnician unexpected error', error: e, stackTrace: st);
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<void> reactivateTechnician({required String userId}) async {
    try {
      AppLogger.info('UserProvisioningService: Reactivating technician $userId');
      await _dio.patch(
        '/users/$userId/status',
        data: {'status': true},
      );

      try {
        await _dio.put(
          '/users/$userId/labels',
          data: {'labels': ['technicians']},
        );
      } catch (_) {}

      AppLogger.info('UserProvisioningService: Successfully reactivated technician $userId');
      return right(null);
    } on DioException catch (e, st) {
      AppLogger.error('UserProvisioningService: reactivateTechnician error', error: e, stackTrace: st);
      final errorMsg = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to reactivate technician';
      return left(ServerFailure(errorMsg));
    } catch (e, st) {
      AppLogger.error('UserProvisioningService: reactivateTechnician unexpected error', error: e, stackTrace: st);
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<void> updateTechnicianPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('UserProvisioningService: Updating password for technician $userId');

      await _dio.patch(
        '/users/$userId/password',
        data: {
          'password': newPassword,
        },
      );

      AppLogger.info('UserProvisioningService: Successfully updated password for technician $userId');
      return right(null);
    } on DioException catch (e, st) {
      AppLogger.error('UserProvisioningService: updateTechnicianPassword error', error: e, stackTrace: st);
      final errorMsg = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to update technician password';
      return left(ServerFailure(errorMsg));
    } catch (e, st) {
      AppLogger.error('UserProvisioningService: updateTechnicianPassword unexpected error', error: e, stackTrace: st);
      return left(ServerFailure(e.toString()));
    }
  }
}
