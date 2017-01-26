#!/bin/bash
docker-compose exec piwik-db \
    bash -c 'mysqldump --skip-lock-tables --single-transaction --all-databases --events -uroot -p$MYSQL_ROOT_PASSWORD' \
    | gzip -9 \
    >  ./mysql/piwik_$(date +%Y%d%mT%H%M).sql.gz
