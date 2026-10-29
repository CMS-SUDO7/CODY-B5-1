-- 카페 주문 DB / SQLite 전용: PRAGMA와 INTEGER PRIMARY KEY의 rowid 연결.
-- 빈 DB에서 한 번 실행한다. 기존 테이블을 삭제하지 않는다.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- 고객 이름은 중복 가능하지만 이메일은 고객을 구별하므로 중복을 막는다.
CREATE TABLE customer (
    customer_id INTEGER PRIMARY KEY,
    customer_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE
);

-- 원 단위 정수로 금액을 저장해 부동소수점 반올림 오차를 피한다.
CREATE TABLE menu (
    menu_id INTEGER PRIMARY KEY,
    menu_name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL CHECK (category IN ('coffee', 'tea', 'dessert')),
    price_won INTEGER NOT NULL CHECK (price_won >= 0),
    is_available INTEGER NOT NULL CHECK (is_available IN (0, 1))
);

-- customer 1명은 cafe_order 여러 건을 가질 수 있다. 날짜는 ISO 형식으로 저장한다.
CREATE TABLE cafe_order (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    ordered_at TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('paid', 'pending', 'cancelled')),
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id) ON DELETE RESTRICT
);

-- 주문 1건에는 상세 여러 줄, 메뉴 1개도 여러 상세에서 참조된다.
-- unit_price_won은 주문 당시 가격이다. 현재 메뉴 가격이 바뀌어도 과거 결제액을 보존한다.
CREATE TABLE order_item (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    menu_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_won INTEGER NOT NULL CHECK (unit_price_won >= 0),
    UNIQUE (order_id, menu_id),
    FOREIGN KEY (order_id) REFERENCES cafe_order (order_id) ON DELETE RESTRICT,
    FOREIGN KEY (menu_id) REFERENCES menu (menu_id) ON DELETE RESTRICT
);

COMMIT;
