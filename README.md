# raspberry-pi-imager

[![Project Status: Inactive – The project has reached a stable, usable state but is no longer being actively developed; support/maintenance will be provided as time allows.](https://www.repostatus.org/badges/latest/inactive.svg)](https://www.repostatus.org/#inactive)

An example/template for baking a base Raspberry Pi image using [Packer](https://www.packer.io/) and pre-seeding a script for further customization.

## Why and What?

I've got a bunch of Raspberry Pis, as does a local non-profit that I work with. Setting up a new Pi involves a lot of identical steps to get the image ready, and then some device-specific steps to set the hostname, generate SSH keys, etc. Frankly, all of this is a pain, especially when you're setting up a bunch of Pis or something goes wrong and you want to re-image. This repo is intended to reduce much of that work.

We use [HashiCorp Packer](https://www.packer.io/) and the [ARM image plugin](https://github.com/solo-io/packer-plugin-arm-image) to download an official Raspberry Pi OS image and then add in our own customizations, such as WiFi configuration, timezone, locale, default username/password, etc. As opposed to just mounting the image and adding files to it, the ARM image plugin uses `qemu-arm-static` emulation and a [chroot](https://en.wikipedia.org/wiki/Chroot) into the image to allow us run native commands inside the Pi OS such as `apt install` and `raspi-config`.

The final step of customization is seeding a customization script into the image. Once the image is written to a SD card and put in a Pi, this script will be run interactively as root to perform the device-specific customization.

## Getting Started (Forking)

1. Fork this repository to a **private** repository.
2. Configure as described in [Configuration](#configuration), below.

## Usage

1. Obtain the newest base image, either via the "Releases" for this repository (if used) or via [Building Locally](#locally).
   * If downloading from GitHub Releases, be sure to download both the `.img.tar.gz` and `.img.sha256sum` files. First extract the image (`tar -xzvf 2023-05-03-raspios-bullseye-arm64-lite_custom.img.tar.gz`) and then verify its checksum (`sha256sum -c 2023-05-03-raspios-bullseye-arm64-lite_custom.img.sha256sum`).
2. Plug a SD card into your computer and note the device (``/dev/sdX`` in the next step) that it's assigned to (i.e. via `sudo dmesg`).
3. Write the image from Step 1 (``foo.img`` in this example) to the SD card: ``sudo dd if=foo.img of=/dev/sdX bs=4M conv=fsync status=progress``
4. Put the SD card in the Pi and boot it up. Either watch the on-screen output or your network's DHCP server to find its IP address.
5. SSH to the Pi with the default username and password (`pi:raspberry` in this repo) and `sudo su -` to root.
6. Run `./configure-pi.sh` to set the hostname, change (if desired) the password for the default user, create root SSH keys, and be prompted to update packages and reboot.
7. Follow your specific post-installation steps (such as adding the root SSH key to a private GitHub repo and configuring via Puppet).

## Configuration

Note that while Packer used JSON templates in early versions, it now uses HCL2 and certain new features _require_ HCL templates. See [HCL Templates | Packer](https://developer.hashicorp.com/packer/docs/templates/hcl_templates) for more information.

For configuring the WiFi SSID and passphrase, default username and password, and other variables in the `.pkr.hcl` files:

* **If building locally,** copy [variables.auto.pkrvars.EXAMPLE.hcl](variables.auto.pkrvars.EXAMPLE.hcl) to `variables.auto.pkrvars.hcl` and edit its content. Note that this file is in [.gitignore](.gitignore) by default.
* **If building via GitHub Actions**, define [repository secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) with the appropriate names for each required variable: ``PKR_VAR_wifi_name``, ``PKR_VAR_wifi_password``, ``PKR_VAR_default_username`` and ``PKR_VAR_default_password``.

## Building Base Images

The first step is to build a base image, which will be written to the SD card for every Pi we manage. This can either be done locally, or via [GitHub Actions](https://docs.github.com/en/actions) automatically every time the repository is changed and then saved as a Release on the repository. The latter is recommended as it will preserve the image in one central place (GitHub Releases), but note that this should **only be used on private repositories**.

### GitHub Actions

**IMPORTANT: ONLY USE ON PRIVATE REPOSITORIES!** This will expose your Pi username/password, WiFi SSID and passphrase, and everything else in the image to anyone who can access the repository. This is ONLY recommended for private repos!

Just push a new commit to the repo and it will be built. If it's on the `main` branch, it will be uploaded as a Release.

### Locally

To build locally with Docker, run `./build_docker.sh` which is based on the example in the [packer-plugin-arm-image README](https://github.com/solo-io/packer-plugin-arm-image#running-with-docker) with slight modifications. **NOTE** that `./packer_cache/` will contain root-owned files.
