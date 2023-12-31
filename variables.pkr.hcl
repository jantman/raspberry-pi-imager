variable "wifi_name" {
    type = string
}

variable "wifi_password" {
    type = string
}

variable "default_username" {
    type    = string
    default = "pi"
}

variable "default_password" {
    type = string
    validation {
        condition     = can(regex("^\\$6\\$", var.default_password))
        error_message = "The default_password must be encrypted with openssl, i.e.: echo 'YourPassword' | openssl passwd -6 -stdin."
    }
}

variable "sha" {
    type        = string
    description = "git SHA"
}

variable "repo" {
    type        = string
    description = "git repo URL"
}

variable "release" {
    type        = string
    description = "github release name, or local"
    default     = "local"
}
