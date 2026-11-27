-- ============================================================================
-- MAY DELICIAS - GESTIÓN GASTRONÓMICA
-- Archivo: db/02_seed.sql
-- Datos iniciales realistas para desarrollo y pruebas
-- Cumplimiento: ESTANDARES_Y_REGLAS_PROYECTO.md
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. CATEGORÍAS
-- ----------------------------------------------------------------------------
INSERT INTO categorias (nombre, descripcion) VALUES
('Insumos y Materias Primas', 'Harinas, carnes, verduras, condimentos y materias primas para producción'),
('Empanadas Tradicionales', 'Empanadas artesanales elaboradas al horno y fritas'),
('Tartas y Comidas Caseras', 'Tartas saladas familiares y porciones individuales');

-- ----------------------------------------------------------------------------
-- 2. CLIENTES
-- ----------------------------------------------------------------------------
INSERT INTO clientes (nombre, telefono, email, cuit_cuil, condicion_iva, direccion) VALUES
('Mariano Gómez', '+54 11 4567-8901', 'mariano.gomez@email.com', '20-35441238-9', 'Consumidor Final', 'Av. Rivadavia 4820, Caballito, CABA'),
('Distribuidora San Telmo SRL', '+54 11 5432-1098', 'compras@santelmosrl.com.ar', '30-71458923-4', 'Responsable Inscripto', 'Defensa 450, San Telmo, CABA');

-- ----------------------------------------------------------------------------
-- 3. PRODUCTOS (Insumos y Elaborados)
-- IDs esperados secuenciales:
-- 1: Carne Picada Especial (insumo)
-- 2: Harina de Trigo 0000 (insumo)
-- 3: Cebolla Blanca (insumo)
-- 4: Huevo de Campo (insumo)
-- 5: Grasa Vacuna Refinada (insumo)
-- 6: Docena Empanadas Criollas de Carne (elaborado)
-- 7: Tarta Pascualina Tradicional (elaborado)
-- 8: Tarta Jamón y Queso Casera (elaborado)
-- ----------------------------------------------------------------------------
INSERT INTO productos (sku, nombre, descripcion, tipo, categoria_id, precio_venta, costo_unitario, stock_actual, stock_minimo, unidad_medida) VALUES
-- Insumos
('INS-CARNE-001', 'Carne Picada Especial', 'Carne vacuna seleccionada magra para relleno', 'insumo', 1, 0.00, 6500.00, 38.5000, 10.0000, 'kg'),
('INS-HARINA-001', 'Harina de Trigo 0000', 'Harina de fuerza cuatro ceros para masas finas', 'insumo', 1, 0.00, 1200.00, 58.9500, 15.0000, 'kg'),
('INS-CEBOLLA-001', 'Cebolla Blanca', 'Cebolla común seleccionada para picar', 'insumo', 1, 0.00, 1100.00, 33.6500, 8.0000, 'kg'),
('INS-HUEVO-001', 'Huevo de Campo', 'Huevo fresco de gallina colorado', 'insumo', 1, 0.00, 220.00, 144.0000, 30.0000, 'unidad'),
('INS-GRASA-001', 'Grasa Vacuna Refinada', 'Grasa pella purificada para masa criolla y hojaldrada', 'insumo', 1, 0.00, 2800.00, 19.7000, 5.0000, 'kg'),
-- Productos Elaborados
('ELA-EMP-CARNE', 'Docena Empanadas Criollas de Carne', '12 empanadas de carne a cuchillo cortadas a mano', 'elaborado', 2, 14400.00, 5850.00, 22.0000, 5.0000, 'docena'),
('ELA-TAR-PASC', 'Tarta Pascualina Tradicional', 'Tarta familiar de acelga fresca, queso y huevo duro', 'elaborado', 3, 11500.00, 4200.00, 9.0000, 3.0000, 'unidad'),
('ELA-TAR-JYQ', 'Tarta Jamón y Queso Casera', 'Tarta con abundante muzzarella, jamón cocido y ligue', 'elaborado', 3, 13200.00, 5100.00, 6.0000, 2.0000, 'unidad');

-- ----------------------------------------------------------------------------
-- 4. RECETA CON MERMA
-- Para: 'Docena Empanadas Criollas de Carne' (producto_id = 6)
-- Considera merma por desgrase, cocción/sellado y pelado de verduras.
-- ----------------------------------------------------------------------------
INSERT INTO receta_insumos (producto_id, insumo_id, cantidad_requerida, merma_pct) VALUES
(6, 1, 0.5000, 12.00), -- 500g carne con 12% merma por cocción/desgrase
(6, 3, 0.4500, 15.00), -- 450g cebolla con 15% merma por pelado y rehogado
(6, 2, 0.3500,  5.00), -- 350g harina masa con 5% merma en mesa
(6, 5, 0.1000,  2.00), -- 100g grasa vacuna derretida con 2% merma
(6, 4, 2.0000,  0.00); -- 2 huevos duros picados sin merma

-- ----------------------------------------------------------------------------
-- 5. MOVIMIENTOS DE STOCK (Carga inicial / compras de insumos y elaboración)
-- ----------------------------------------------------------------------------
INSERT INTO movimientos_stock (producto_id, tipo, cantidad, saldo_resultante, venta_id, motivo, fecha_creacion) VALUES
(1, 'entrada', 40.0000, 40.0000, NULL, 'Compra inicial de carne según Factura Proveedor A-102', NOW() - INTERVAL '2 days'),
(2, 'entrada', 60.0000, 60.0000, NULL, 'Compra inicial de harina según Factura Proveedor A-103', NOW() - INTERVAL '2 days'),
(3, 'entrada', 35.0000, 35.0000, NULL, 'Compra inicial de verduras del Mercado Central', NOW() - INTERVAL '2 days'),
(4, 'entrada', 150.0000, 150.0000, NULL, 'Cajón de huevos frescos de granja', NOW() - INTERVAL '2 days'),
(5, 'entrada', 20.0000, 20.0000, NULL, 'Compra inicial de grasa vacuna', NOW() - INTERVAL '2 days'),
(6, 'entrada', 25.0000, 25.0000, NULL, 'Producción lote mañana - 25 docenas empanadas criollas', NOW() - INTERVAL '1 day'),
(7, 'entrada', 10.0000, 10.0000, NULL, 'Producción lote mañana - 10 tartas pascualinas', NOW() - INTERVAL '1 day'),
(8, 'entrada', 8.0000, 8.0000, NULL, 'Producción lote mañana - 8 tartas jamón y queso', NOW() - INTERVAL '1 day');

-- ----------------------------------------------------------------------------
-- 6. VENTAS
-- Venta 1: Mostrador / Consumidor Final sin registrar (cliente_id = NULL)
-- Venta 2: Cliente registrado particular (cliente_id = 1, Mariano Gómez)
-- Venta 3: Cliente corporativo Responsable Inscripto (cliente_id = 2, Distribuidora San Telmo SRL)
-- ----------------------------------------------------------------------------
INSERT INTO ventas (cliente_id, numero_comprobante, tipo_comprobante, condicion_iva_receptor, metodo_pago, base_imponible, iva_21, total, clave_idempotencia, observaciones, fecha_creacion) VALUES
(
    NULL,
    'TK-0001-00000001',
    'Ticket Mostrador',
    'Consumidor Final',
    'efectivo',
    11900.83,
    2499.17,
    14400.00,
    'IDEMP-POS1-20261127-0001',
    'Venta rápida en mostrador turno tarde',
    NOW() - INTERVAL '4 hours'
),
(
    1,
    'FB-0001-00000001',
    'Factura B',
    'Consumidor Final',
    'transferencia',
    33305.79,
    6994.21,
    40300.00,
    'IDEMP-POS1-20261127-0002',
    'Pedido telefónico para entrega a domicilio',
    NOW() - INTERVAL '2 hours'
),
(
    2,
    'FA-0001-00000001',
    'Factura A',
    'Responsable Inscripto',
    'debito',
    21818.18,
    4581.82,
    26400.00,
    'IDEMP-POS1-20261127-0003',
    'Catering almuerzo corporativo',
    NOW() - INTERVAL '30 minutes'
);

-- ----------------------------------------------------------------------------
-- 7. DETALLE DE VENTAS (venta_items con precio congelado)
-- ----------------------------------------------------------------------------
INSERT INTO venta_items (venta_id, producto_id, cantidad, precio_unitario, subtotal, fecha_creacion) VALUES
-- Items Venta 1 (Total: $14.400,00)
(1, 6, 1.0000, 14400.00, 14400.00, NOW() - INTERVAL '4 hours'),

-- Items Venta 2 (2 docenas empanadas + 1 tarta pascualina = $28.800 + $11.500 = $40.300,00)
(2, 6, 2.0000, 14400.00, 28800.00, NOW() - INTERVAL '2 hours'),
(2, 7, 1.0000, 11500.00, 11500.00, NOW() - INTERVAL '2 hours'),

-- Items Venta 3 (2 tartas jamón y queso = 2 * $13.200 = $26.400,00)
(3, 8, 2.0000, 13200.00, 26400.00, NOW() - INTERVAL '30 minutes');

-- ----------------------------------------------------------------------------
-- 8. MOVIMIENTOS DE STOCK POR VENTAS (Salidas vinculadas a venta_id)
-- Descuentan del stock de elaborados hasta el saldo actual reflejado en productos.
-- ----------------------------------------------------------------------------
INSERT INTO movimientos_stock (producto_id, tipo, cantidad, saldo_resultante, venta_id, motivo, fecha_creacion) VALUES
(6, 'salida', 1.0000, 24.0000, 1, 'Despacho por Venta TK-0001-00000001', NOW() - INTERVAL '4 hours'),
(6, 'salida', 2.0000, 22.0000, 2, 'Despacho por Venta FB-0001-00000001', NOW() - INTERVAL '2 hours'),
(7, 'salida', 1.0000,  9.0000, 2, 'Despacho por Venta FB-0001-00000001', NOW() - INTERVAL '2 hours'),
(8, 'salida', 2.0000,  6.0000, 3, 'Despacho por Venta FA-0001-00000001', NOW() - INTERVAL '30 minutes');

-- ----------------------------------------------------------------------------
-- 9. NOTAS DE CRÉDITO (Ejemplo de anulación/ajuste contable append-only)
-- Se deja lista una nota de crédito de demostración sobre una venta previa simulada
-- o como referencia documental del modelo.
-- ----------------------------------------------------------------------------
-- INSERT INTO notas_credito (venta_id, numero_comprobante, motivo, total, fecha_creacion)
-- VALUES (1, 'NC-0001-00000001', 'Anulación por error en comprobante de mostrador', 14400.00, NOW());

COMMIT;
