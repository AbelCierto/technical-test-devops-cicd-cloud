# Prueba Técnica DevOps – CI/CD + Cloud

---

## 1. Pipeline de CI/CD

### Repositorio base elegido

**Opción 3 – App Web** ([docker/getting-started](https://github.com/docker/getting-started/tree/master/app))

Aplicación Todo List escrita en Node.js + Express con frontend React que persiste datos en SQLite.

---

### ¿Qué herramienta CI/CD elegiste y por qué?

**GitHub Actions.**

- Está integrada nativamente con GitHub, sin necesidad de instalar ni mantener un servidor externo (como Jenkins).
- Ofrece runners gratuitos con Docker preinstalado.
- Soporta OIDC nativo para autenticarse con AWS sin guardar access keys como secretos, lo cual es más seguro.
- Para una prueba técnica donde se busca simplicidad y funcionalidad, es la opción más directa.

---

### ¿Por qué esa nube?

**AWS (Amazon Web Services).**

- ECS Fargate permite correr contenedores sin administrar servidores (serverless compute).
- ECR como registro privado de imágenes Docker está totalmente integrado.
- ALB (Application Load Balancer) distribuye tráfico y expone la app al público.
- EFS (Elastic File System) resuelve la persistencia para contenedores efímeros.
- IAM + OIDC permite autenticación segura desde GitHub Actions sin credenciales de larga duración.

---

### ¿Por qué usar Docker?

**Sí, se usa Docker.**

- Empaqueta la aplicación y todas sus dependencias en una imagen inmutable.
- Garantiza que lo que se prueba en CI es exactamente lo que se despliega.
- ECS requiere imágenes de contenedores para funcionar.
- Facilita reproducibilidad: cualquier desarrollador puede levantar la app localmente con `docker build` + `docker run`.

---

### Etapas del pipeline

El pipeline tiene **2 jobs** definidos en `.github/workflows/deploy.yml`:

#### Job 1: `validate` (CI)
Se ejecuta en **push** y **pull requests** a `main`.

| Paso | Descripción |
|------|-------------|
| Checkout | Descarga el código del repositorio |
| Setup Node | Instala Node.js 18 |
| Install dependencies | Ejecuta `yarn install` en la carpeta `./app` |
| Run tests | Ejecuta `yarn test` (Jest) para validar la lógica de negocio |
| Lint check | Verifica formato de código con Prettier |

#### Job 2: `deploy` (CD)
Se ejecuta **solo en push a `main`** (no en PRs) y depende de que `validate` pase.

| Paso | Descripción |
|------|-------------|
| Checkout | Descarga el código |
| Configure AWS credentials | Usa OIDC para asumir un IAM Role en AWS (sin access keys) |
| Login to Amazon ECR | Obtiene token de autenticación para el registro Docker privado |
| Build, tag and push image | Construye la imagen Docker, la tagea con el SHA del commit, la sube a ECR |
| Render ECS task definition | Inyecta la nueva imagen en el JSON de task definition |
| Deploy ECS task definition | Registra la nueva task definition y actualiza el servicio ECS, esperando estabilidad |

---

### ¿Qué dispara la ejecución del pipeline?

- **Push a `main`**: ejecuta validación + deploy completo.
- **Pull request a `main`**: ejecuta solo la validación (tests + lint), sin desplegar.

---

### ¿Dónde está desplegada la app?

En **AWS ECS Fargate** (región `us-east-1`), detrás de un **Application Load Balancer**.

---

### ¿Cómo se accede?

```
http://<ALB-DNS-NAME>
```

Tras aplicar Terraform, el output `app_url` muestra la URL pública. Ejemplo:
```
http://todo-app-alb-123456789.us-east-1.elb.amazonaws.com
```

---

## 2. Arquitectura de Solución

### 2.1 Diagrama y Análisis del Flujo de Tráfico

```
┌──────────┐     ┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ Usuario  │────▶│  ALB (puerto 80) │────▶│  ECS Fargate     │────▶│  SQLite en EFS   │
│ Browser  │     │  Security Group:  │     │  Security Group:  │     │  /etc/todos/     │
│          │     │  0.0.0.0/0 → 80  │     │  ALB SG → 3000   │     │  todo.db         │
└──────────┘     └─────────────────┘     └──────────────────┘     └──────────────────┘
```

**Punto de Entrada:**
- El usuario accede vía HTTP al DNS público del ALB.
- El ALB escucha en el puerto 80 y reenvía al target group en el puerto 3000.

**Seguridad:**
- **ALB Security Group**: solo permite tráfico HTTP (puerto 80) desde Internet.
- **ECS Security Group**: solo acepta tráfico en puerto 3000 **proveniente del ALB** (referencia al SG del ALB).
- **EFS Security Group**: solo permite NFS (puerto 2049) desde el SG de ECS.
- **IAM**: GitHub Actions usa OIDC — no hay access keys ni secrets de larga duración.
- **ECR**: escaneo de vulnerabilidades activado en cada push de imagen.

**API Gateway:** No se utiliza. Para una app simple con frontend y API en el mismo contenedor, el ALB es suficiente. Un API Gateway se justificaría si existiera un backend de microservicios con autenticación, rate limiting o transformación de requests.

**Cómputo:**
- ECS Fargate — serverless, no hay instancias EC2 que administrar.
- 256 CPU units / 512 MB de memoria.
- Escalable horizontalmente mediante `desired_count`.

---

### 2.2 Estrategia de Persistencia

**Problema:** Los contenedores son efímeros. La app usa SQLite, que guarda datos en un archivo local (`/etc/todos/todo.db`). Si el contenedor se reinicia o escala, se pierden los datos.

**Solución implementada: Amazon EFS (Elastic File System)**

- Se crea un filesystem EFS cifrado.
- Se montan targets en las 2 subnets de las AZs.
- En la task definition de ECS, se define un volumen EFS montado en `/etc/todos`.
- Todos los contenedores (incluso si hay múltiples réplicas) leen/escriben el mismo filesystem.
- Los datos **sobreviven** reinicios, redeployments y escalado.

**Alternativas consideradas:**
| Opción | Pros | Contras |
|--------|------|---------|
| EFS (elegida) | Simple, compatible con SQLite, sin cambios en código | No escala escrituras concurrentes |
| RDS (PostgreSQL/MySQL) | Mejor para concurrencia, backups automáticos | Requiere cambiar código de la app |
| DynamoDB | Serverless, altamente escalable | Requiere reescribir la capa de persistencia |
| S3 | Barato, duradero | No apto para bases de datos |

---

## 3. Infraestructura como Código (IaC)

Se incluye un template de **Terraform** en la carpeta `terraform/` que automatiza la creación de todos los recursos.

### Recursos creados

| Recurso | Descripción |
|---------|-------------|
| VPC + 2 Subnets públicas | Red aislada con conectividad a Internet |
| Internet Gateway + Route Table | Permite tráfico saliente/entrante |
| Security Groups (ALB, ECS, EFS) | Control de tráfico entre capas |
| ECR Repository | Registro privado de imágenes Docker |
| EFS File System + Mount Targets | Almacenamiento persistente |
| ALB + Target Group + Listener | Balanceador de carga público |
| ECS Cluster + Task Def + Service | Orquestación de contenedores Fargate |
| IAM Roles (ECS execution, task, GitHub Actions) | Permisos con least privilege |
| OIDC Provider | Autenticación segura para GitHub Actions |
| CloudWatch Log Group | Logs centralizados del contenedor |

### Cómo usar

```bash
cd terraform

# Configurar variable con tu repo de GitHub
terraform init
terraform plan -var="github_repo=tu-usuario/technical-test-devops-cicd-cloud"
terraform apply -var="github_repo=tu-usuario/technical-test-devops-cicd-cloud"
```

Tras el apply, los outputs mostrarán:
- `app_url` — URL pública de la aplicación
- `github_actions_role_arn` — ARN del IAM Role a configurar como secret `AWS_ROLE_ARN` en GitHub

### Secret requerido en GitHub

| Secret | Valor | Descripción |
|--------|-------|-------------|
| `AWS_ROLE_ARN` | output `github_actions_role_arn` | IAM Role que el pipeline asume vía OIDC |

---

## Uso de IA

Sí, se utilizó IA (GitHub Copilot) como apoyo para:
- Estructurar y validar la configuración de Terraform.
- Revisar la definición del pipeline de GitHub Actions.
- Redactar y organizar la documentación del README.
- Verificar la consistencia entre los nombres de recursos (Terraform ↔ pipeline ↔ task definition).

El diseño de la arquitectura, la elección de servicios y la estrategia de despliegue fueron decisiones propias.