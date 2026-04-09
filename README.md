# Prueba Técnica DevOps – CI/CD + Cloud

## Descripción
Se implementó un pipeline CI/CD para desplegar una aplicación web containerizada en AWS.

## Repositorio base elegido
Opción 3 – App Web (Docker Getting Started App)

## Herramienta CI/CD elegida
GitHub Actions.

### ¿Por qué GitHub Actions?
Porque está integrado nativamente con GitHub, permite automatizar validaciones, build y deploy de forma simple, y reduce la complejidad operativa frente a montar Jenkins para una prueba técnica.

## Nube elegida
AWS.

### ¿Por qué AWS?
Porque ofrece integración sencilla con ECR, ECS Fargate, ALB, IAM y EFS, lo que permite construir una solución moderna, escalable y administrada.

## Uso de Docker
Sí, se usó Docker para empaquetar la aplicación y asegurar consistencia entre desarrollo, pipeline y producción.

## Etapas del pipeline
1. Checkout del código
2. Instalación de dependencias
3. Validaciones básicas / tests
4. Build de imagen Docker
5. Push a Amazon ECR
6. Deploy a ECS Fargate

## Disparador del pipeline
El pipeline se ejecuta en cada push a la rama main.
Adicionalmente, en pull requests se ejecutan validaciones sin desplegar.

## Arquitectura
Usuario → ALB → ECS Fargate → contenedor app
Persistencia → EFS montado en /etc/todos

## Seguridad
- ALB expuesto públicamente
- ECS en red controlada por Security Groups
- El servicio ECS solo acepta tráfico proveniente del ALB
- Credenciales del pipeline manejadas con GitHub OIDC + IAM Role

## Persistencia
La aplicación usa SQLite local. Como los contenedores son efímeros, se montó Amazon EFS en la ruta `/etc/todos` para preservar el archivo de datos.

## URL de acceso
http://<ALB-DNS>

## Infraestructura como código
Se incluye template básico en Terraform para aprovisionar recursos principales.

## Uso de IA
Sí. Se utilizó IA como apoyo para estructurar la solución, redactar documentación y revisar la definición del pipeline y de la infraestructura.