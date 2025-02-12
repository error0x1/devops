Разберем установку Docker

Обновите систему
```bash
sudo apt update && sudo apt upgrade -y
```

 Установите необходимые зависимости
Установите пакеты, которые позволят использовать репозиторий Docker через HTTPS:

```bash
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
```

Настройте репозиторий Docker
Добавьте репозиторий Docker в список источников APT:

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

> Примечание : Команда $(lsb_release -cs) автоматически определяет кодовое имя вашего дистрибутива (например, bookworm для Debian 12). Если команда не работает, замените её на bookworm. 

Обновите список пакетов и установите Docker
После добавления репозитория обновите список доступных пакетов и установите Docker и связанные с ним пакеты:
```bash
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
```

Проверьте установку
Проверьте, что Docker установлен корректно:
```bash
sudo docker --version
```
Пример вывода:
```bash
Docker version 24.0.5, build 12345678
```

Также можно запустить тестовый контейнер:
```bash
sudo docker run hello-world
```

Добавьте пользователя в группу docker
По умолчанию команды Docker требуют прав суперпользователя (sudo). Чтобы избежать этого, добавьте своего пользователя в группу docker:
```bash
sudo usermod -aG docker $USER
```

После этого перезагрузите систему или выполните:
```bash
newgrp docker
```

Проверьте статус службы Docker
Убедитесь, что служба Docker запущена:
```bash
sudo systemctl status docker
```
Пример вывода:
```bash
● docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
     Active: active (running) since ...
```

Настройте автозапуск Docker
Чтобы Docker запускался автоматически при загрузке системы:
```bash
sudo systemctl enable docker
```