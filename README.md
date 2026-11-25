# Proyecto Triple Pipeline DevOps en AWS

Infraestructura (Terraform) → Código y Versionado (Docker + ECR) → Despliegue y Monitoreo (ECS Fargate), con GitHub Actions.

## Estructura
- `.github/workflows/` – los pipelines que ejecuta GitHub Actions
  - `1-infraestructura.yml` – Lint → Plan → Aprobación → Apply
  - `2-codigo-ecr.yml` – Build → Pruebas → Docker Build → Push a ECR (tag SHA + latest)
  - `3-despliegue-ecs.yml` – Task Definition → QA → Aprobación → Deploy Prod → Monitoreo HTTP
  - `4-destruir-infra.yml` – limpieza (`terraform destroy`) para no gastar créditos
- `pipelines/` – copia exacta de los .yml para la entrega
- `terraform/` – VPC por defecto, Security Group (80/3000), ECR, CloudWatch Logs, clúster ECS, Task Definitions y Servicios
- `aplicacion/backend` – API Express + prueba automatizada (`npm test`)
- `aplicacion/frontend` – página web estática con Nginx

## Adaptaciones para AWS Academy (Learner Lab)
- Learner Lab no permite crear roles IAM: se usa el rol existente **LabRole** (data source en Terraform y en el Pipeline 3).
- Se usa `aws-session-token` en todos los pipelines (secreto `AWS_SESSION_TOKEN`).
- El estado de Terraform se guarda en un bucket S3 (`devops-final-tfstate-<ACCOUNT_ID>`) que el Pipeline 1 crea automáticamente; así se puede volver a ejecutar y destruir.
- Se corrigió el JSON de `container-definitions` del Pipeline 3 generándolo con `jq`.

## Secretos requeridos (Settings → Secrets and variables → Actions)
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_REGION` (= `us-east-1`).
Las credenciales del Learner Lab caducan (~4 h): al reiniciar el laboratorio hay que actualizarlas.

## Entornos de aprobación (Settings → Environments)
`produccion-infra` y `produccion-deploy`, ambos con *Required reviewers*.

## Orden de ejecución
1. Pipeline 1 → aprobar → VPC/SG, ECR y clúster ECS creados.
2. Pipeline 2 → pruebas verdes e imágenes etiquetadas en ECR.
3. Pipeline 3 se dispara solo → aprobar → el log imprime `FRONTEND URL` y `BACKEND API`.
4. Al terminar: ejecutar **Limpieza - Destruir Infraestructura**.

No se guarda ninguna clave ni token en el repositorio.
