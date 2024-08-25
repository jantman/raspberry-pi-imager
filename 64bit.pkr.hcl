source "arm-image" "raspberry_pi_os_64bit" {
    iso_url                   = "https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-07-04/2024-07-04-raspios-bookworm-arm64-lite.img.xz"
    iso_checksum              = "sha256:43d150e7901583919e4eb1f0fa83fe0363af2d1e9777a5bb707d696d535e2599"
    last_partition_extra_size = 268435456
    output_filename           = "2024-07-04-raspios-bookworm-arm64-lite_custom.img"
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

    # setup WiFi - copied from what rpi-imager does
    provisioner "file" {
        destination = "/boot/firstrun.sh"
        content     = <<-EOS
        #!/bin/bash

        set +e

        if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
        /usr/lib/raspberrypi-sys-mods/imager_custom set_wlan '${var.wifi_name}' '${var.wifi_password}' 'US'
        else
        cat >/etc/wpa_supplicant/wpa_supplicant.conf <<'WPAEOF'
        country=US
        ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
        ap_scan=1

        update_config=1
        network={
            ssid="${var.wifi_name}"
            psk="${var.wifi_password}"
        }

        WPAEOF
        chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
        rfkill unblock wifi
        for filename in /var/lib/systemd/rfkill/*:wlan ; do
            echo 0 > $filename
        done
        fi
        rm -f /boot/firstrun.sh
        sed -i 's| systemd.run.*||g' /boot/cmdline.txt
        exit 0
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
            "chmod 0755 /boot/firstrun.sh",
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
            # handle initial configuration the way rpi-imager does
            "sed -i 's|$| cfg80211.ieee80211_regdom=US systemd.run=/boot/firstrun.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target|' /boot/cmdline.txt"
        ]
        inline_shebang = "/bin/sh -ex"
    }
    post-processor "checksum" {
        output         = "2024-07-04-raspios-bookworm-arm64-lite_custom.img.sha256sum"
        checksum_types = ["sha256"]
    }
    post-processor "compress" {
        output              = "2024-07-04-raspios-bookworm-arm64-lite_custom.img.tar.gz"
        compression_level   = 9
        keep_input_artifact = true
    }
}
