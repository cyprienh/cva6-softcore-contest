-fno-rtti pour la compilation du plugin :

  https://gcc.gnu.org/legacy-ml/gcc-patches/2013-07/msg01258.html :

    [PATCH 05/11] Add -fno-rtti when building plugins.
    
        From: David Malcolm <dmalcolm at redhat dot com>
        To: gcc-patches at gcc dot gnu dot org
        Cc: David Malcolm <dmalcolm at redhat dot com>
        Date: Fri, 26 Jul 2013 11:04:35 -0400
        Subject: [PATCH 05/11] Add -fno-rtti when building plugins.
        References: <1374851081-32153-1-git-send-email-dmalcolm at redhat dot com>
    
    With the conversion of passes to C++ classes, plugins that add custom
    passes must create them by creating their own derived classes of the
    relevant subclass of opt_pass.  gcc itself is built with -fno-rtti,
    hence there is no RTTI available for the opt_pass class hierarchy.
    
    Hence plugins that create passes will need to be built with RTTI
    disabled in order to link against gcc, or they will fail to load, with
    an error like:
          cc1: error: cannot load plugin ./selfassign.so
          ./selfassign.so: undefined symbol: _ZTI8opt_pass
    (aka "typeinfo for opt_pass").
    
    gcc/testsuite
    
        * lib/plugin-support.exp (plugin-test-execute): Add -fno-rtti
        to optstr when building plugins.
    ---
     gcc/testsuite/lib/plugin-support.exp | 2 +-
     1 file changed, 1 insertion(+), 1 deletion(-)
    
    diff --git a/gcc/testsuite/lib/plugin-support.exp
    b/gcc/testsuite/lib/plugin-support.exp
    index 88033b3..017f3fd 100644
    --- a/gcc/testsuite/lib/plugin-support.exp
    +++ b/gcc/testsuite/lib/plugin-support.exp
    @@ -104,7 +104,7 @@ proc plugin-test-execute { plugin_src plugin_tests } {
        set optstr [concat $optstr "-DIN_GCC -fPIC -shared -undefined
    dynamic_lookup"]
         } else {
        set plug_cflags $PLUGINCFLAGS 
    -   set optstr "$includes $extra_flags -DIN_GCC -fPIC -shared"
    +   set optstr "$includes $extra_flags -DIN_GCC -fPIC -shared -fno-rtti"
         }
     
         # Temporarily switch to the environment for the plugin compiler.
    -- 
    1.7.11.7
