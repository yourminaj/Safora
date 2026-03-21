import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/contacts_local_datasource.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/repositories/contacts_repository.dart';
import 'contacts_state.dart';

/// Cubit managing emergency contacts CRUD operations.
class ContactsCubit extends Cubit<ContactsState> {
  ContactsCubit(this._repository) : super(const ContactsInitial());

  final ContactsRepository _repository;

  /// Load all contacts from storage.
  void loadContacts() {
    emit(const ContactsLoading());
    try {
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
    } catch (e) {
      emit(ContactsError('Failed to update contact: $e'));
    }
  }

  /// Delete a contact by ID.
  Future<void> deleteContact(String id) async {
    try {
      await _repository.delete(id);
      loadContacts();
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
    } catch (e) {
      emit(ContactsError('Failed to set primary contact: $e'));
    }
  }
}
