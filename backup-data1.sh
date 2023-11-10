#!/bin/bash

function log {
    echo `date -u +%F`T`date -u +%H-%M-%SZ` $1 >> $LOG_DIR/$LOG_FILE
}

PGM_NAME=`basename $0`
LOG_DIR="/home/caadmin/backups.sh.logs"
BACKUP_DIR="/media/backups"
LOG_FILE=`basename $0 | cut -d'.' -f1`_`date -u +%F`_`date -u +%H-%M-%SZ`.log

echo "Chequeando si el directorio de logs existe"
if [ ! -d $LOG_DIR ]; then
    mkdir -p $LOG_DIR
    log "El directorio de logs no existia, se creo en esta ejecucion"
fi

log "Iniciando backup"
rsync -avz --delete --progress /media/data1/ $BACKUP_DIR >> $LOG_DIR/$LOG_FILE 2>&1
log "Backup finalizado"
