-- ============================================================================
-- MAY DELICIAS - GESTIÓN GASTRONÓMICA
-- Archivo: db/01_schema.sql
-- Motor: PostgreSQL 15+
-- Arquitectura: Single-tenant, 3FN, Append-Only transaccional, Soft-delete maestras
-- Cumplimiento: ESTANDARES_Y_REGLAS_PROYECTO.md
--
-- NOTA DE EJECUCIÓN:
-- Conectarse primero a la base de datos 'may_delicias' antes de correr este script.
--
-- Si necesitás reiniciar las tablas desde cero, podés ejecutar previamente:
-- DROP TABLE IF EXISTS notas_credito, movimientos_stock, venta_items, ventas, receta_insumos, productos, clientes, categorias CASCADE;
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. TABLA: categorias
-- Tipo: Maestra (Soft Delete)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorias (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    eliminado_en TIMESTAMPTZ NULL
);

-- ----------------------------------------------------------------------------
-- 2. TABLA: clientes
-- Tipo: Maestra (Soft Delete)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(50) NULL,
    email VARCHAR(150) NULL,
    cuit_cuil VARCHAR(20) NULL,
    condicion_iva VARCHAR(50) NOT NULL DEFAULT 'Consumidor Final',
    direccion TEXT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    eliminado_en TIMESTAMPTZ NULL
);

-- ----------------------------------------------------------------------------
-- 3. TABLA: productos
-- Tipo: Maestra (Soft Delete)
-- Observaciones: Almacena insumos y productos elaborados gastronómicos.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS productos (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('insumo', 'elaborado')),
    categoria_id INT NOT NULL REFERENCES categorias(id) ON DELETE RESTRICT,
    precio_venta NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (precio_venta >= 0),
    costo_unitario NUMERIC(12,2) NULL CHECK (costo_unitario IS NULL OR costo_unitario >= 0),
    stock_actual NUMERIC(12,4) NOT NULL DEFAULT 0.0000 CHECK (stock_actual >= 0),
    stock_minimo NUMERIC(12,4) NOT NULL DEFAULT 0.0000 CHECK (stock_minimo >= 0),
    unidad_medida VARCHAR(20) NOT NULL DEFAULT 'unidad',
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    eliminado_en TIMESTAMPTZ NULL
);

-- ----------------------------------------------------------------------------
-- 4. TABLA: receta_insumos
-- Tipo: Relación N:M (Elaborados -> Insumos con merma técnica de cocina)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS receta_insumos (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    producto_id INT NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    insumo_id INT NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad_requerida NUMERIC(12,4) NOT NULL CHECK (cantidad_requerida > 0),
    merma_pct NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (merma_pct >= 0 AND merma_pct < 100),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_receta_producto_insumo UNIQUE (producto_id, insumo_id),
    CONSTRAINT chk_receta_distintos CHECK (producto_id <> insumo_id)
);

-- ----------------------------------------------------------------------------
-- 5. TABLA: ventas
-- Tipo: Transaccional / Financiera (Append-Only)
-- Observaciones: Preparada para ARCA 2026 con base imponible e IVA discriminados.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ventas (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id INT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    numero_comprobante VARCHAR(50) NOT NULL UNIQUE,
    tipo_comprobante VARCHAR(20) NOT NULL DEFAULT 'Factura B',
    condicion_iva_receptor VARCHAR(50) NOT NULL DEFAULT 'Consumidor Final',
    metodo_pago VARCHAR(50) NOT NULL,
    base_imponible NUMERIC(12,2) NOT NULL CHECK (base_imponible >= 0),
    iva_21 NUMERIC(12,2) NOT NULL CHECK (iva_21 >= 0),
    total NUMERIC(12,2) NOT NULL CHECK (total >= 0),
    clave_idempotencia VARCHAR(100) NULL UNIQUE,
    observaciones TEXT NULL,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 6. TABLA: venta_items
-- Tipo: Transaccional (Append-Only)
-- Observaciones: Congela precio_unitario al momento de la venta (excepción 3FN).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS venta_items (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venta_id INT NOT NULL REFERENCES ventas(id) ON DELETE RESTRICT,
    producto_id INT NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad NUMERIC(12,4) NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 7. TABLA: movimientos_stock
-- Tipo: Transaccional / Inventario (Append-Only)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS movimientos_stock (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    producto_id INT NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('entrada', 'salida', 'ajuste')),
    cantidad NUMERIC(12,4) NOT NULL CHECK (cantidad > 0),
    saldo_resultante NUMERIC(12,4) NOT NULL CHECK (saldo_resultante >= 0),
    venta_id INT NULL REFERENCES ventas(id) ON DELETE RESTRICT,
    motivo VARCHAR(255) NOT NULL,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 8. TABLA: notas_credito
-- Tipo: Contable / Fiscal (Append-Only)
-- Observaciones: Permite anulación o compensación de ventas cerradas.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notas_credito (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venta_id INT NOT NULL REFERENCES ventas(id) ON DELETE RESTRICT,
    numero_comprobante VARCHAR(50) NOT NULL UNIQUE,
    motivo TEXT NOT NULL,
    total NUMERIC(12,2) NOT NULL CHECK (total > 0),
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- ÍNDICES PARA CLAVES FORÁNEAS Y CONSULTAS FRECUENTES
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_productos_categoria_id ON productos(categoria_id);
CREATE INDEX IF NOT EXISTS idx_productos_tipo ON productos(tipo);
CREATE INDEX IF NOT EXISTS idx_receta_insumos_producto_id ON receta_insumos(producto_id);
CREATE INDEX IF NOT EXISTS idx_receta_insumos_insumo_id ON receta_insumos(insumo_id);
CREATE INDEX IF NOT EXISTS idx_ventas_cliente_id ON ventas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_ventas_fecha_creacion ON ventas(fecha_creacion);
CREATE INDEX IF NOT EXISTS idx_venta_items_venta_id ON venta_items(venta_id);
CREATE INDEX IF NOT EXISTS idx_venta_items_producto_id ON venta_items(producto_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_stock_producto_id ON movimientos_stock(producto_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_stock_venta_id ON movimientos_stock(venta_id);
CREATE INDEX IF NOT EXISTS idx_notas_credito_venta_id ON notas_credito(venta_id);

COMMIT;
