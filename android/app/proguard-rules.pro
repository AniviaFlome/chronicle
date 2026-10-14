# Chronicle release (R8) keep rules.
#
# Glance instantiates widget ActionCallbacks reflectively through their
# public no-arg constructors. R8 cannot see that reflective use and
# strips the constructors in release builds (debug builds never minify),
# which breaks EVERY widget tap on release with:
#   java.lang.NoSuchMethodException: <XCallback>.<init> []
# (seen on-device via logcat on v1.11.0 release while debug taps worked).
# Keep every callback implementation in the widget package.
-keep class com.chronicleapp.chronicle.widget.*Callback {
    <init>(...);
}
