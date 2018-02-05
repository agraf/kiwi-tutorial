== Quick kiwi tutorial ==

Welcome to the really quick guide on how to create images with kiwi. This will
only teach you the basics, but will give you enough tooling so that the gaps are
easy to fill out using google or by asking friendly people you know.

Please adapt the URLs in the config.kiwi files in this directory with paths that
point to either your SMT server or local copies of the respective SLES or module
media.

= Step 1 =

Go to an x86 SLES12 SP3 host. Install the full KVM stack. Then follow the
README in the sles12_sp3_x86_jeos directory.

= Step 2 =

Go to an aarch64 SLES12 SP3 host. Install the full KVM stack. Then follow the
README in the sles12_sp3_aarch64_jeos directory.

= Step 3 =

diff -ru both directories. What are the differences between building an image
for x86_64 and aarch64?

= Step 4 =

Now that you know how irrelevant architectures are, concentrate on one ;).
Try to add a package to the image.

= Step 5 =

Try to add a package that also needs to get started on bootup (apache2 maybe?).
Then edit config.sh to automatically run the new service on boot.

= Step 6 =

Create an account on build.opensuse.org. Then run

  $ zypper in osc
  $ osc branch home:cwh/moon-buggy

Then go to build.opensuse.org, log in, select "Home Project" in the top right
corner, click on subprojects, select the newly added project. Go to
"Repositories". Remove all unneeded build targets.  Add SLES12 SP3 as target
distribution.

Unfortunately, OBS only builds for x86_64 by default (because that's where the
build of build power lies). Let's add a build for aarch64 as well. Go to
Advanced -> Meta and add a

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
preparations for Step 8.

= Step 7 =

We now want to build an image with our new package included. For that, add the
download repository to your kiwi .xml repository list. To determine the link,
click on "SLE_12_SP3" in the build result table on the right side of the screen.
Then click on "Go to download repository". If you get a 404 error it just means
the build hasnt finished yet.

Now build your image locally with the OBS built binary included. Boot it and try
to run moon-buggy. Enjoy it for a few minutes.

= Step 8 =

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

    Prefer: !kiwi
    Prefer: !kiwi-desc-oemboot-requires
    Prefer: !kiwi-requires
    Prefer: python2-kiwi
    Prefer: kiwi-boot-require

    Preinstall: jing 

Now select "Create package" from the Overview tab and call it
"moon_buggy_image". Save changes. Add all files from the local image repository,
but replace the list of repositories with a simple

        <repository type="rpm-md">
            <source path="obsrepositories:/"/>
        </repository>

(tip: You can use the osc command line tool to add files easier than with the
Web UI. You will need to run a "co" on the package, copy all files in, run
"addremove", then "ci".)

Now that all files are in, wait for the image build to finish.

In this setup, every change to the sources of the moon-buggy package will
automatically spawn a build of the image once the package build is done. The
same is true for inter-package dependencies.

Try to grab the image from the server and verify it works.

