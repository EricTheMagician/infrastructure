{
  disko.devices = {
    disk = {
      vdb = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "1GiB";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
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
                  # This subvolume will be created but not mounted
                  "/test" = {};
                };
              };
            };
          };
        };
      };
      external-usb = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD120EDBZ-11B1HA0_5QJ1XG5B";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  # Subvolume name is different from mountpoint
                  "/data" = {
                    mountpoint = "/data";
                    mountOptions = ["compress=zstd"];
                  };
                  "/data/attic" = {};
                  "/data/minio" = {
                    mountOptions = ["compress=zstd"];
                  };
                  "/data/seaweedfs" = {
                    mountOptions = ["compress=zstd"];
                  };
                  "/data/audiobookshelf" = {
                    mountpoint = "/var/lib/audiobookshelf";
                  };
                  "/nix" = {
                    # mountOptions = ["compress=zstd" "noatime"];
                    # mountpoint = "/nix";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
