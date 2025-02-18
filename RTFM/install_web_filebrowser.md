Сегодня мы с вами запустим продукт https://filebrowser.org/ в Docker Compose

Для установки **FileBrowser** с использованием **Docker Compose**, создадим файл `docker-compose.yml`, который описывает контейнер и его настройки.

---

### **1. Создайте файл `docker-compose.yml`**

Создайте файл с именем `docker-compose.yml` и добавьте в него следующее содержимое:

```yaml
version: "3.8"

services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    ports:
      - "8080:80" # Проброс порта хоста на контейнер (8080 -> 80)
    volumes:
      - ./data:/srv # Корневая директория для FileBrowser
      - ./filebrowser.db:/database/filebrowser.db # База данных FileBrowser
      - ./settings.json:/config/settings.json # Конфигурационный файл
    environment:
      - PUID=1000 # ID пользователя (замените на ваш UID)
      - PGID=1000 # ID группы (замените на ваш GID)
    restart: unless-stopped # Политика перезапуска
```

---

### **2. Объяснение ключевых параметров**

1. **`image: filebrowser/filebrowser:latest`**:
   - Используется официальный образ FileBrowser из Docker Hub.

2. **`ports`**:
   - Пробрасывает порт `8080` на хосте к порту `80` внутри контейнера.
   - Вы сможете получить доступ к FileBrowser через браузер по адресу: `http://localhost:8080`.

3. **`volumes`**:
   - `./data:/srv`: Монтирует локальную папку `./data` как корневую директорию для FileBrowser.
   - `./filebrowser.db:/database/filebrowser.db`: Монтирует базу данных FileBrowser.
   - `./settings.json:/config/settings.json`: Монтирует конфигурационный файл.

4. **`environment`**:
   - `PUID` и `PGID` используются для запуска процессов внутри контейнера от имени определенного пользователя и группы.
   - Узнать свои `PUID` и `PGID` можно командой:
     ```bash
     id -u  # PUID
     id -g  # PGID
     ```

5. **`restart: unless-stopped`**:
   - Контейнер будет автоматически перезапускаться, если он остановится (кроме случаев ручной остановки).

---

### **3. Подготовка файлов и папок**

1. Создайте папку для проекта:
   ```bash
   mkdir filebrowser && cd filebrowser
   ```

2. Создайте необходимые файлы и папки:
   ```bash
   mkdir data
   touch filebrowser.db
   touch settings.json
   ```

3. Если у вас уже есть существующие данные или конфигурации, скопируйте их в соответствующие папки.

---

### **4. Запустите контейнер**

В той же директории, где находится `docker-compose.yml`, выполните команду:
```bash
docker-compose up -d
```

Флаг `-d` запускает контейнер в фоновом режиме.

---

### **5. Проверьте работу FileBrowser**

Откройте браузер и перейдите по адресу:
```
http://localhost:8080
```

По умолчанию:
- Логин: `admin`
- Пароль: `admin`

После входа обязательно измените пароль в настройках.

---

### **6. Дополнительные настройки**

#### **Настройка HTTPS**
Если вы хотите использовать HTTPS, вы можете:
1. Настроить обратный прокси (например, с помощью Nginx или Traefik).
2. Или использовать Let's Encrypt для автоматической генерации SSL-сертификатов.

Пример настройки Nginx:
```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /path/to/your/cert.pem;
    ssl_certificate_key /path/to/your/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

### **7. Остановка и удаление контейнера**

Если нужно остановить контейнер:
```bash
docker-compose down
```

Если нужно удалить контейнер вместе с данными:
```bash
docker-compose down -v
```

---

Теперь FileBrowser установлен и работает через Docker Compose.
