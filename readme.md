Практика с SELinux
Цель: Тренируем умение работать с SELinux: диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется.
1. Запустить nginx на нестандартном порту 3-мя разными способами:
- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux.
К сдаче:
- README с описанием каждого решения (скриншоты и демонстрация приветствуются).

2. Обеспечить работоспособность приложения при включенном selinux.
- Развернуть приложенный стенд
https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems
- Выяснить причину неработоспособности механизма обновления зоны (см. README);
- Предложить решение (или решения) для данной проблемы;
- Выбрать одно из решений для реализации, предварительно обосновав выбор;
- Реализовать выбранное решение и продемонстрировать его работоспособность.
К сдаче:
- README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
- Исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.

Запустить nginx на нестандартном порту
Способ 1 https://github.com/RaibeartRuadh/selinux_nginx/tree/main/type1
Добавление нестандартного порта в имеющийся тип:
Используется команда:
- semanage port --add --type http_port_t --proto tcp 9001

Поскольку я использую Ansible playbook, то этот блок выглядит как:

    - name: Разрешаем наш нестандартный порт
      seport:
        ports: 9001
        proto: tcp
        setype: http_port_t
        state: present
Запуск стенда:
- $ bash
- $ vagrant up

После отработки playbook
Проверка, что nginx запущен на нестандартном порту (в нашем случае 9001)
- $ curl http://localhost:9001
- или
- $ sudo ss -tulpn | grep nginx

Скриншоты с экрана присутствуют

Способ 2 https://github.com/RaibeartRuadh/selinux_nginx/tree/main/type2

Использую команду setsebool -P nis_enabled 1
Иными словами, я разрешаю использование сетевого интерфейса. После применения правила, разрешаю nginx (делаю симлинк сервиса) и запускаю.

В Ansible playbook это выглядит как:

    - name: Установка разрешения setsebool -P nis_enabled 1
      seboolean:
        name: httpd_can_network_connect
        state: yes
        persistent: yes       
...
    - name: enable service nginx
      systemd:
        name: nginx
        enabled: yes
        masked: no      
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted

Запуск стенда:
- $ bash
- $ vagrant up

После отработки playbook
Проверка, что nginx запущен на нестандартном порту (в нашем случае 9001)
- $ curl http://localhost:10001
- или
- $ sudo ss -tulpn | grep nginx

Скриншоты с экрана присутствую.






