---
- hosts: monitoring_new
  become: true
  roles:
    - install_grafana
