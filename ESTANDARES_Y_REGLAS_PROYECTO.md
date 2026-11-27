# ESTÁNDARES Y REGLAS DE ARQUITECTURA — MAY DELICIAS

**Contexto:** Sistema single-tenant de gestión gastronómica (stock, recetas, ventas, caja y control de costos).
**Stack oficial:** Python 3.12+, FastAPI, PostgreSQL, SQLAlchemy 2.0, Pydantic, pytest + httpx, Docker y GitHub Actions.

---

## 1. Base de Datos y Modelado (PostgreSQL)
* **Normalización (3FN):** Un dato atómico por celda y sin redundancias. **Excepción contable obligatoria:** congelar el `precio_unitario` en `venta_items` al momento de la venta para preservar el historial ante cambios de precios.
* **Claves Primarias:** Usar `INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY` (no usar `SERIAL`).
* **Tipos de Datos Estrictos:**
  * **Dinero:** Siempre `NUMERIC(12,2)`. Prohibido `FLOAT` o `DOUBLE PRECISION`.
  * **Cantidades de recetas/insumos:** `NUMERIC(12,4)`.
  * **Fechas:** Siempre `TIMESTAMPTZ` (con zona horaria, nunca `TIMESTAMP` a secas).
  * **Textos:** `TEXT` o `VARCHAR` (no usar `NVARCHAR`).
* **Integridad y Restricciones:**
  * Usar `CHECK (columna >= 0)` o `CHECK (columna > 0)` en todos los montos y cantidades.
  * Usar `ON DELETE RESTRICT` en todas las claves foráneas (`FK`) de tablas transaccionales, financieras y de stock. **Prohibido `ON DELETE CASCADE`** en datos históricos o contables.
* **Trazabilidad:**
  * **Tablas Maestras** (`categorias`, `productos`, `clientes`): usar `soft_delete` (`eliminado_en TIMESTAMPTZ NULL`).
  * **Tablas Transaccionales** (`ventas`, `venta_items`, `movimientos_stock`, `notas_credito`): patrón **Append-Only** (solo `INSERT` y `SELECT`; prohibido `UPDATE` o `DELETE` sobre registros cerrados).

---

## 2. Backend y Arquitectura (Python / FastAPI)
* **Principios:** KISS, YAGNI, Clean Code, SOLID básico y tipado fuerte (*type hints*) en todas las funciones.
* **Arquitectura en 3 Capas:**
  1. `routers/`: Endpoints HTTP, códigos de estado y validación de entrada/salida. Sin lógica de negocio.
  2. `services/`: Reglas de negocio, cálculos financieros y manejo de transacciones ACID.
  3. `repositories/`: Consultas SQL / SQLAlchemy 2.0. Sin lógica de negocio.
* **Validación (DTOs):** Esquemas de entrada y salida con **Pydantic** usando obligatoriamente `Decimal` para plata y cantidades (prohibido `float`).
* **Confiabilidad y Concurrencia:**
  * Operaciones críticas (venta + descuento de stock + registro de movimiento) dentro de una transacción ACID (`BEGIN` / `COMMIT` / `ROLLBACK`).
  * Descuento atómico de stock (`WHERE stock_actual >= cantidad`) para evitar stock negativo por concurrencia.
  * Clave de idempotencia (`UNIQUE`) en ventas y pagos para evitar duplicados ante reintentos de red.
* **APIs REST:** Usar verbos HTTP semánticos y códigos de estado exactos (`200`, `201`, `400`, `401`, `403`, `404`, `409`, `422`, `500`).

---

## 3. Seguridad (OWASP Básico)
* **Secretos:** Credenciales, URLs de BD y API Keys únicamente en `.env` (bloqueado en `.gitignore`). Mantener un `.env.example` sin valores reales.
* **Anti SQL Injection (CWE-89):** Prohibido concatenar strings en consultas SQL. Usar siempre consultas parametrizadas o SQLAlchemy.
* **Autenticación y Roles (RBAC):** Contraseñas hasheadas (`bcrypt` o `argon2`), autenticación con JWT y control de permisos por rol (`dueno` vs `empleado`) validado en cada endpoint.
* **Errores Sanitizados:** Nunca exponer *stack traces* ni mensajes internos del motor de BD en las respuestas HTTP al cliente.

---

## 4. Testing, Observabilidad y DevOps
* **Testing (`pytest` + `httpx`):** Tests unitarios y de integración obligatorios para reglas críticas (cálculo de IVA/totales, descuento de stock, idempotencia, permisos RBAC y bloqueo de borrado de comprobantes).
* **Observabilidad:** Logs estructurados con el módulo `logging` (nivel, timestamp, `request_id`; prohibido loguear contraseñas o tokens) y endpoint `GET /health`.
* **Contenedores y CI:** `Dockerfile` + `docker-compose.yml` para correr API + PostgreSQL en un comando. Pipeline en GitHub Actions que corra `pytest` en cada PR y bloquee el merge si falla.

---

## 5. Reglas de Negocio y Marco Legal (Argentina / ARCA 2026)
* **Inmutabilidad Fiscal:** Una venta confirmada nunca se edita ni se borra. Cualquier corrección o anulación emite una `nota_credito` vinculada.
* **Preparación ARCA:** Discriminar `base_imponible`, `iva_21` y validar `condicion_iva_receptor` antes de confirmar. Diseñar el flujo pensando en CAE en tiempo real y contingencia CAEA sin frenar el mostrador.
* **Gastronomía:** Calcular costos de recetas contemplando **mermas** y usando **costo de reposición**.

---

## 6. Trabajo en Equipo y Reglas para Agentes de IA (Antigravity)
* **GitHub Flow:** `main` siempre estable. Trabajar en ramas cortas (`feat/...`, `fix/...`) con commits atómicos y Pull Requests chicos y revisables.
* **Prohibido Sobreingenierizar:** No introducir microservicios, Kubernetes, GraphQL, Kafka ni librerías fuera del stack oficial sin aprobación explícita.
* **Lógica Determinista:** Cálculos de dinero, impuestos, stock y cuadraturas siempre en código Python/SQL determinista, nunca delegados a un LLM.
* **Auditoría Humana:** Al generar código o SQL, respetar estrictamente estas reglas, evitar cambios masivos fuera del alcance pedido y detallar cualquier supuesto asumido.