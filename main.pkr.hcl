packer {
    required_version = ">= 1.7.0, <2.0.0"
    required_plugins {
        arm-image = {
            source  = "github.com/solo-io/arm-image"
            version = ">= 0.0.1"
        }
    }
}
