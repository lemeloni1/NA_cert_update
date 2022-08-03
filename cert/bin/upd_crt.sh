#!/bin/bash -eu

declare -r api_key=''
declare -r basedir='/opt/letsencrypt'
declare -r tmpdir='/tmp/CRT_'$(echo $(pwgen 8))
declare -r domainsfile=${basedir}'/domains.txt'
declare -r archive=$(echo $(date +%Y-%m-%d))
declare -r log=${basedir}/upd_crt.log
status=1

token=$(curl -s -k -X POST -d "api_key=${api_key}" 'https://panel.netangels.ru/api/gateway/token/' | jq -r '.token')
for STRING in $(cat ${domainsfile} | grep -v "#"); do
    domain=$(echo ${STRING} | cut -d":" -f2)
    id=$(echo ${STRING} | cut -d":" -f1)

    fullinfo=$(curl -s -k -H "Authorization: Bearer ${token}" -X GET "https://api-ms.netangels.ru/api/v1/certificates/${id}/" | jq .)

    state=$(echo ${fullinfo} | jq '.state')
    [[ "${state}" = "\"Issued\""  ]] || {
        echo "$(date +%Y/%m/%d" "%H:%M) Сертификат с id:${id} для домена ${domain} не найден. Пропускаем." >> ${log} 
        continue
    }

    mkdir -p ${tmpdir}/${id}_${domain}
    mkdir -p ${basedir}/cert/${domain}

    cd ${tmpdir}/${id}_${domain}
    name=$(echo ${fullinfo} | jq .domains | jq .[0] | tr -d \" | sed -e 's|*|WC|g' | sed -e 's|\.|_|g')
    curl -s -k -H "Authorization: Bearer ${token}" -X GET "https://api-ms.netangels.ru/api/v1/certificates/${id}/download/?name=${name}&type=tar" > ${name}.tar

    [[ -f ${name}.tar ]] && {
        tar -xf ${name}.tar
        rm -f ${name}.tar;
    } || {
        echo "$(date +%Y/%m/%d" "%H:%M) Не смогли получить ${name}.tar для домена ${domain}. Пропускаем." >> ${log} 
        continue
    }

    crt_old="${basedir}/cert/${domain}/${name}.crt"
    [[ -f ${crt_old} ]] || touch ${crt_old}
    crt_new="${tmpdir}/${id}_${domain}/${name}.crt"

    [[ -f ${crt_new} ]] && {
        diff -q "${crt_old}" "${crt_new}" && {
            echo "$(date +%Y/%m/%d" "%H:%M) Сертификат для домена ${domain} не требует обновлений. Пропускаем." >> ${log} 
            continue
        } || echo "$(date +%Y/%m/%d" "%H:%M) Обнаружен новый сертификат для домена ${domain}. Обновляем" >> ${log} 
    } || {
        echo "$(date +%Y/%m/%d" "%H:%M) Сертификат для домена ${domain} в архиве не обнаружен." >> ${log} 
        continue
    }

    [[ -s ${crt_old} ]] && {
        mkdir -p ${basedir}/cert/${domain}/${archive}
        mv ${basedir}/cert/${domain}/${name}.* ${basedir}/cert/${domain}/${archive}/
    }

    mv ${tmpdir}/${id}_${domain}/* ${basedir}/cert/${domain}/

    status=0
done

rm -rf ${tmpdir}

exit ${status}
