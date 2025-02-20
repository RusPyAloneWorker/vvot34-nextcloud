resource "local_file" "ansible_cfg" {
  filename = "${path.module}/ansible.cfg"
  content  = <<-EOT
    [defaults]
    allow_world_readable_tmpfiles = True
  EOT
}

resource "local_file" "hosts" {
  filename = "${path.module}/hosts"
  content  = <<-EOT
    server ansible_host=${yandex_compute_instance.server.network_interface[0].nat_ip_address} ansible_user=ubuntu ansible_connection=ssh
  EOT
}

resource "null_resource" "run_ansible" {
  depends_on = [local_file.ansible_cfg, local_file.hosts, yandex_compute_instance.server]

  provisioner "local-exec" {
    command = "ansible-playbook --become --become-user root --become-method sudo -i ${path.module}/hosts main-server.yaml"
    
    environment = {
      ANSIBLE_CONFIG = "${path.module}/ansible.cfg"
    }
  }
}