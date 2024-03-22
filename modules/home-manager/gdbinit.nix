{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkOption types mkEnableOption mkIf;
  cfg = config.my.gdb;
  qt-pretty-printer = pkgs.stdenv.mkDerivation rec {
    inherit (pkgs.kdePackages.kdevelop) src version;
    pname = "qt6-pretty-printers";
    dontBuild = true;
    dontConfigure = true;
    installPhase = ''
      mkdir $out
      ls ${src}
      mkdir source
      tar -xJf $src -C source --strip-components=1
      ls source/plugins/gdb/printers
      echo $out
      ls $out
      install -m644 "source/plugins/gdb/printers/qt.py" $out
      install -m644 "source/plugins/gdb/printers/helper.py" $out
    '';
  };
in {
  options.my.gdb = {
    enable = mkEnableOption "gdb";
    pretty-print.qt.enable = mkEnableOption "Qt Pretty Printer";
  };

  config = mkIf cfg.enable {
    home.file.".gdbinit".source = pkgs.writeText ".gdbinit" (''
        set history save on
        set print thread-events off
        set debuginfod enabled
        python
        import sys
        sys.path.insert(0, '${lib.getLib pkgs.gcc-unwrapped}/share/gcc-${pkgs.gcc-unwrapped.version}/python')
        from libstdcxx.v6.printers import register_libstdcxx_printers
        register_libstdcxx_printers (None)

        #######################
        ## add stepskip
        #######################
        import gdb

        class StepSkipping(gdb.Command):
            """Step into or over based on the source file path"""

            def __init__(self):
                super(StepSkipping, self).__init__("stepskip", gdb.COMMAND_USER)

            def invoke(self, arg, from_tty):
                while True:
                    gdb.execute("step")
                    frame = gdb.selected_frame()
                    sal = frame.find_sal()
                    fname = sal.symtab.fullname() if sal.symtab else ""

                    if not fname.startswith('/opt/rh') and not fname.startswith('/home/conda') and not fname.startswith('/work/conan/.conan/data'):
                        break
                    gdb.execute("next")
        StepSkipping()

        end
      ''
      + (lib.optionalString cfg.pretty-print.qt.enable ''
        python
        sys.path.insert(0, '${qt-pretty-printer}')
        from qt import register_qt_printers
        register_qt_printers (None)
        end
      ''));
  };
}
