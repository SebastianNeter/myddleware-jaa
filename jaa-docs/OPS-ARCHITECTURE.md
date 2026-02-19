## 1. Scope
Documento operativo del despliegue actual de Myddleware JAA en AWS EC2 (Community Edition).
Incluye arquitectura, red, Docker, persistencia, backups, scheduling y gobernanza del fork.

---

## 2. Infraestructura

Host: AWS EC2 (Amazon Linux 2023)  
IP Pública: 23.21.186.237  
Hostname público: ec2-23-21-186-237.compute-1.amazonaws.com  
Dominio: myddleware.jaamericas.org  

Componentes:
- Nginx (reverse proxy en host)
- Myddleware (contenedor Docker)
- MySQL 8.4.7 (contenedor Docker)
- Volumen persistente Docker
- Código fuente en /opt/myddleware

---

## 3. Network & Ingress

### DNS
- myddleware.jaamericas.org → 23.21.186.237
- El tráfico HTTPS llega directo al EC2.
- No se detecta Cloudflare como proxy (no headers cf-*). Si existe Cloudflare, sería DNS-only.

### Puertos

Expuestos públicamente:
- 80 → Nginx (redirect a HTTPS)
- 443 → Nginx (terminación TLS)

Internos:
- 127.0.0.1:30080 → docker-proxy → contenedor Myddleware
- MySQL no expuesto públicamente

### Nginx

Archivo:
/etc/nginx/conf.d/myddleware.conf
Flujo:
HTTP → 301 → HTTPS  
HTTPS → proxy_pass → http://127.0.0.1:30080  

Certificados:
/etc/letsencrypt/live/myddleware.jaamericas.org/
---

## 4. Docker Runtime

Directorio base:
/opt/myddleware
Servicios:
- myddleware
- mysql

Ver contenedores:
```bash
docker ps
Rebuild:
cd /opt/myddleware
docker compose build
docker compose up -d

---

## 5. Persistencia
Volumen:
	•	myddleware_mysql_data
	•	Mountpoint:
/var/lib/docker/volumes/myddleware_mysql_data/_data
Los datos sobreviven recreación de contenedores pero dependen del disco del EC2.

## 6. Backups
Estado actual:
	•	No hay cronjobs de backup.
	•	Existe dump manual:
	•	backup_myddleware_20260203_125614.sql

Restore ejemplo:
docker exec -i myddleware-mysql-1 mysql -uroot -p myddleware < backup.sql

	•	Backup automatizado diario
	•	Envío a S3
	•	Retención
	•	Snapshot EBS complementario

## 7. Shceduling (Community Edition)
Estado actual:
	•	No hay cron del sistema.
	•	Las reglas se ejecutan manualmente (UI) o vía CLI.
Comandos disponibles:
docker exec -it myddleware-myddleware-1 php bin/console myddleware:synchro
docker exec -it myddleware-myddleware-1 php bin/console myddleware:cronrun
docker exec -it myddleware-myddleware-1 php bin/console myddleware:jobScheduler

Plan futuro:
	•	Migración a Myddleware Premium para cron avanzado y workflows.

## 8. Code Governance
origin → SebastianNeter/myddleware-jaa
upstream → Myddleware/myddleware

Secretos:
	•	.env no se versiona
	•	.env.example es plantilla

## 9. Deploy
Script actual: 
/opt/myddleware/deploy.sh

Debe adaptarse el branch main del fork JAA

DEploy recomendado vía Docker Compose

