#cloud-config

package_update: true

users:
  - default
  - name: proxy
    groups: [sudo]
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    shell: /bin/bash

packages:
  - curl
  - iptables

write_files:
  - path: /etc/sysctl.d/99-tailscale.conf
    owner: root:root
    permissions: "0644"
    content: |
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.forwarding = 1
      net.core.rmem_max = 2500000
      net.core.wmem_max = 2500000
      net.core.default_qdisc = fq
      net.ipv4.tcp_congestion_control = bbr

runcmd:
  - sysctl --system
  - iptables -I INPUT -p udp --dport 41641 -j ACCEPT
  - ip6tables -I INPUT -p udp --dport 41641 -j ACCEPT
  - curl -fsSL https://tailscale.com/install.sh | sh
  - systemctl enable --now tailscaled
  - sleep 5
  - tailscale up --authkey=${tailscale_auth_key} --advertise-exit-node --ssh --hostname=${hostname}
