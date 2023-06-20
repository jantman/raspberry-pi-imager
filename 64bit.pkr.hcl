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

    provisioner "shell" {
        inline = [
            # write repo and sha to /etc/image_version file
            "echo \"IMAGE_REPO='${var.repo}'\" > /etc/image_version",
            "echo \"IMAGE_SHA='${var.sha}'\" >> /etc/image_version",
            "echo \"IMAGE_RELEASE='${var.release}'\" >> /etc/image_version",
            # enable SSH
            "touch /boot/ssh",
            # set default user and password
            "echo '${var.default_username}:${var.default_password}' > /boot/userconf",
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
            # set WiFi credentials - NOTE that `raspi-config nonint do_wifi_ssid_passphrase` doesn't work in a chroot
            "echo 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev' > /etc/wpa_supplicant/wpa_supplicant.conf",
            "echo 'update_config=1' >> /etc/wpa_supplicant/wpa_supplicant.conf",
            "echo 'country=US' >> /etc/wpa_supplicant/wpa_supplicant.conf",
            "echo '' >> /etc/wpa_supplicant/wpa_supplicant.conf",
            "echo 'network={' >> /etc/wpa_supplicant/wpa_supplicant.conf",
            "echo '    ssid=\"${var.wifi_name}\"' >> /etc/wpa_supplicant/wpa_supplicant.conf",
            "echo '    psk=\"${var.wifi_password}\"' >> /etc/wpa_supplicant/wpa_supplicant.conf",
            "echo '}' >> /etc/wpa_supplicant/wpa_supplicant.conf",
            # disable prompt to run raspi-config after boot
            "raspi-config nonint disable_raspi_config_at_boot",
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
