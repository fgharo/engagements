pid_file = "/tmp/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
            role = "example"
        }
    }
    sink "file" {
        config = {
            path = "/tmp/.vault-token"
            mode = 0777
        }
    }
}

template {
    source = "/tmp/application.properties"
    destination = "/deployments/config/application.properties"

}