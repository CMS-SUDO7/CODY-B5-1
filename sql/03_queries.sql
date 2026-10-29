-- 핵심 쿼리 정확히 15개. 설정과 BEGIN/COMMIT은 쿼리 개수에 포함하지 않는다.
-- Q01~Q12 결과는 초기 데이터 기준이다. Q13~Q14가 바꾸므로 전체는 한 번만 실행한다.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- Q01 | 기본 조회 | 판매 가능한 5,000원 이상 메뉴를 가격이 낮은 순서로 찾는다.
SELECT menu_id, menu_name, price_won
FROM menu
WHERE is_available = 1 AND price_won >= 5000
ORDER BY price_won ASC, menu_id ASC;

-- Q02 | 기본 조회 | 이름에 라테가 들어간 메뉴를 검색한다.
SELECT menu_id, menu_name, price_won
FROM menu
WHERE menu_name LIKE '%라테%'
ORDER BY menu_id ASC;

-- Q03 | 기본 조회 | 2026년 10월 주문 중 가장 최근 주문 5건을 찾는다.
SELECT order_id, customer_id, ordered_at, status
FROM cafe_order
WHERE ordered_at >= '2026-10-01 00:00:00'
  AND ordered_at < '2026-11-01 00:00:00'
ORDER BY ordered_at DESC, order_id DESC
LIMIT 5;

-- Q04 | 기본 조회 | 결제 대기 또는 취소 상태인 주문을 찾는다.
SELECT order_id, customer_id, status
FROM cafe_order
WHERE status IN ('pending', 'cancelled')
ORDER BY order_id ASC;

-- Q05 | 조인 | 각 주문에 주문한 고객 이름을 붙인다. INNER JOIN 1.
SELECT o.order_id, c.customer_name, o.status
FROM cafe_order AS o
INNER JOIN customer AS c ON c.customer_id = o.customer_id
ORDER BY o.order_id ASC;

-- Q06 | 조인 | 상세에 메뉴 이름과 당시 단가·소계를 붙인다. INNER JOIN 2.
SELECT i.order_item_id, m.menu_name, i.quantity,
       i.unit_price_won, i.quantity * i.unit_price_won AS subtotal_won
FROM order_item AS i
INNER JOIN menu AS m ON m.menu_id = i.menu_id
ORDER BY i.order_item_id ASC;

-- Q07 | 조인 | 주문이 없는 고객까지 포함해 고객과 주문을 확인한다. LEFT JOIN.
SELECT c.customer_id, c.customer_name, o.order_id, o.status
FROM customer AS c
LEFT JOIN cafe_order AS o ON o.customer_id = c.customer_id
ORDER BY c.customer_id ASC, o.order_id ASC;

-- Q08 | 조인 | 1번 고객의 결제 완료 주문에 담긴 메뉴와 수량을 확인한다.
SELECT c.customer_name, o.order_id, m.menu_name, i.quantity
FROM customer AS c
INNER JOIN cafe_order AS o ON o.customer_id = c.customer_id
INNER JOIN order_item AS i ON i.order_id = o.order_id
INNER JOIN menu AS m ON m.menu_id = i.menu_id
WHERE c.customer_id = 1 AND o.status = 'paid'
ORDER BY o.order_id ASC, i.order_item_id ASC;

-- Q09 | 집계 | 상태별 주문 건수를 센다. COUNT + GROUP BY.
SELECT status, COUNT(*) AS order_count
FROM cafe_order
GROUP BY status
ORDER BY status ASC;

-- Q10 | 집계 | 결제 완료 주문의 고객별 구매액을 많은 순서로 정렬한다. SUM + GROUP BY.
SELECT c.customer_id, c.customer_name,
       SUM(i.quantity * i.unit_price_won) AS total_paid_won
FROM customer AS c
INNER JOIN cafe_order AS o ON o.customer_id = c.customer_id
INNER JOIN order_item AS i ON i.order_id = o.order_id
WHERE o.status = 'paid'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_paid_won DESC, c.customer_id ASC;

-- Q11 | 집계 | 판매 가능한 메뉴의 분류별 평균 가격을 구한다. AVG + GROUP BY.
SELECT category, ROUND(AVG(price_won), 2) AS average_price_won
FROM menu
WHERE is_available = 1
GROUP BY category
ORDER BY category ASC;

-- Q12 | 서브쿼리 | 주문 기록이 한 번도 없는 고객을 찾는다. NOT EXISTS.
SELECT c.customer_id, c.customer_name
FROM customer AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM cafe_order AS o
    WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id ASC;

-- Q13 | 수정 | 13번 주문이 결제 대기일 때만 결제 완료로 바꾼다.
UPDATE cafe_order
SET status = 'paid'
WHERE order_id = 13 AND status = 'pending';

-- Q14 | 삭제 | 상세가 없는 14번 취소 주문을 삭제한다.
DELETE FROM cafe_order
WHERE order_id = 14 AND status = 'cancelled';

-- Q15 | 인덱스 | 최근 주문 검색의 시각 범위와 정렬을 지원하는 인덱스를 만든다.
CREATE INDEX IF NOT EXISTS idx_cafe_order_recent
ON cafe_order (ordered_at DESC, order_id DESC);

COMMIT;
