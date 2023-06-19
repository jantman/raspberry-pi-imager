variable "wifi_name" {
    type = string
}

variable "wifi_password" {
    type = string
}

variable "default_username" {
    type = string
}

variable "default_password" {
    type = string
}

variable "sha" {
    type        = string
    description = "git SHA"
}

variable "repo" {
    type        = string
    description = "git repo URL"
}
