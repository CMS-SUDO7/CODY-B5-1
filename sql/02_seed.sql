-- 고객과 주문은 모두 학습용 가상 데이터다. 이메일은 example.com을 사용한다.
-- 부모(customer, menu) → 자식(cafe_order) → 손자(order_item) 순서로 입력한다.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- customer: 10행. 값의 순서는 고객 번호, 이름, 이메일.
INSERT INTO customer (customer_id, customer_name, email)
VALUES
    (1, '김민수', 'minsu@example.com'),
    (2, '이서연', 'seoyeon@example.com'),
    (3, '박지훈', 'jihun@example.com'),
    (4, '최유진', 'yujin@example.com'),
    (5, '정하늘', 'haneul@example.com'),
    (6, '강도윤', 'doyun@example.com'),
    (7, '윤수빈', 'subin@example.com'),
    (8, '장현우', 'hyunwoo@example.com'),
    (9, '임지아', 'jia@example.com'),
    (10, '한시우', 'siwoo@example.com');

-- menu: 10행. 값의 순서는 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부.
INSERT INTO menu (menu_id, menu_name, category, price_won, is_available)
VALUES
    (1, '아메리카노', 'coffee', 4000, 1),
    (2, '카페라떼', 'coffee', 4500, 1),
    (3, '바닐라라떼', 'coffee', 5000, 1),
    (4, '카푸치노', 'coffee', 4500, 1),
    (5, '콜드브루', 'coffee', 5000, 1),
    (6, '얼그레이', 'tea', 4500, 1),
    (7, '레몬티', 'tea', 5000, 1),
    (8, '초코케이크', 'dessert', 6500, 1),
    (9, '치즈케이크', 'dessert', 6500, 1),
    (10, '버터쿠키', 'dessert', 2500, 0);

-- cafe_order: 14행. 값의 순서는 주문 번호, 고객 번호, 주문 시각, 상태.
INSERT INTO cafe_order (order_id, customer_id, ordered_at, status)
VALUES
    (1, 1, '2026-10-01 09:00:00', 'paid'),
    (2, 2, '2026-10-01 10:00:00', 'paid'),
    (3, 3, '2026-10-02 11:00:00', 'paid'),
    (4, 1, '2026-10-03 09:30:00', 'paid'),
    (5, 4, '2026-10-04 13:00:00', 'paid'),
    (6, 5, '2026-10-05 14:00:00', 'paid'),
    (7, 6, '2026-10-06 15:00:00', 'paid'),
    (8, 7, '2026-10-07 16:00:00', 'paid'),
    (9, 8, '2026-10-08 12:00:00', 'paid'),
    (10, 2, '2026-10-09 10:30:00', 'paid'),
    (11, 3, '2026-10-10 11:30:00', 'paid'),
    (12, 4, '2026-10-11 13:30:00', 'cancelled'),
    (13, 5, '2026-10-12 14:30:00', 'pending'),
    (14, 6, '2026-10-13 15:30:00', 'cancelled');

-- order_item: 23행. 값의 순서는 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가.
INSERT INTO order_item (order_item_id, order_id, menu_id, quantity, unit_price_won)
VALUES
    (1, 1, 1, 2, 4000),
    (2, 1, 8, 1, 6500),
    (3, 2, 2, 1, 4500),
    (4, 2, 10, 2, 2500),
    (5, 3, 3, 2, 5000),
    (6, 3, 9, 1, 6500),
    (7, 4, 5, 1, 5000),
    (8, 4, 10, 1, 2500),
    (9, 5, 6, 1, 4500),
    (10, 5, 8, 1, 6500),
    (11, 6, 7, 2, 5000),
    (12, 6, 9, 1, 6500),
    (13, 7, 4, 1, 4500),
    (14, 7, 10, 2, 2500),
    (15, 8, 1, 1, 4000),
    (16, 8, 8, 1, 6500),
    (17, 9, 2, 2, 4500),
    (18, 9, 9, 1, 6500),
    (19, 10, 5, 2, 5000),
    (20, 10, 10, 1, 2500),
    (21, 11, 3, 1, 5000),
    (22, 12, 6, 1, 4500),
    (23, 13, 7, 1, 5000);

-- 9·10번 고객은 주문이 없어 LEFT JOIN과 NOT EXISTS를 확인할 수 있다.
-- 14번은 상세가 없는 취소 주문으로 Q14 삭제 대상이다. 13번은 Q13 수정 대상이다.
-- 판매 중단 메뉴인 버터쿠키도 과거 주문에는 존재한다. 현재 판매 여부로 과거 주문을 지우지 않는다.
COMMIT;
