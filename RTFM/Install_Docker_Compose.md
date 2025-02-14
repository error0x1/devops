Установка **Docker Compose** зависит от вашей операционной системы. Вот пошаговые инструкции для разных платформ:

---

### **1. Установка Docker Compose на Linux**

#### **Шаг 1: Убедитесь, что Docker установлен**
Перед установкой Docker Compose убедитесь, что Docker уже установлен и работает:
```bash
docker --version
```
Если Docker не установлен, следуйте официальной инструкции: [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/).

---

#### **Шаг 2: Скачайте Docker Compose**
1. Скачайте последнюю версию Docker Compose:
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   ```
   > Замените `v2.21.0` на последнюю стабильную версию с [официальной страницы релизов](https://github.com/docker/compose/releases).

2. Сделайте файл исполняемым:
   ```bash
   sudo chmod +x /usr/local/bin/docker-compose
   ```

---

#### **Шаг 3: Проверьте установку**
Проверьте, что Docker Compose установлен корректно:
```bash
docker-compose --version
```
Пример вывода:
```plaintext
docker-compose version v2.21.0
```

---

#### **Шаг 4 (опционально): Создайте символическую ссылку**
Если команда `docker-compose` недоступна, создайте символическую ссылку:
```bash
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

---

### **2. Установка Docker Compose на macOS**

#### **Способ 1: Через Docker Desktop**
1. Установите Docker Desktop для macOS:
   - Скачайте установщик с официального сайта: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop).
   - Установите Docker Desktop.
2. Docker Compose входит в состав Docker Desktop и автоматически доступен.

---

#### **Способ 2: Установка через Homebrew**
1. Убедитесь, что Homebrew установлен:
   ```bash
   brew --version
   ```
   Если нет, установите его:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Установите Docker Compose:
   ```bash
   brew install docker-compose
   ```

3. Проверьте установку:
   ```bash
   docker-compose --version
   ```

---

### **3. Установка Docker Compose на Windows**

#### **Способ 1: Через Docker Desktop**
1. Установите Docker Desktop для Windows:
   - Скачайте установщик с официального сайта: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop).
   - Установите Docker Desktop.
2. Docker Compose входит в состав Docker Desktop и автоматически доступен.

---

#### **Способ 2: Установка вручную**
1. Скачайте бинарный файл Docker Compose:
   - Перейдите на страницу релизов: [https://github.com/docker/compose/releases](https://github.com/docker/compose/releases).
   - Скачайте версию для Windows (например, `docker-compose-Windows-x86_64.exe`).

2. Переместите файл в директорию, доступную в PATH:
   - Например, переместите файл в `C:\Windows\System32\`.

3. Переименуйте файл в `docker-compose.exe`.

4. Проверьте установку:
   ```cmd
   docker-compose --version
   ```

---

### **4. Установка Docker Compose как плагин Docker CLI (v2 и выше)**

Начиная с Docker Compose v2, он доступен как плагин Docker CLI (`docker compose` вместо `docker-compose`).

#### **Шаг 1: Установите плагин**
1. Скачайте плагин:
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
   ```

2. Сделайте файл исполняемым:
   ```bash
   sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
   ```

---

#### **Шаг 2: Проверьте установку**
Проверьте, что плагин работает:
```bash
docker compose version
```

---

### **5. Обновление Docker Compose**
Если Docker Compose уже установлен, обновите его до последней версии:
1. Удалите старую версию:
   ```bash
   sudo rm /usr/local/bin/docker-compose
   ```

2. Скачайте и установите новую версию, как описано выше.

---

### **6. Удаление Docker Compose**
Если нужно удалить Docker Compose:
```bash
sudo rm /usr/local/bin/docker-compose
```

---

Теперь вы знаете, как установить Docker Compose на любой платформе! Если возникнут вопросы или проблемы, уточните детали, чтобы я мог помочь.