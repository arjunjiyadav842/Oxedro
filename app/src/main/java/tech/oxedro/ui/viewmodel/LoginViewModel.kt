package tech.oxedro.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import tech.oxedro.data.model.AuthState
import tech.oxedro.data.repository.AuthRepository

class LoginViewModel : ViewModel() {
    private val authRepository = AuthRepository()

    private val _authState = MutableStateFlow<AuthState>(AuthState.Initial)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    private val _uniqueId = MutableStateFlow("")
    val uniqueId: StateFlow<String> = _uniqueId.asStateFlow()

    private val _password = MutableStateFlow("")
    val password: StateFlow<String> = _password.asStateFlow()

    private val _passwordVisible = MutableStateFlow(false)
    val passwordVisible: StateFlow<Boolean> = _passwordVisible.asStateFlow()

    fun onUniqueIdChange(value: String) {
        _uniqueId.value = value.uppercase()
    }

    fun onPasswordChange(value: String) {
        _password.value = value
    }

    fun togglePasswordVisibility() {
        _passwordVisible.value = !_passwordVisible.value
    }

    fun login() {
        if (_uniqueId.value.isBlank() || _password.value.isBlank()) {
            _authState.value = AuthState.Error("Please fill all fields")
            return
        }

        viewModelScope.launch {
            _authState.value = AuthState.Loading
            val result = authRepository.signIn(_uniqueId.value, _password.value)

            _authState.value = if (result.isSuccess) {
                AuthState.Success(result.getOrThrow())
            } else {
                val error = result.exceptionOrNull()
                AuthState.Error(error?.message ?: "Invalid credentials")
            }
        }
    }

    fun resetAuthState() {
        _authState.value = AuthState.Initial
    }
}
