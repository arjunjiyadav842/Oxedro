package tech.oxedro.data.repository

import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.postgrest.from
import kotlinx.serialization.json.Json
import tech.oxedro.data.SupabaseClient
import tech.oxedro.data.model.Profile

class AuthRepository {
    private val client = SupabaseClient.client
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun signIn(uniqueId: String, password: String): Result<Profile> {
        return try {
            val profileResult = client.from("profiles")
                .select {
                    filter {
                        eq("unique_id", uniqueId)
                        eq("is_active", true)
                    }
                }
                .decodeSingle<Profile>()

            client.auth.signInWith(Email) {
                email = profileResult.email
                this.password = password
            }

            Result.success(profileResult)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getCurrentUser(): Profile? {
        return try {
            val session = client.auth.currentSessionOrNull()
            if (session != null) {
                val userId = session.user?.id ?: return null
                client.from("profiles")
                    .select {
                        filter {
                            eq("id", userId)
                        }
                    }
                    .decodeSingle<Profile>()
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    suspend fun signOut() {
        try {
            client.auth.signOut()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun isLoggedIn(): Boolean {
        return client.auth.currentSessionOrNull() != null
    }
}
