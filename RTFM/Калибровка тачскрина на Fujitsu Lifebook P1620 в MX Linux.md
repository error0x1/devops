# Калибровка тачскрина на Fujitsu Lifebook P1620 в MX Linux
**Цель:** Это пошаговое руководство поможет вам откалибровать USB-тачскрин (Fujitsu Component USB Touch Panel Pen) на старом ноутбуке Fujitsu Lifebook P1620 под MX Linux (на базе Debian 12 "Bookworm"). Без калибровки касания могут попадать в углы или сбоить из-за raw HID-координат (0–16M). Мы используем libinput (драйвер по умолчанию) и специализированный инструмент xlibinput_calibrator, так как стандартный xinput_calibrator не всегда работает с libinput.

P1620 — legacy-устройство (Core Duo, GMA 950, 1–2 ГБ RAM), так что всё должно тянуть без лагов. Тестировано на MX Linux 23.6. Если у вас другой релиз, обновите систему: `sudo apt update && sudo apt upgrade`.

## Предварительные требования
1. **Проверьте устройство:**  
   Откройте терминал (Ctrl+Alt+T) и запустите:  
   ```
   xinput list | grep -i fujitsu
   ```  
   Должно показать:  
   ```
   Fujitsu Component USB Touch Panel Pen (0)    id=16    [slave  pointer  (2)]
   ```  
   (ID может варьироваться, запомните его — обычно 16). Если не видно — подключите USB-кабель тачскрина (если отсоединён) или проверьте `lsusb | grep Fujitsu`.

2. **Установите пакеты:**  
   Libinput уже должен стоять (проверьте: `dpkg -l | grep libinput`). Если нет:  
   ```
   sudo apt install xserver-xorg-input-libinput libinput-tools xinput
   ```  
   Для калибратора нужны dev-пакеты:  
   ```
   sudo apt install git libxi-dev libx11-dev build-essential txt2man x11-xserver-utils libxrandr-dev
   ```

3. **Сбросьте текущую матрицу:**  
   Чтобы избежать искажений:  
   ```
   xinput set-prop "Fujitsu Component USB Touch Panel Pen (0)" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
   ```  
   Или для libinput:  
   ```
   xinput set-prop "Fujitsu Component USB Touch Panel Pen (0)" "libinput Calibration Matrix" 1 0 0 0 1 0 0 0 1
   ```

## Установка xlibinput_calibrator
Стандартный `xinput_calibrator` (из `sudo apt install xinput-calibrator`) выдаёт min/max для evdev, а не матрицу для libinput — поэтому используем форк для libinput (GitHub: kreijack/xlibinput_calibrator).

1. **Клонируйте репозиторий:**  
   ```
   git clone https://github.com/kreijack/xlibinput_calibrator.git
   cd xlibinput_calibrator/src
   ```

2. **Скомпилируйте:**  
   ```
   make clean  # Очистка, если перезапуск
   make
   ```  
   Если ошибка с Xrandr.h (fatal error): Убедитесь, что `libxrandr-dev` установлен (см. выше). Если persists:  
   - Отредактируйте `Makefile` (`nano Makefile`): Удалите `-lXrandr` из LIBS/LDFLAGS.  
   - В `gui_x11.cc` (`nano gui_x11.cc`): Закомментируйте `#include <X11/extensions/Xrandr.h>` и блоки с XRR* (используйте fallback: return {1280, 768} для экрана P1620).  
   Пересоберите: `make clean && make`.

3. **Установите бинарник:**  
   ```
   sudo cp xlibinput_calibrator /usr/local/bin/
   cd ../..
   ```

## Калибровка тачскрина
1. **Проверьте устройства:**  
   ```
   xlibinput_calibrator --list-devices | grep -i fujitsu
   ```  
   Должно показать ваш тачскрин.

2. **Запустите калибровку:**  
   ```
   xlibinput_calibrator --show-xinput-cmd
   ```  
   - Экран заполнится крестиками в 4 углах (1280x768 по умолчанию).  
   - Коснитесь стилусом (или пальцем) **точно в центр** каждого крестика (не мышью!).  
   - Опции для точности:  
     - `--device-name="Fujitsu Component USB Touch Panel Pen (0)"` (если несколько устройств).  
     - `--threshold-misclick=50` (порог ошибки клика в пикселях; 0=выкл).  
     - `--monitor-nr=0` (для первого экрана).  
     - Если подозреваете инверсию Y: `--start-matrix=1,0,0,0,-1,1,0,0,1`.  

3. **Результат:**  
   В конце увидите:  
   - Матрицу: `a b c d e f 0 0 1` (9 чисел, напр. 0.0533 0 -53311 0 -0.0431 101781 0 0 1).  
   - Готовую команду: `xinput set-prop "Fujitsu..." "libinput Calibration Matrix" a b c d e f 0 0 1`.  
   Автоматически применится. Скопируйте матрицу для conf.

4. **Протестируйте:**  
   - Коснитесь углов, центра, свайпните. Курсор должен попадать близко (±5–10 пикселей).  
   - Если в углу:  
     - Инверсия X: Поменяйте знаки a и c, примените: `xinput set-prop ... -a 0 +c ...`.  
     - Инверсия Y: Поменяйте e и f (e=-e, f=-f).  
     - Swapped оси: Поменяйте a b c <-> d e f.  
   Сброс: Команда из шага Предварительные требования.

## Сохранение калибровки (постоянно)
1. **Создайте conf-файл:**  
   ```
   sudo nano /etc/X11/xorg.conf.d/99-calibration.conf
   ```  
   Вставьте (замените на вашу матрицу):  
   ```
   Section "InputClass"
       Identifier "Fujitsu Touch Libinput"
       MatchProduct "Fujitsu Component USB Touch Panel Pen"
       Driver "libinput"
       Option "CalibrationMatrix" "a b c d e f 0 0 1"
       Option "TapTime" "180"  # Чувствительность тапа (150–250 мс)
       Option "TappingDrag" "on"  # Тащить с тапом
   EndSection
   ```  
   Сохраните (Ctrl+O, Enter, Ctrl+X).

2. **Примени:**  
   ```
   sudo systemctl restart display-manager
   ```  
   Или `sudo reboot`. Проверьте:  
   ```
   xinput list-props "Fujitsu Component USB Touch Panel Pen (0)" | grep -i calib
   ```  
   Должна быть ваша матрица.

## Troubleshooting
- **Курсор не двигается:** Проверьте события: `xinput test "Fujitsu Component USB Touch Panel Pen (0)"` — коснитесь, увидите motion a[0]=... a[1]=... (raw 0–16M). Если нет — USB/драйвер (перезагрузите).
- **Шум/дёрганье:** Добавьте в conf: `Option "Ignore" "off"` или `Option "AccelSpeed" "0"`.
- **Поворот экрана (бонус):** Для кнопок/акселерометра Fujitsu (FUJ02E3):  
  1. Установите: `sudo apt install iio-sensor-proxy xrandr`.  
  2. Проверьте датчик: `monitor-sensor` (должен показать tilt).  
  3. Скрипт для поворота: Создайте `/usr/local/bin/rotate.sh` (chmod +x):  
     ```
     #!/bin/bash
     # 0=normal, 1=left, 2=inverted, 3=right
     xrandx --output LVDS1 --rotate left  # Пример для 90°
     xinput set-prop "Fujitsu..." "libinput Calibration Matrix" ...  # Обновите матрицу для поворота (перекалибруйте)
     ```  
  4. Привяжите к кнопкам: `sudo nano /etc/acpi/events/rotate` (Match: event=fujitsu-rotate), Action: `/usr/local/bin/rotate.sh`.  
  Перезагрузите acpi: `sudo systemctl restart acpid`.

## Заключение
Калибровка займёт 10–15 мин, и тачскрин станет точным.
