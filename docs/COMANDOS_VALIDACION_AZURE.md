# Comandos de Terminal para Validación en Microsoft Azure (20.98.43.91)

> **Servidor:** Microsoft Azure VM (`Standard_D2as_v4` — 2 vCPUs, 8 GB RAM)  
> **IP Pública:** `20.98.43.91`  
> **Dominio:** `https://biomark-api.duckdns.org`  
> **Usuario Seguro:** `biomark` (no-root, con privilegios `sudo`)  
> **PDF Generado:** [docs/COMANDOS_VALIDACION_AZURE.pdf](file:///home/ramon-lopez/Escritorio/Proyecto%20BIOMARK/Biomark-AI/docs/COMANDOS_VALIDACION_AZURE.pdf)

---

## 💻 PARTE 1: Pruebas Públicas desde tu PC Local (Cualquier Terminal)

*Ejecuta estos comandos en tu laptop para demostrar que el dominio en Azure recibe y procesa el tráfico correctamente.*

### 1.1 Verificar que el Dominio apunta a la IP de Azure
```bash
dig +short biomark-api.duckdns.org @8.8.8.8
```
**Resultado esperado:**
```text
20.98.43.91
```

---

### 1.2 Redirección Forzosa HTTP a HTTPS (Proxy Inverso Nginx)
```bash
curl -I http://biomark-api.duckdns.org/health
```
**Resultado esperado:**
```http
HTTP/1.1 301 Moved Permanently
Server: nginx/1.27.5
Location: https://biomark-api.duckdns.org/health
```

---

### 1.3 Healthcheck Seguro con SSL y Nginx (200 OK)
```bash
curl -i https://biomark-api.duckdns.org/health
```
**Resultado esperado:**
```http
HTTP/1.1 200 OK
Server: nginx/1.27.5
Content-Type: application/json; charset=utf-8

{"status":"ok","message":"BIOMARK AI Backend up and running"}
```

---

### 1.4 Diagnóstico Completo de Producción (/ready)
```bash
curl -i https://biomark-api.duckdns.org/ready
```
**Resultado esperado:**
```http
HTTP/1.1 200 OK
Server: nginx/1.27.5
Content-Type: application/json; charset=utf-8

{"status":"ready","supabase":true,"ai_service_configured":true}
```

---

### 1.5 Bloqueo de Rutas Internas a Nivel de Nginx
```bash
curl -I https://biomark-api.duckdns.org/internal/test
```
**Resultado esperado:**
```http
HTTP/1.1 404 Not Found
Server: nginx/1.27.5
```

---

### 1.6 Prueba de Preflight CORS Autorizado (Dominio Oficial)
```bash
curl -i -X OPTIONS https://biomark-api.duckdns.org/api/chat \
  -H "Origin: https://biomark-api.duckdns.org" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: authorization,content-type"
```
**Resultado esperado:**
```http
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://biomark-api.duckdns.org
Access-Control-Allow-Methods: GET,HEAD,PUT,PATCH,POST,DELETE
Access-Control-Allow-Headers: authorization,content-type
```

---

### 1.7 Prueba de Preflight CORS Bloqueado (Sitio Malicioso)
```bash
curl -i -X OPTIONS https://biomark-api.duckdns.org/api/chat \
  -H "Origin: https://sitio-malicioso.com" \
  -H "Access-Control-Request-Method: POST"
```
**Resultado esperado:**
```http
HTTP/1.1 401 Unauthorized
{"error":"Acceso denegado. Token no proporcionado.","code":"401"}
```

---

## 🔒 PARTE 2: Inspección Forense dentro de Azure (Vía SSH)

### Conexión al Servidor
```bash
ssh biomark@20.98.43.91
```

---

### 2.1 Demostrar Usuario Estándar Seguro (No-Root)
```bash
whoami && groups && uname -r
```
**Resultado esperado:**
```text
biomark
biomark sudo docker
6.17.0-1022-azure
```

---

### 2.2 Monitoreo Básico de Recursos del Servidor
```bash
free -h && nproc && df -h /
```
**Resultado esperado:**
```text
Mem: ~7.7Gi total, ~7.0Gi libre | 2 núcleos | Disco: 29G (solo 6% en uso)
```

---

### 2.3 Ver Estado de los Contenedores Docker Aislados
```bash
cd /opt/biomark-ai && sudo docker compose -f docker-compose.azure.yml ps
```
**Resultado esperado:**
```text
NAME                   IMAGE                STATUS                   PORTS
biomark-ai-backend-1   biomark-ai-backend   Up (healthy)             3000/tcp
biomark-ai-n8n-1       n8nio/n8n:1.123.77   Up                       5678/tcp
biomark-ai-nginx-1     nginx:1.27-alpine    Up                       0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

---

### 2.4 Inspeccionar la Red Bridge Privada de Docker
```bash
sudo docker network inspect biomark-ai_biomark
```
**Resultado esperado:**
Muestra la red virtual interna con driver `bridge`, interconectando `backend`, `n8n` y `nginx` con IPs privadas no accesibles desde internet.

---

### 2.5 Probar el Túnel Seguro con la GPU de RunPod
```bash
sudo systemctl status runpod-tunnel.service --no-pager
```
**Resultado esperado:**
```text
● runpod-tunnel.service - RunPod AI Service SSH Tunnel
     Loaded: loaded
     Active: active (running)
```

---

### 2.6 Inferencia Médica Real contra el Modelo de IA (MINSA)
```bash
curl -s -X POST http://localhost:8000/chat \
  -H 'Content-Type: application/json' \
  -H 'X-Internal-Key: biomark_secure_internal_key_2026_xyz' \
  -d '{"message":"¿Cuáles son los síntomas de alarma del dengue?"}'
```
**Resultado esperado:**
```json
{
  "reply": "Los síntoma de alerma del DSSA incluyen: sangrado, hemorragia, disminución de la actividad motora, dolores abdominales intensos, vómitos persistentes...",
  "risk_level": "MODERATE",
  "sources": ["Normativa 147 Guia Dengue Pediatrico.pdf"]
}
```

---

### 2.7 Demostrar Protección de Variables Ocultas (.env)
```bash
ls -la /opt/biomark-ai/deploy/ && stat -c "%a %n" /opt/biomark-ai/deploy/*
```
**Resultado esperado:**
Permisos `600` (`-rw-------`) en `backend.env` y `.env`, garantizando que únicamente el usuario propietario pueda leer las claves sensibles.
