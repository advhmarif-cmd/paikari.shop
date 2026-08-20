# Supabase Auth implementation reference

Source URLs:

- https://supabase.com/docs/reference/dart/auth-signinwithoauth
- https://supabase.com/docs/reference/dart/auth-onauthstatechange
- https://supabase.com/docs/guides/auth/native-mobile-deep-linking
- https://supabase.com/docs/guides/auth/redirect-urls

Key implementation facts from the official docs:

- `supabase_flutter` v2 uses `OAuthProvider.google` with `supabase.auth.signInWithOAuth(...)`.
- `Supabase.initialize` can use `authFlowType: AuthFlowType.pkce`; PKCE is the secure default for deep-link authentication.
- The current session is available through `supabase.auth.currentSession`, and Auth changes are delivered through `supabase.auth.onAuthStateChange`.
- OAuth redirect URLs must be added to the Supabase Auth redirect allow list and must match the `redirectTo` value.
- Native mobile OAuth requires a custom URL scheme/deep link, such as `com.example.app://login-callback/`, registered in the app and in Supabase Auth URL configuration.
- Supabase RPC calls are available through `supabase.rpc('function_name', params: {...})`; tables/functions exposed through the Data API must have appropriate grants and RLS policies.
- Client-side apps should use a publishable/anon key; service-role keys must not be shipped in the app.
