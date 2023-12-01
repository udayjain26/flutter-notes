// Author: Uday Jain
//Date: 01/12/2023
//Purpose: To handle all the exceptions that can occur during the authentication process

//Login Exceptions

class InvalidCredentialAuthException implements Exception {}

class UserNotFoundException implements Exception {}

class InvalidEmailAuthException implements Exception {}

class MissingRequiredFieldsAuthException implements Exception {}

//Register Exceptions

class WeakPasswordException implements Exception {}

class EmailAlreadyInUseAuthException implements Exception {}

class InvalidEmailException implements Exception {}

//Generic Exceptions

class GenericAuthException implements Exception {}

class UserNotLoggedInException implements Exception {}

class UserNotVerifiedException implements Exception {}

class UserNotCreatedException implements Exception {}
