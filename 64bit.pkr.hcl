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
            "echo \"REPO='${var.repo}'\" > /etc/image_version",
            "echo \"SHA='${var.sha}'\" >> /etc/image_version"
        ]
    }
    provisioner "shell" {
        inline = ["touch /boot/ssh"]
    }
    provisioner "shell" {
        inline = ["wpa_passphrase \"${var.wifi_name}\" \"${var.wifi_password}\" | sed -e 's/#.*$//' -e '/^$/d' >> /etc/wpa_supplicant/wpa_supplicant.conf"]
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
