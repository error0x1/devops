---
- hosts: monitoring
  become: true
  roles:
    - install_grafana
