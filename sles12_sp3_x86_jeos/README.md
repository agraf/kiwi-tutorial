== Example template for an x86 SLES 12 SP3 minimal image ==

This image demonstrates how to do a simple, ext4 based image with a single
partition and online resizing of the same. Please follow the instructions
below to create and run the image in a virtual machine.


# Install kiwi (SLE15 calls it python3-kiwi)
zypper in python2-kiwi

# Build the image
sudo kiwi system build  --description sles12_sp3_x86_jeos --target-dir=tmp

# Create a big virtual disk containing the image
qemu-img create -f qcow2 -b /studio/arm/kiwi-tutorial/tmp/SLES12-SP3-template.x86_64-0.0.1.raw foo.qcow2 20G

# Run the image
qemu-system-x86_64 -nographic -enable-kvm -bios /usr/share/qemu/ovmf-x86_64.bin foo.qcow2 -m 4G

User: root
Pass: linux
