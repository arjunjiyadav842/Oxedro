package tech.oxedro.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Profile(
    val id: String,
    @SerialName("unique_id")
    val uniqueId: String,
    val email: String,
    val phone: String? = null,
    @SerialName("first_name")
    val firstName: String,
    @SerialName("last_name")
    val lastName: String? = null,
    val role: UserRole,
    val address: String? = null,
    val sex: Gender? = null,
    @SerialName("blood_group")
    val bloodGroup: String? = null,
    @SerialName("avatar_url")
    val avatarUrl: String? = null,
    @SerialName("is_active")
    val isActive: Boolean = true,
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null
)

@Serializable
enum class UserRole {
    @SerialName("superadmin")
    SUPER_ADMIN,
    @SerialName("admin")
    ADMIN,
    @SerialName("teacher")
    TEACHER,
    @SerialName("student")
    STUDENT,
    @SerialName("parent")
    PARENT
}

@Serializable
enum class Gender {
    @SerialName("male")
    MALE,
    @SerialName("female")
    FEMALE,
    @SerialName("other")
    OTHER
}
