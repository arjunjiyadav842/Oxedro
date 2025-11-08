package tech.oxedro.data

import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.postgrest.Postgrest

object SupabaseClient {
    private const val SUPABASE_URL = "https://hkqjhwpeqvrbypfzcwcp.supabase.co"
    private const val SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrcWpod3BlcXZyYnlwZnpjd2NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2MDE1MzAsImV4cCI6MjA3ODE3NzUzMH0.XOQluaki5FyPfjmpQtDxViE2pzW2ri9_XxrH8oeTTYE"

    val client = createSupabaseClient(
        supabaseUrl = SUPABASE_URL,
        supabaseKey = SUPABASE_ANON_KEY
    ) {
        install(Auth)
        install(Postgrest)
    }
}
