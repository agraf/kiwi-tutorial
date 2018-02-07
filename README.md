# SLES12 SP3 AArch64/x86_64 images with KIWI - Quick Tutorial

Welcome to the really quick guide on how to create images with kiwi. This will
only teach you the basics, but will give you enough tooling so that the gaps are
easy to fill out using google or by asking friendly people you know.

The main idea behind this tutorial is that after you've finished, you will be
able to build images for both ARM and x86 systems easily. You will also be able
to do so both locally as well as using OBS.

###  Table of contents

   * [Preparation](#preparation)
   * [Building locally](#building-locally)
      * [First step on x86_64](#first-step-on-x86_64)
      * [First step on aarch64](#first-step-on-aarch64)
      * [Comparing aarch64 and x86_64](#comparing-aarch64-and-x86_64)
      * [Adding a package](#adding-a-package)
      * [Adding a service](#adding-a-service)
   * [Building in the Open Build Service](#building-in-the-open-build-service)
      * [First OBS steps](#first-obs-steps)
      * [Building with packages from OBS](#building-with-packages-from-obs)
      * [Breathing clouds](#breathing-clouds)

## Preparation

As a first step, clone this git repository:

    $ git clone https://github.com/agraf/kiwi-tutorial.git

Then run all commands under this directory.

Patch your SMT server name or IP address in all \*/\*.kiwi files. For example,
if your SMT server is smt.example.com, run the following command:

    $ for i in */*.kiwi; do sed -i 's/SMT_SERVER/smt.example.com/g' $i; done

You will also need the following:

  * SMT server with SLES12 SP3 (base and public cloud) repositories synchronized
  * x86_64 server with
    * SLES12 SP3 installed
    * The KVM pattern installed
    * Package "qemu-ovmf-x86_64" installed
  * aarch64 server with
    * SLES12 SP3 installed
    * The KVM pattern installed
    * Package "qemu-uefi-aarch64" installed

## Building locally

### First step on x86_64

Go to your x86_64 SLES12 SP3 host. Clone this git repo locally. Then follow
the README in the [sles12_sp3_x86_jeos directory](sles12_sp3_x86_jeos).

### First step on aarch64

Go to your aarch64 SLES12 SP3 host. Clone this git repo locally. Then follow
the README in the [sles12_sp3_aarch64_jeos directory](sles12_sp3_aarch64_jeos).

### Comparing aarch64 and x86_64

diff -ru both directories.

You will see that both architectures have basically identical kiwi description
files. Almost all of the architecture specifics are abstracted away.

### Adding a package

Now that you know how irrelevant architectures are, concentrate on the one
that is easiest for you to access right now ;).

Try to add the package "curl" to the image. Rebuild it and verify that curl is
available.

### Adding a service

Add the package "apache2" to your image. We want to start it on bootup. To
enable automatic execution of the new service on boot, edit config.sh.

## Building in the Open Build Service

So far we have done everything locally. That means that every time things
change, someone would need to manually recreate the image. Of course you
could automate things slightly using external tools like Jenkins, but there
is an open source project that makes package and image building across
architectures quite easy: OBS - the Open Build Service.

Integration of the image to the build service will allow to automate the
build of the image as soon as a package change in the repositories occurs.

Follow the next steps to copy our image into the build service and add
package we build there.

### First OBS steps

Create an account on build.opensuse.org. Then run

    $ zypper in osc
    $ osc branch home:cwh/moon-buggy

Now go to build.opensuse.org, log in, select "Home Project" in the top right
corner, click on subprojects, select the newly added project. Go to
"Repositories". Remove all unneeded build targets.  Add SLES12 SP3 as target
distribution.

Unfortunately, OBS only builds for x86_64 by default (because that's where the
bulk of build power lies). Let's add a build for aarch64 as well. Go to
Advanced -> Meta and add an

    <arch>aarch64</arch>

line right below the

    <arch>x86_64</arch>

line. Also remove the following lines to get externally accessible repositories
created:

    <publish>
      <disable/>
    </publish>

Press "Save".

The web service should now build the package on both aarch64 and x86_64 for
you. While it's doing that, either grab a coffee or jump ahead to the
preparations for [Breathing clouds](#breathing-clouds).

### Building with packages from OBS

We now want to build an image with our new package included. For that, add the
download repository to your kiwi .xml repository list. To determine the link,
click on "SLE_12_SP3" in the build result table on the right side of the screen.
Then click on "Go to download repository". If you get a 404 error it just means
the build has not finished yet.

Now build your image locally with the OBS built binary included. Boot it and try
to run moon-buggy. Enjoy it for a few minutes.

### Breathing clouds

Let's move everything into OBS to leverage the full power of it.

For that, create an "images" repository. In the Web UI, select "Meta". Here,
add an image repository definition:

    <repository name="images">
      <path project="home:<your_user_name>:branches:home:cwh" repository="SLE_12_SP3"/>
      <arch>x86_64</arch>
      <arch>aarch64</arch>
    </repository>

Press "Save".

Go to "Project Config". Add the following snippet:

    %if "%_repository" == "images"
    Type: kiwi
    Repotype: staticlinks
    Patterntype: none
    Prefer: sles-release
    %endif

    Conflict: kiwi:libudev-mini1
    Conflict: kiwi:systemd-mini
    Conflict: libudev1:udev-mini
    Conflict: udev:libudev-mini1
    Conflict: udev-mini-devel:udev

    Conflict: systemd:libsystemd0-mini
    Conflict: systemd-mini-devel:systemd

    Prefer: ksh

    Substitute: kiwi-filesystem:ext4 e2fsprogs
    Prefer: !kiwi
    Prefer: !kiwi-desc-oemboot-requires
    Prefer: !kiwi-requires
    Prefer: python2-kiwi
    Prefer: kiwi-boot-require

    Preinstall: jing 

Now select "Create package" from the Overview tab and call it
"moon_buggy_image". Save changes. Add config.kiwi, config.sh and
cloud-cfg-swapfile.tgz from your local image source directory.

> (tip: You can use the osc command line tool to add files easier than with the
> Web UI. You will need to run a "co" on the package, copy all files in, run
> "addremove", then "ci".)

The config.kiwi file now still contains local URLs for its repositories
which can not be used from OBS. However, OBS already knows all repositories
we want to build against, so we can just reuse its internal logic. For that,
replace all repository tags in config.kiwi with this single snippet:

    <repository type="rpm-md">
        <source path="obsrepositories:/"/>
    </repository>

Now that all files are in OBS, wait for the image build to finish.

In this setup, every change to the sources of the moon-buggy package will
automatically spawn a build of the image once the package build is done. The
same is true for inter-package dependencies.

When the build is done, try to grab the image from the server and verify it
works.

All of the build service pieces you used can be hosted on-site at your facility
as well. There is nothing that binds you to the publicly hosted OBS version.

Congratulations, you can now dive into the wonderful world of image building
with kiwi!
