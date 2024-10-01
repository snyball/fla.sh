# `fla.sh`

A simple (Linux-only) command line wrapper for `dd`, it will only list
disks that are:

A) Not mounted

B) Removable

```text
$ fla.sh ~/Downloads/memtest86-usb.img
Select a disk
1) /dev/sda: My Cool Label Intenso Speed Line
2) /dev/sdb: Generic Label Intenso Speed Line
#? 2
Are you sure you want to ERASE ALL DATA on usb-Intenso_Speed_Line_RANDOMCHARS98-0:0?
I will execute the following command:
$ sudo dd if=/home/user/Downloads/memtest86-usb.img of=/dev/disk/by-id/usb-Intenso_Speed_Line_RANDOMCHARS98-0:0 bs=4096 status=progress
yes/N?) yes
262144+0 records in
262144+0 records out
1073741824 bytes (1,1 GB, 1,0 GiB) copied, 16,9434 s, 63,4 MB/s
Waiting for sync ...
Done.
```

Use this script if you want to flash disks quickly, and with less
stress, without needing to use an ad-ridden electron behemoth like
balena etcher.

### Dependencies

- `jq`
- optional: `fzf`
  - Used as the menu if present
