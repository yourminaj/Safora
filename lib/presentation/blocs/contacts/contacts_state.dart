import 'package:equatable/equatable.dart';
import '../../../data/models/emergency_contact.dart';

/// States for the contacts management cubit.
sealed class ContactsState extends Equatable {
  const ContactsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before contacts are loaded.
class ContactsInitial extends ContactsState {
  const ContactsInitial();
}

/// Loading contacts from storage.
class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

/// Contacts loaded successfully.
class ContactsLoaded extends ContactsState {
  const ContactsLoaded({
    required this.contacts,
    required this.isLimitReached,
  });

  final List<EmergencyContact> contacts;
  final bool isLimitReached;

  @override
  List<Object?> get props => [contacts, isLimitReached];
}

/// An error occurred while managing contacts.
class ContactsError extends ContactsState {
  const ContactsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Contact limit reached (free tier).
class ContactsLimitReached extends ContactsState {
  const ContactsLimitReached({required this.contacts});
  final List<EmergencyContact> contacts;

  @override
  List<Object?> get props => [contacts];
}
