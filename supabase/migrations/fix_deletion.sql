-- ВАЖНО: Выполните этот SQL скрипт в Supabase Dashboard -> SQL Editor
-- Это исправит ошибку удаления товаров, на которые есть заказы.

-- ВАРИАНТ 1 (Рекомендуемый): Настройка каскадного удаления
-- При удалении товара, все связанные заказы удалятся автоматически.
ALTER TABLE orders
DROP CONSTRAINT IF EXISTS orders_product_id_fkey;

ALTER TABLE orders
ADD CONSTRAINT orders_product_id_fkey
    FOREIGN KEY (product_id)
    REFERENCES products(id)
    ON DELETE CASCADE;

-- ВАРИАНТ 2 (Если вы хотите использовать RPC функцию): Исправление ошибки "ambiguous column"
-- Сначала удаляем старую функцию, так как PostgreSQL не разрешает менять имена параметров через REPLACE
DROP FUNCTION IF EXISTS delete_product_with_orders(uuid);

-- Теперь создаем исправленную версию
CREATE OR REPLACE FUNCTION delete_product_with_orders(target_product_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Удаляем заказы
  DELETE FROM orders WHERE product_id = target_product_id;
  -- Удаляем продукт
  DELETE FROM products WHERE id = target_product_id;
END;
$$;
