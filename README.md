# NA_cert_update
update SSL-certificates
Скрипт предназначен для использования на VDS хостинг-провайдера NetAngels.
Он позволяет автоматизатировать процесс обновления SSL сертификатов, выпущенных через панель управления.
Основную информацию пишет в свой лог upd_crt.log
В большинстве случаев это относится к SSL сертификатам от Let's Encrypt, рабочий срок которых 3 месяца.

Порядок установки и использования:
1. Заводим отдельного пользования для работы со скриптом 
    	
	useradd -m -d /opt/letsencrypt -s /usr/sbin/nologin letsencrypt 

Можно использовать и существующего, этот момент на свое усмотрение.

2. Переходим в каталог и тянем скрипт из git-репозитория 
    	
	cd /opt/letsencrypt 
    	
	git clone [https://github.com/lemeloni1/NA_cert_update](https://github.com/lemeloni1/NA_cert_update.git) 

3. Перемещаем каталоги и правим доступы

	mv NA_cert_update /opt/letsencrypt/cert 
	
	chown -R letsencrypt: /opt/letsencrypt

4. Для работы необходимо установить пакет jq
	
	apt-get update && apt-get install -y jq

или
	
	yum install jq

Возможно, на Debian Wheezy этого пакета нет, берем его из бэкпортов
    
    echo "deb http://ftp.de.debian.org/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list

5. В файл /opt/letsencrypt/domains.txt добавляем список доменов вида id:domain, которые будем чекать. 
	
	Нужно добавить токен id в начало файла bin/upd_crt.sh ,  берем из панели управления https://panel.netangels.ru/account/api/ . в upd_crt.sh вставляем api-key

6. Запускаем первый раз командой 
    
    sudo -u letsencrypt bash -x ./bin/upd_crt.sh

Смотрим вывод на наличие каких-либо ошибок, проверяем /opt/letsencrypt/cert на сертификаты. Если ничего нет, а должно быть,
копируем весь вывод с экрана и обращаемся к vitaly, если самостоятельно не смогли разобраться. Если видны ошибки, точно так же, пересылаем их.

7. В crontab добавляем задание
    0 1 * * * /usr/bin/sudo -u letsencrypt /opt/letsencrypt/bin/upd_crt.sh && nginx -s reload

8. К web-серверу прокидываем симлинк
    ln -s /opt/letsencrypt/cert /etc/nginx/ssl 

9. Создаем соответствующие конфиг для web-сервера, например, как в статье https://www.netangels.ru/support/ssl/add-ssl-cvds-panel/

10. Создаем в панели отложенный тикет на проверку обновления сертификата за 3 дня до окончания срока действия.	
