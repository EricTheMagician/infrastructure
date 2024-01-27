{
  # on this system, there are 3 drives
  # xvda is a small 10G drive just for booting
  # xvdb and xvdc are 1T drives for data
  disko.devices = {
    disk = {
      xvda = {
        type = "disk";
        device = "/dev/xvda";
        # this is what's called a hybrid boot: efi boot with legcy bios
        content = {
          type = "gpt";
          partitions = {
            bootloader = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "2G";
              #type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
          };
        };
      };
      xvdb = {
        type = "disk";
        device = "/dev/xvdb";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted-xvdb";
                extraOpenArgs = [];
                settings = {
                  # if you want to use the key for interactive login be sure there is no trailing newline
                  # for example use `echo -n "password" > /tmp/secret.key`
                  #keyFile = "/tmp/secret.key";
                  allowDiscards = true;
                };
                #additionalKeyFiles = ["/tmp/additionalSecret.key"];
                content = {
                  type = "lvm_pv";
                  vg = "pool";
                };
              };
            };
          };
        };
      };
      xvdc = {
        type = "disk";
        device = "/dev/xvdc";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted-xvdc";
                extraOpenArgs = [];
                settings = {
                  # if you want to use the key for interactive login be sure there is no trailing newline
                  # for example use `echo -n "password" > /tmp/secret.key`
                  #keyFile = "/tmp/secret.key";
                  allowDiscards = true;
                };
                #additionalKeyFiles = ["/tmp/additionalSecret.key"];
                content = {
                  type = "lvm_pv";
                  vg = "pool";
                };
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          swap = {
            size = "4G";
            content = {
              type = "swap";
            };
          };
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = ["-f"]; # Override existing partition
              # Subvolumes must set a mountpoint in order to be mounted,
              # unless their parent is mounted
              subvolumes = {
                # Subvolume name is different from mountpoint
                "/rootfs" = {
                  mountpoint = "/";
                };
                # Subvolume name is the same as the mountpoint
                "/home" = {
                  mountOptions = ["compress=zstd"];
                  mountpoint = "/home";
                };
                # Parent is not mounted so the mountpoint must be set
                "/nix" = {
                  mountOptions = ["compress=zstd" "noatime"];
                  mountpoint = "/nix";
                };
              };
            };
          };
        };
      };
    };
  };
}
