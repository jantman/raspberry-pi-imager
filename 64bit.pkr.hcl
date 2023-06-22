packer {
    required_version = ">= 1.7.0, <2.0.0"
    required_plugins {
        arm-image = {
            source  = "github.com/solo-io/arm-image"
            version = ">= 0.0.1"
        }
    }
}

source "arm-image" "raspberry_pi_os_64bit" {
    iso_url                   = "https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2023-05-03/2023-05-03-raspios-bullseye-arm64-lite.img.xz"
    iso_checksum              = "sha256:bf982e56b0374712d93e185780d121e3f5c3d5e33052a95f72f9aed468d58fa7"
    last_partition_extra_size = 268435456
    output_filename           = "2023-05-03-raspios-bullseye-arm64-lite_custom.img"
    qemu_binary               = "qemu-aarch64-static"
}

build {
    sources = ["source.arm-image.raspberry_pi_os_64bit"]

    #########################################################
    # NOTE: file provisioners - be sure to chmod afterwards #
    #########################################################
    provisioner "file" {
        destination = "/etc/image_version"
        content     = <<-EOS
        IMAGE_REPO='${var.repo}'
        IMAGE_SHA='${var.sha}'
        IMAGE_RELEASE='${var.release}'
        EOS
    }

    # default user configuration
    provisioner "file" {
        destination = "/boot/userconf"
        content     = "${var.default_username}:${var.default_password}"
    }

    # set WiFi credentials - NOTE that `raspi-config nonint do_wifi_ssid_passphrase` doesn't work in a chroot
    provisioner "file" {
        destination = "/etc/wpa_supplicant/wpa_supplicant.conf"
        content     = <<-EOS
        # put in place by ${var.repo}
        ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
        update_config=1
        country=US

        network={
            ssid="${var.wifi_name}"
            psk="${var.wifi_password}"
        }
        EOS
    }

    # agetty restart every 60 seconds to show new /etc/issue.d files
    provisioner "file" {
        destination = "/etc/systemd/system/getty@tty1.service.d/restart.conf"
        content     = <<-EOS
        # put in place by ${var.repo}
        [Service]
        # the VT is cleared by TTYVTDisallocate
        # The '-o' option value tells agetty to replace 'login' arguments with an
        # option to preserve environment (-p), followed by '--' for safety, and then
        # the entered username.
        ExecStart=
        ExecStart=-/sbin/agetty -o '-p -- \\u' --noclear --timeout 60 %I $TERM
        EOS
    }

    # script to generate /etc/issue.d/rpi-image.issue
    provisioner "file" {
        destination = "/usr/local/bin/generate-rpi-image-issue"
        source      = "generate-rpi-image-issue.sh"
    }

    # cron.d file to trigger script every minute
    provisioner "file" {
        destination = "/etc/cron.d/rpi_imager"
        content     = "* * * * * root /usr/local/bin/generate-rpi-image-issue\n"
    }

    # script to configure Pi after boot
    provisioner "file" {
        destination = "/root/configure-pi.sh"
        source      = "configure-pi.sh"
    }

    provisioner "shell" {
        inline = ["install -d -m 0700 -o root -g root /root/.ssh"]
    }

    # root .ssh/config for github
    provisioner "file" {
        destination = "/root/.ssh/config"
        source      = "ssh-config"
    }

    provisioner "shell" {
        inline = [
            "chmod 0644 /etc/image_version",
            "chmod 0600 /etc/wpa_supplicant/wpa_supplicant.conf",
            "chmod 0644 /etc/systemd/system/getty@tty1.service.d/restart.conf",
            "chmod 0755 /usr/local/bin/generate-rpi-image-issue",
            "chmod 0644 /etc/cron.d/rpi_imager",
            "chmod 0700 /root/configure-pi.sh",
            "install -d -m 0755 -o root -g root /etc/issue.d",
            # enable SSH
            "touch /boot/ssh",
            # set hostname
            "raspi-config nonint do_hostname custom-pi-${var.sha}",
            # set locale
            "raspi-config nonint do_change_locale en_US.UTF-8",
            # set timezone
            "raspi-config nonint do_change_timezone America/New_York",
            # text console, no autologin
            "raspi-config nonint do_boot_behaviour B1",
            # wait for network at boot
            "raspi-config nonint do_boot_wait 0",
            # set WiFi country
            "raspi-config nonint do_wifi_country US",
            # disable rfkill
            "bash -c 'for filename in /var/lib/systemd/rfkill/*:wlan ; do [[ -e \"$filename\" ]] && echo 0 > \"$filename\"; done'",
            # disable prompt to run raspi-config after boot
            "raspi-config nonint disable_raspi_config_at_boot",
            # install dependencies
            "DEBIAN_FRONTEND=noninteractive apt install -y puppet git r10k vim",
        ]
        inline_shebang = "/bin/sh -ex"
    }
    post-processor "checksum" {
        output         = "2023-05-03-raspios-bullseye-arm64-lite_custom.img.sha256sum"
        checksum_types = ["sha256"]
    }
    post-processor "compress" {
        output              = "2023-05-03-raspios-bullseye-arm64-lite_custom.img.tar.gz"
        compression_level   = 9
        keep_input_artifact = true
    }
}
