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
Проверка, что nginx запущен на нестандартном порту (в нашем случае 10001)
- $ curl http://localhost:10001
- или
- $ sudo ss -tulpn | grep nginx

Скриншоты с экрана присутствую.

Способ 3 https://github.com/RaibeartRuadh/selinux_nginx/tree/main/type3

Формирование и установка модуля SELinux.
к сожалению стенд отработал только на 90%, так как я не нашел подходящего способа выполнить эти команды, используя playbook Ansible.  Самое главное придется сделать руками

Запуск стенда:
- $ bash
- $ vagrant up

Стенд будет остановлен с ошибкой, так как порт 5000 нестандартный. 
Следующие действия выполнить руками:
- Подключиться к стенду
- Авторизоваться vagrant|vagrant
- Повысить полномочия sudo su
- Выполнить формирование модуля:
- $ sudo ausearch -c 'nginx' --raw | audit2allow -M nginx-custom-port
- Выполнить установку модуля:
- $ sudo semodule -i nginx-custom-port.pp
- Выполнить запуск nginx
- $ systemctl start nginx

Проверка, что nginx запущен на нестандартном порту (в нашем случае 5000)
- $ curl http://localhost:5000
- или
- $ sudo ss -tulpn | grep nginx

Скриншоты с экрана присутствуют.


2. Обеспечить работоспособность приложения при включенном selinux.
SELinux: проблема с удаленным обновлением зоны DNS
Инженер настроил следующую схему:

ns01 - DNS-сервер (192.168.50.10);
client - клиентская рабочая станция (192.168.50.15).
При попытке удаленно (с рабочей станции) внести изменения в зону ddns.lab происходит следующее:

[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
    > server 192.168.50.10
    > zone ddns.lab
    > update add www.ddns.lab. 60 A 192.168.50.15
    > send
    update failed: SERVFAIL
    >
Инженер перепроверил содержимое конфигурационных файлов и, убедившись, что с ними всё в порядке, предположил, что данная ошибка связана с SELinux.

Разбираемся:
Выгружаем стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems

Поднимаем стенд:
- $ vagrant up
- сервер и клиент поднялись без видимых проблем.
- Подключаемся к хосту клиента: 192.168.50.15 и выполняем команды (описанные выше)
- Получаем характерный для описанной ситуации ответ update failed: SERVFAIL

- Подключаемся к хосту сервера: 192.168.50.10
- Проверяем журналы:
- $ cat /var/log/audit/audit.log | grep denied
- $ cat /var/log/messages
- $ sealert -a /var/log/audit/audit.log
(скриншоты problem1.png problem2.png)

Получаем информацию о том, что юниту named SELinux запрещает доступ к созданию файла named.ddns.lab.view1.jnl
Выполняем поиск зоны ddns.lab, для получения типа файла безопаности:

- $ ll -Z /etc/named/dynamic/named.ddns.lab.view1

Подтверждаем информацию, что Это etc_t. Динамические зоны не могут быть расположены в защищенном каталоге /etc/. 
Их следует располагать в каталоге /var/named/dynamic/
Файлы, созданные или скопированные в этот каталог, наследуют разрешения Linux, позволяющие named записывать в них. Поскольку такие файлы имеют тип named_cache_t, SELinux позволяет named записывать в них.

Изменим тип файла для директории /etc/named/dynamic в контексте безопаности SELinux, используя утилиту semanage
- $ sudo semanage fcontext -a -t named_cache_t '/etc/named/dynamic(/.*)?'

А также восстановим файлы контекстов безопасности SELinux по умолчанию, используя утилиту restorecon (https://www.opennet.ru/man.shtml?topic=restorecon&category=8&russian=2):
- $ sudo restorecon -R -v /etc/named/dynamic/

Переключимся на хост клиента и попробуем выполнить алгоритм снова:

- $ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> 

Ошибки не получаем. 
(скриншот problem3.png)

Переключаемся на хост сервера и проверяем сервер DNS www.ddns.lab, используя утилиту dig (https://linux-faq.ru/page/komanda-dig)

- $ dig www.ddns.lab
Получаем информацию, что запрос с клиентской машины был успешный.

(скриншот problem4.png)

Альтернативно текущую проблему можно решить через утилиту audit2allow. Она выявит в журналах сообщения, которые появляются, когда система не дает разрешение на операцию и создает фрагмент кода правил политики, который позволяет операции успешно завершиться. Однако, использование его вслепую наруушает безопасность, так как некоторые отказы обоснованы. И если можно обойтись без этой утилиты, то лучше искать другие способы. 
