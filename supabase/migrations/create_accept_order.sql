-- ВАЖНО: Выполните этот SQL скрипт в Supabase Dashboard -> SQL Editor
-- Этот скрипт создает функцию accept_order, которая нужна для принятия заказов.

CREATE OR REPLACE FUNCTION accept_order(order_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_product_id uuid;
  v_quantity int;
  v_current_stock int;
BEGIN
  -- 1. Получаем данные заказа
  SELECT product_id, quantity INTO v_product_id, v_quantity
  FROM orders
  WHERE id = order_id;

  -- Проверка: существует ли заказ
  IF v_product_id IS NULL THEN
    RAISE EXCEPTION 'Заказ не найден';
  END IF;

  -- 2. Получаем текущее количество товара на складе
  SELECT quantity INTO v_current_stock
  FROM products
  WHERE id = v_product_id;

  -- Проверка: существует ли товар
  IF v_current_stock IS NULL THEN
    RAISE EXCEPTION 'Товар не найден';
  END IF;

  -- 3. Проверка: достаточно ли товара
  IF v_current_stock < v_quantity THEN
    RAISE EXCEPTION 'Недостаточно товара на складе. Доступно: %, Требуется: %', v_current_stock, v_quantity;
  END IF;

  -- 4. Списываем товар
  UPDATE products
  SET quantity = quantity - v_quantity
  WHERE id = v_product_id;

  -- 5. Обновляем статус заказа
  UPDATE orders
  SET status = 'accepted'
  WHERE id = order_id;
END;
$$;
