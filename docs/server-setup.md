# Настройка сервера DevOps

## Развёртывание приложения через Ansible

Плейбуки запускаются из WSL и работают с существующей Ubuntu Server 24.04.
Инвентарь `ansible/inventory/prod.ini` использует локальный SSH-псевдоним
`devops`, порт `2222` и ключ `~/.ssh/devops_vm`. Фактический адрес VM
задаётся в `~/.ssh/config` на управляющем узле.

| Параметр | Значение |
|---|---|
| Образ | `ghcr.io/uz3ix/devops-ci-app` |
| Тег образа | `3101f7885b66330f7d771c9ed80d1bf99017926f` |
| Порт на VM | `127.0.0.1:5011` |
| Порт в контейнере | `5000` |
| Виртуальный хост | `pr11.devops.local` |
| Проверка приложения | `GET /health` возвращает `{"status":"ok"}` |

На существующей VM роли `base` и `ssh` проверяют Docker, Nginx и SSH.
Роль `app` скачивает образ перед запуском контейнера. Роль `nginx` добавляет
отдельный сайт и запускает `nginx -t` перед перезагрузкой конфигурации.
Проверенный SHA остаётся заданным в `ansible/group_vars/all.yml`.

Из каталога `ansible/` на управляющем узле:

    ansible-galaxy collection install -r requirements.yml
    ansible vm -m ping
    ansible-playbook site.yml -K
    ansible-playbook site.yml -K
    ansible-playbook verify.yml -K

Повторный запуск с тем же SHA должен завершиться с `changed=0, failed=0`.
При ошибке скачивания образа плейбук останавливается до изменения контейнера.
Аудит проверяет SSH-порт, тег и привязку контейнера, а также отвечает ли
приложение напрямую и через Nginx.

Работа выполнена на VM с настроенным SSH-доступом. Bootstrap от `student`
и первичную установку Docker и Nginx на этом стенде не выполняли.
