# Подготовка системы
Выполняется на всех узлах master и work-нодах.

1. Перво на перво обновить. Система должна быть всегда обновлена максимально:
    ```bash
    sudo apt update
    sudo apt -y full-upgrade
    [ -f /var/run/reboot-required ] && sudo reboot -f
    ```

2. Установка сопутствующих пакетов:
    ```bash
    sudo apt install -y curl apt-transport-https gpg vim git
    ```

3. Необходимо отключить своп:
    ```bash
    sudo swapoff -a
    ```

4. Проверка:
    ```bash
    free -h
    ```
    Пример вывода:
    ```
                   total        used        free      shared  buff/cache   available
    Mem:           1,6Gi       481Mi       315Mi       1,3Mi       1,0Gi       1,1Gi
    Swap:          975Mi          0B       975Mi
    ```

5. Далее комментируем запись в `/etc/fstab`:
    ```bash
    sudo vim /etc/fstab
    ```
    Добавить комментарий:
    ```
    #UUID=3589935bj3333-39u4bb-24234343	none	swap	sw	0	0
    ```

6. Активируем необходимые модули ядра:
    ```bash
    sudo tee /etc/modules-load.d/k8s.conf <<EOF
    overlay
    br_netfilter
    EOF
    ```

7. Включаем IP-пересылку, чтобы позволить подам общаться друг с другом, а также пересылать трафик наружу:
    ```bash
    echo 1 > /proc/sys/net/ipv4/ip_forward #из под root
    ```

8. Включаем модули ядра:
    ```bash
    sudo modprobe overlay
    sudo modprobe br_netfilter
    ```

9. Измените файл как показано ниже:
    ```bash
    sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    EOF
    ```

10. Перечитываем настройки:
    ```bash
    sudo sysctl --system
    ```

## 2. Install Kubeadm Bootstrapping tool
Выполняется на всех узлах master и work-нодах.

1. Добавление репозитория Kubernetes. Импортируем ключ:
    ```bash
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    ```

2. Добавляем репозиторий:
    ```bash
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    ```

3. Обновляем пакетную базу:
    ```bash
    sudo apt update
    ```

4. Установим необходимые нам тулзы `kubectl`, `kubeadm` и `kubelet`:
    ```bash
    sudo apt install -y wget kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    ```

5. Проверка инсталляции:
    ```bash
    kubectl version --client && kubeadm version
    ```
    Пример вывода:
    ```
    Client Version: v1.28.2
    Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
    kubeadm version: &version.Info{Major:"1", Minor:"28", GitVersion:"v1.28.2", GitCommit:"89a4ea3e1e4ddd7f7572286090359983e0387b2f", GitTreeState:"clean", BuildDate:"2023-09-13T09:34:32Z", GoVersion:"go1.20.8", Compiler:"gc", Platform:"linux/amd64"}
    ```

## 3. Install and Configure Container Runtime
Выполняется на всех узлах master и work-нодах.

1. Ставим Docker. Добавляем репу Docker и ключ:
    ```bash
    OS=Debian_12
    CRIO_VERSION=v1.32
    cat <<EOF | tee /etc/yum.repos.d/cri-o.repo
    [cri-o]
    name=CRI-O
    baseurl=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/
    enabled=1
    gpgcheck=1
    gpgkey=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/repodata/repomd.xml.key
    EOF
    ```

2. Установка Docker:
    ```bash
    sudo apt-get install -y cri-o cri-o-runc
    ```

3. Убедитесь, что служба запущена и включена:
    ```bash
    sudo systemctl enable crio
    sudo systemctl start crio
    sudo systemctl status crio
    ```

## 4. Initialize the Control Plane
Выполняется на master-ноде.

1. Убедимся, что модули загружены верно:
    ```bash
    lsmod | grep br_netfilter
    ```
    Пример вывода:
    ```
    br_netfilter           32768  0
    bridge                311296  1 br_netfilter
    ```

2. Активируем `kubelet`:
    ```bash
    sudo systemctl enable kubelet
    ```

3. Следующее, что нужно сделать, — загрузить все необходимые образы контейнеров на главный узел:
    ```bash
    sudo kubeadm config images pull
    ```

4. Начальная инициация кластера:
    ```bash
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --dry-run
    ```
    Обратите внимание на вывод команды:
    ```
    kubeadm join 172.22.1.12:6443 --token c4sog1.m1ovrecybyl3jpcc \
        --discovery-token-ca-cert-hash sha256:1d16678e3952fdc0b89730a286e091907e01b8a0f31fd83fe77131c3270baa8f
    ```
    Запомните это — это пригодится нам в будущем для добавления нод воркеров.

5. Сконфигурируем `kubectl`. Выполнять из под целевого для управления пользователя:
    ```bash
    mkdir -p $HOME/.kube
    sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

6. Проверим информацию кластера:
    ```bash
    kubectl cluster-info
    ```

## 5. Install and Configure the Network Plugin
Выполняется на master-ноде.

Установим плагин `flannel`:
1. Скачаем манифест:
    ```bash
    wget https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    ```

2. Применяем наш манифест:
    ```bash
    kubectl apply -f kube-flannel.yml
    ```
    Пример вывода:
    ```
    namespace/kube-flannel created
    clusterrole.rbac.authorization.k8s.io/flannel created
    clusterrolebinding.rbac.authorization.k8s.io/flannel created
    serviceaccount/flannel created
    configmap/kube-flannel-cfg created
    daemonset.apps/kube-flannel-ds created
    ```

3. Проверяем работу пода `flannel`:
    ```bash
    kubectl get pods -n kube-flannel
    ```
    Пример вывода:
    ```
    NAME                    READY   STATUS    RESTARTS   AGE
    kube-flannel-ds-w2gbk   1/1     Running   0          103s
    ```

4. Проверяем, что наша мастер нода запущена:
    ```bash
    kubectl get nodes -o wide
    ```
    Пример вывода:
    ```
    NAME        STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
    main-core   Ready    control-plane   19m   v1.28.2   172.22.1.94   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-13-amd64   docker://24.0.7
    ```

## 6. Add worker nodes to the Cluster
1. Если у вас кластер состоит из нескольких нод, то добавьте их таким образом. На каждой ноде нужно выполнить данную команду:
    ```bash
    sudo kubeadm join 172.22.1.12:6443 --token f0pj7p.sz449hol1o1ycs7y \
        --discovery-token-ca-cert-hash sha256:fea5cc967114667a7c501a12a6f9b6244c9ff87c052d41c9989570b08724bc72
    ```

2. Проверим, что все ноды работают:
    ```bash
    kubectl get nodes -o wide
    ```
    Пример вывода:
    ```
    NAME             STATUS   ROLES           AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
    node-master      Ready    control-plane   105m   v1.28.2   172.22.1.12   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-13-amd64   containerd://1.6.25
    node-worker-01   Ready    <none>          29m    v1.28.2   172.22.1.14   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-13-amd64   containerd://1.6.25
    node-worker-02   Ready    <none>          28m    v1.28.2   172.22.1.15   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-13-amd64   containerd://1.6.25
    ```

## 7. Using Kubernetes Cluster
Выполняется на master-ноде.

1. Попробуем протестировать наш кластер и добавим тестовый под:
    ```bash
    kubectl apply -f https://k8s.io/examples/pods/commands.yaml
    ```

2. Проверим работу тестового пода:
    ```bash
    kubectl get pods
    ```
    Пример вывода:
    ```
    NAME           READY   STATUS      RESTARTS   AGE
    command-demo   0/1     Completed   0          8s
    ```

## 8. Установка Metrics Server на Kubernetes Cluster
Выполняется на master-ноде.

1. Скачиваем манифест файл:
    ```bash
    wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -O metrics-server-components.yaml
    ```

2. Применяем настройки:
    ```bash
    kubectl apply -f metrics-server-components.yaml
    ```

3. Проверяем настройку Metrics Server:
    ```bash
    kubectl get deployment metrics-server -n kube-system
    ```

Если долгое время под не загружается:
    ```bash
    kubectl get deployment metrics-server -n kube-system
    ```
    Пример вывода:
    ```
    NAME             READY   UP-TO-DATE   AVAILABLE   AGE
    metrics-server   0/1     1            0           3m3s
    ```

А в логах подобная ошибка:
    ```bash
    kubectl logs metrics-server-fbb469ccc-ldc2b -n kube-system
    ```
    Пример вывода:
    ```
    E1205 08:47:15.952300       1 scraper.go:140] "Failed to scrape node" err="Get \"https://172.22.1.14:10250/metrics/resource\": x509: cannot validate certificate for 172.22.1.14 because it doesn't contain any IP SANs" node="node-worker-01"
    ```

Можно попробовать исправить ситуацию следующим образом:
1. На мастере:
    ```bash
    kubectl -n kube-system edit configmap kubelet-config
    ```

2. Добавить `serverTLSBootstrap: true` в секцию `kubelet`.

3. На каждой ноде:
    ```bash
    sudo nano /var/lib/kubelet/config.yaml
    ```
    Добавить вниз:
    ```
    serverTLSBootstrap: true
    ```

4. На мастере выполнить:
    ```bash
    sudo systemctl restart kubelet
    for kubeletcsr in `kubectl -n kube-system get csr | grep kubernetes.io/kubelet-serving | awk '{ print $1 }'`; do kubectl certificate approve $kubeletcsr; done
    ```

5. Проверка:
    ```bash
    kubectl logs -f -n kube-system `kubectl get pods -n kube-system | grep metrics-server | awk '{ print $1 }'`
    kubectl top pods --all-namespaces
    ```

## 9. Ставим Dashboard Kubernetes
Все действия выполняем на мастере.

1. Для удобства поставим Helm:
    ```bash
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    sudo apt-get install apt-transport-https --yes
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
    ```

2. Скачиваем дистрибутив, используя Helm:
    ```bash
    helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
    helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
    ```

3. Убеждаемся, что под задеплоен:
    ```bash
    kubectl get pods -n kubernetes-dashboard
    ```
    Пример вывода:
    ```
    NAME                                    READY   STATUS    RESTARTS   AGE
    kubernetes-dashboard-798dd48467-jzq8x   1/1     Running   0          3h50m
    ```

## 10. Создаем доступ к Dashboard

1. Заменим `clusterIP` на `NodePort`:
    ```bash
    kubectl patch svc -n kubernetes-dashboard kubernetes-dashboard -p '{"spec": {"type": "NodePort"}}'
    ```

2. Создать файл `dashboard.yml`:
    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: admin
      namespace: kubernetes-dashboard
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: admin
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: admin
      namespace: kubernetes-dashboard
    ```

3. Применить его:
    ```bash
    kubectl apply -f dashboard.yml
    ```

4. Получить токен входа в web UI:
    ```bash
    kubectl -n kubernetes-dashboard create token admin-user
    ```

## 11. Установка Grafana и Prometheus на Kubernetes

1. Скачиваем исходники:
    ```bash
    git clone https://github.com/prometheus-operator/kube-prometheus.git && cd kube-prometheus
    ```

2. Применяем конфиг файл:
    ```bash
    kubectl create -f manifests/setup
    kubectl create -f manifests/
    ```

3. Проверяем, что у нас все применилось, развернулось и запустилось:
    ```bash
    kubectl get ns monitoring
    ```
    Пример вывода:
    ```
    NAME         STATUS   AGE
    monitoring   Active   2m41s
    ```

    Смотрим состояние подов:
    ```bash
    kubectl get pods -n monitoring -w
    ```
    Пример вывода:
    ```
    NAME                                   READY   STATUS    RESTARTS        AGE
    alertmanager-main-0                    2/2     Running   0               3m8s
    alertmanager-main-1                    2/
