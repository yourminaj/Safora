import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/app_logger.dart';
import '../../../data/datasources/contacts_cloud_sync.dart';
import '../../../data/datasources/contacts_local_datasource.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/repositories/contacts_repository.dart';
import 'contacts_state.dart';

/// Cubit managing emergency contacts CRUD operations.
///
/// When [_cloudSync] is provided, every mutation (add/update/delete/setPrimary)
/// triggers a fire-and-forget sync to Cloud Firestore.
class ContactsCubit extends Cubit<ContactsState> {
  ContactsCubit(this._repository, {ContactsCloudSync? cloudSync})
      : _cloudSync = cloudSync,
        super(const ContactsInitial());

  final ContactsRepository _repository;
  final ContactsCloudSync? _cloudSync;

  /// Fire-and-forget sync to cloud after any local mutation.
  void _syncToCloud() {
    final sync = _cloudSync;
    if (sync == null) return;
    try {
      final all = _repository.getAll();
      sync.syncToCloud(all).catchError((e) {
        AppLogger.warning('[ContactsCubit] Cloud sync failed: $e');
      });
    } catch (e) {
      AppLogger.warning('[ContactsCubit] Cloud sync prep failed: $e');
    }
  }

  /// Load all contacts from storage, pulling from cloud first if local is empty.
  ///
  /// On a fresh install or after clearing app data, the local Hive box is
  /// empty while contacts may still exist in Firestore.  We perform a
  /// one-shot cloud pull when the local store is empty so the user's contacts
  /// are restored without any manual action.
  Future<void> loadContacts() async {
    emit(const ContactsLoading());
    try {
      // If local storage is empty (e.g. reinstall), pull from cloud first.
      final sync = _cloudSync;
      if (_repository.getAll().isEmpty && sync != null) {
        AppLogger.info('[ContactsCubit] Local contacts empty — syncing from cloud');
        final cloudContacts = await sync.syncFromCloud();
        for (final c in cloudContacts) {
          try {
            await _repository.add(c);
          } catch (_) {
            // ContactLimitException can fire for free users — safe to skip.
          }
        }
      }

      final contacts = _repository.getAll();
      emit(ContactsLoaded(
        contacts: contacts,
        isLimitReached: _repository.isLimitReached,
      ));
    } catch (e) {
      emit(ContactsError('Failed to load contacts: $e'));
    }
  }

  /// Add a new emergency contact.
  Future<void> addContact({
    required String name,
    required String phone,
    String? relationship,
    bool isPrimary = false,
  }) async {
    try {
      final contact = EmergencyContact(
        name: name,
        phone: phone,
        relationship: relationship,
        isPrimary: isPrimary,
        createdAt: DateTime.now(),
      );
      await _repository.add(contact);
      loadContacts(); // Reload list
      _syncToCloud();
    } on ContactLimitException {
      final contacts = _repository.getAll();
      emit(ContactsLimitReached(contacts: contacts));
    } catch (e) {
      emit(ContactsError('Failed to add contact: $e'));
    }
  }

  /// Update an existing contact.
  Future<void> updateContact(EmergencyContact contact) async {
    try {
      await _repository.update(contact);
      loadContacts();
      _syncToCloud();
    } catch (e) {
      emit(ContactsError('Failed to update contact: $e'));
    }
  }

  /// Delete a contact by ID.
  Future<void> deleteContact(String id) async {
    try {
      await _repository.delete(id);
      loadContacts();
      _syncToCloud();
    } catch (e) {
      emit(ContactsError('Failed to delete contact: $e'));
    }
  }

  /// Set a contact as the primary contact (first to be notified).
  Future<void> setPrimary(String id) async {
    try {
      final contacts = _repository.getAll();
      for (final contact in contacts) {
        if (contact.id == id) {
          await _repository.update(contact.copyWith(isPrimary: true));
        } else if (contact.isPrimary) {
          await _repository.update(contact.copyWith(isPrimary: false));
        }
      }
      loadContacts();
      _syncToCloud();
    } catch (e) {
      emit(ContactsError('Failed to set primary contact: $e'));
    }
  }
}

