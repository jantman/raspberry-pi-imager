source "arm-image" "raspberry_pi_os_32bit" {
    iso_url                   = "https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2023-10-10/2023-10-10-raspios-bookworm-armhf-lite.img.xz"
    iso_checksum              = "sha256:1f8a646b375b198ef9f48c940889ac9f61744d1c1105b36c578313edbc81a339"
    last_partition_extra_size = 268435456
    output_filename           = "2023-10-10-raspios-bookworm-armhf-lite_custom.img"
}

build {
    sources = ["source.arm-image.raspberry_pi_os_32bit"]

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

    # script to write system info to tty1 if nobody is logged in there
    provisioner "file" {
        destination = "/usr/local/bin/tty1_system_info"
        source      = "tty1_system_info.sh"
    }

    # cron.d file to trigger script every minute
    provisioner "file" {
        destination = "/etc/cron.d/tty1_system_info"
        content     = "* * * * * root /usr/local/bin/tty1_system_info\n"
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
            "chmod 0755 /usr/local/bin/tty1_system_info",
            "chmod 0644 /etc/cron.d/tty1_system_info",
            "chmod 0700 /root/configure-pi.sh",
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
        output         = "2023-10-10-raspios-bookworm-armhf-lite_custom.img.sha256sum"
        checksum_types = ["sha256"]
    }
    post-processor "compress" {
        output              = "2023-10-10-raspios-bookworm-armhf-lite_custom.img.tar.gz"
        compression_level   = 9
        keep_input_artifact = true
    }
}
