package tech.oxedro.data.model

sealed class AuthState {
    data object Initial : AuthState()
    data object Loading : AuthState()
    data class Success(val profile: Profile) : AuthState()
    data class Error(val message: String) : AuthState()
}
