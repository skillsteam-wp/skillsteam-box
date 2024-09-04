# Конфигурация и запуск
Перед первым запуском нужно залогиниться в docker registry используя данные которые были вам высланы по email  

`docker login cr.selcloud.ru`


### Подготовительный этап:
```sh
make prepare
```
---

После успешного выполнения в конревой папке приложения появится файл .env с переменными которые нужно настроить.

---

## Описание переменных и их значений по умолчанию (файл .env)

| Наименование         | Значение по умолчанию                              | Описание                                                                                        |
|----------------------|----------------------------------------------------|-------------------------------------------------------------------------------------------------|
| APP_ENV              | PROD                                               | Среда запуска приложения                                                                        |
| FRONT_URL            | http://localhost:3000                              | Публичный адрес приложения                                                                      |
| NEXT_PUBLIC_BFF_PATH | /api                                               | Точка входа в BFF слой для проксирования запросов                                               |
| DB                   | postgres://skillsteam:tmp@postgres:5432/skillsteam | Cтрока-адрес подключения к БД для приложения                                                    |
| SMTP                 | postfix                                            | Хост для подключения к почтовому шлюзу                                                          |  
| SMTP_PORT            | 25                                                 | Порт для подключения к почтовому шлюзу                                                          |
| SMTP_HOSTNAME        | company.ru                                         | Хост почтового ящика отправителя                                                                |
| SMTP_MAILBOX         | no-reply                                           | Название почтового ящика отправителя                                                            |
| NEXTAUTH_SECRET      | Надежный ключ                                      | Секрет для next авторизации, можно сгенерировать командой `openssl rand -hex 32`.               |   
| NEXTAUTH_URL         | http://localhost:3000                              | Базовая ссылка next-auth для редиректов, должна вести по публичному адресу на главную страницу. |   
| CACHE_PUBLIC_MAX_AGE | 3600                                               | Время в секундах, для кеширования статики на уровне                                             | 
| S3_PUBLIC_URL        | https://example.com                                | Публичная ссылка на storage s3                                                                  |   
| S3_ENDPOINT_URL      | https://example.com                                | Ссылка для обращения приложения к s3                                                            |   
| S3_REGION            | ru-1                                               | Регион s3                                                                                       | 
| S3_ACCESS_KEY        | s3 key                                             | Ключ s3                                                                                         |   
| S3_SECRET_KEY        | s3 secret                                          | Секрет s3                                                                                       |   
| S3_BUCKET_NAME       | s3 bucket name                                     | Название бакета s3                                                                              | 
| REDIS_HOST           | redis                                              | Хост для подключения к redis                                                                    |
| REDIS_PORT           | 6379                                               | Порт для подключения к redis                                                                    |
| POSTGRES_DB          | skillsteam                                         | Наименование БД приложения                                                                      |
| POSTGRES_USER        | skillsteam                                         | Пользователь для подключения к СУБД                                                             |
| POSTGRES_HOST        | postgres                                           | Имя хоста для подключения к СУБД                                                                |
| POSTGRES_PORT        | 5432                                               | Порт для подключения к СУБД                                                                     |
| POSTGRES_PASSWORD    | tmp                                                | Пароль для подключения к СУБД                                                                   |
| VERSION              | v1.0.0                                             | Версия приложения                                                                               |
| LICENSE_KEY          | l-key                                              | Лицензионный ключ вашей копии приложения                                                        |


**Переменным нужно дать корректные значения в зависимости от среды выполнения и желаемого адреса приложения.**

К примеру если нужно развернуть приложение по адресу app.skillsteam.pro нужно задать такие значения для переменных:

`NEXTAUTH_URL=https://app.skillsteam.pro`  
`NEXT_PUBLIC_FRONT_URL=https://app.skillsteam.pro`

Для работы приложения нужно обязательно указать лицензионный ключ в переменной `LICENSE_KEY`  

Кроме того для полноценного функционирования приложения необходимо задать параметры подключения к SMTP, а также подключение к s3 хранилищу с публичным адресом по которому будет доступен его контент.

# Настройка SMTP

Пример переменных в `.env` файле для локального SMTP postfix:  
`SMTP=postfix`  
`SMTP_PORT=25`

Помимо переменных так-же необходимо настроить сам `postfix`:  

Пример настройки для отправки писем с адреса `no-reply@skillsteam.pro`

---  

### Для SMTP сервера вне текущей установки: 
- В файл /etc/postfix/generic добавить строку `no-reply@skillsteam.pro  no-reply@skillsteam.pro`
- В файл /etc/postfix/main.cf задать `myhostname = skillsteam.pro`
- В файл /etc/postfix/main.cf задать `local_recipient_maps = `
- В файл /etc/postfix/main.cf задать `mynetworks = 0.0.0.0/0` **это разрешит использовать postfix из любой подсети**, если нужно ограничиться конкретными подсетями то можно их задать через запятую.  

---  

### Для SMTP сервера в составе текущей установки
**Для удобства в состав docker-compose входит сервис postfix который можно сконфигурировать переменными:**    
`SMTP_HOSTNAME=skillsteam.pro`  
`SMTP_MAILBOX=no-reply`  

---  

### Для того что-бы почта доходила до адресата необходимо сделать SPF запись(тип **TXT**) и MX запись на DNS сервере для сервера на котором размешается postfix    
Пример SPF и MX записи если бы постфикс был на сервере с IP `111.222.33.44` на домене skillsteam.pro

### SPF:
- Тип: `TXT`
- Название записи: `skillsteam.pro.` (точка в конце обязательна)
- Значение: `v=spf1 ip4:111.222.33.44 a mx include:_spf.mail.ru ~all`
- 

### MX
- Тип: `MX`
- Название записи: `skillsteam.pro.` (точка в конце обязательна)
- Значение: `skillsteam.pro` (без точки в конце)


## Приложение можно запустить в двух вариантах:  

1) Обычный запуск. Потребуется подключение внешнего S3 хранилища  
2) **Эксперементальный**. Будет запущен дополнительный сервис с S3

Пример настройки переменных для Selectel S3:  
`S3_PUBLIC_URL=https://6examplee-furl2-4for9-8selectel4-storage43.selstorage.ru`  
`S3_ENDPOINT_URL=https://s3.selcdn.ru`  
`S3_REGION=ru-1`  
`S3_ACCESS_KEY=asfsdfgj`  
`S3_SECRET_KEY=sDpsdvoiawey8324sdfjfspof`  
`S3_BUCKET_NAME=skillsteam`

---

### Если вы решили использовать запуск с S3 хранилищем, то перед первым запуском воспользуйтесь скриптом `S3_prepare.sh` что-бы задать конфигурацию для S3 сервера

---

### Запуск приложения без s3:
```sh
make up
```

### Запуск приложения c s3:
```sh
make up-s3
```

### Остановка приложения без s3:
```sh
make down
```

### Остановка приложения c s3:
```sh
make down-s3
```

# Начало работы

После установки и запуска нужно пройти регистрацию, которая будет доступна на /register урле приложения.

---  

К примеру если адрес приложения http://skillco.ru то ссылка для регистрации будет выглядеть так: http://skillco.ru/register  

--- 

# Обновление приложения

### ВНИМАНИЕ настоятельно рекомендуем сделать резервную копию БД перед выполнением данной операции  

Для проверки и применения обновления приложения достаточно запустить скрипт `check-fo-update.sh` и следовать инструкциям.  

Если появилась новая версия приложения, то будет выкачан новый образ и контейнер с приложением будет перезапущен.   