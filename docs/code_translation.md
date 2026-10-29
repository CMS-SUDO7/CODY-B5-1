# SQL 코드·명령 해설

## 1. 전체 구조와 실행 시작점

실행 시작점은 새 SQLite DB에서 `sql/01_schema.sql`을 실행하는 것이다. 스키마 → 샘플 → 핵심 쿼리 순서로 실행한다. 이미 채워진 `data/cafe.db`를 사용하면 핵심 쿼리부터 시작한다. 파일끼리 함수를 호출하는 구조가 아니라, 앞 파일이 만든 DB 상태를 다음 파일이 사용하는 구조다.

| 파일 | 입력 | 출력·DB 상태 변화 | 주요 오류 |
| --- | --- | --- | --- |
| 01_schema.sql | 빈 SQLite DB | 테이블 4개·제약조건 생성 | 기존 테이블명 충돌, 트랜잭션 중첩 |
| 02_seed.sql | 생성된 스키마 | 10·10·14·23행 저장 | 중복값, FK, CHECK 위반 |
| 03_queries.sql Q01~Q12 | 초기 데이터 | 조회 결과 행. 저장 데이터는 바꾸지 않음 | 테이블·열 이름 오류 |
| Q13 | 13번 pending 주문 | 상태를 paid로 바꿈 | 조건 미일치면 변경 0행 |
| Q14 | 상세 없는 14번 취소 주문 | 주문 1행 삭제 | 상세가 있으면 FK RESTRICT로 차단 |
| Q15 | cafe_order 구조 | 검색용 인덱스 생성 | 잘못된 열 이름 등 |

SELECT는 결과 행을 SQL 도구에 반환한다. 도구가 화면에 출력하거나 파일에 기록한다. UPDATE·DELETE·CREATE INDEX는 이 소스에서는 결과 표를 반환하지 않으므로 별도 조회와 변경 행 수로 확인했다. SQL은 명령 실행 시 바로 동작하며 나중에 호출할 함수를 선언한 코드가 아니다.

## 2. 실제 입력을 따라가는 예

### Q08의 네 테이블 JOIN

[README의 Q08 해설](../README.md#q08-고객의-결제-완료-주문에-담긴-메뉴-찾기)에서 고객 조회 → 결제 완료 주문 조회 → 상세 연결 → 메뉴 이름 연결 순서로 SQL과 중간 결과를 비교합니다. 고객 1행에서 주문 2행, 상세 4행으로 이어지는 과정을 확인할 수 있습니다.

### 1번 고객 구매액, Q10

1. customer의 `(1, 김민수)`에 고객 번호 1인 주문 1·4가 연결된다.
2. 주문 1에는 아메리카노 2개 × 4,000원, 초코케이크 1개 × 6,500원이 있다. 소계는 14,500원이다.
3. 주문 4에는 콜드브루 1개 × 5,000원, 버터쿠키 1개 × 2,500원이 있다. 소계는 7,500원이다.
4. 두 주문은 paid라 WHERE를 통과한다. 고객 번호·이름으로 묶고 SUM하면 22,000원을 반환한다. 현재 판매 중단인 버터쿠키도 과거 유효 구매액에는 포함된다.

### Q13과 Q14 상태 변화

Q13은 주문 번호 13과 상태 pending을 동시에 만족하는 한 행을 찾고 paid로 바꾼다. 초기 상태를 다시 만들지 않고 재실행하면 pending이 아니므로 변경 0행이다. 주문 13의 상세와 수량은 바뀌지 않는다.

Q14는 주문 번호 14와 cancelled를 만족하는 한 행을 삭제한다. 샘플의 14번에는 상세가 없어 성공한다. 1번처럼 상세가 있는 주문을 삭제하려 하면 order_item의 FK가 막는다. COMMIT 후 초기 상태로 돌아가려면 새 DB에 01·02를 실행한다.

## 3. 줄별 표의 기준

아래는 **최종 SQL 파일을 실제 읽어 얻은 원본 줄 번호**다. 빈 줄·순수 `--` 주석·괄호와 구분 기호만 있는 줄은 제외한다. 여러 줄 SQL도 의미 있는 각 줄을 하나씩 해설한다. 순수 주석으로 적힌 쿼리 목적은 소스에 남아 있고, 코드와 데이터는 생략하지 않았다. `VALUES`의 각 행은 입력 열 순서와 실제 값을 개별 설명한다. 각 파일 표의 줄 번호는 그 파일 안에서 센다.

## sql/01_schema.sql

| 원본 줄 번호 | 해당 코드 | 쉬운 설명 |
| --- | --- | --- |
| 3 | <code>PRAGMA foreign_keys = ON;</code> | SQLite 전용 설정이다. 이 연결에서 없는 부모를 참조하는 입력을 차단한다. 트랜잭션을 시작하기 전에 실행한다. |
| 4 | <code>BEGIN TRANSACTION;</code> | 여러 테이블 생성을 하나의 작업으로 묶는다. 모두 성공하면 마지막 COMMIT으로 확정한다. |
| 7 | <code>CREATE TABLE customer (</code> | 고객 정보를 담는 customer 테이블을 만든다. |
| 8 | <code>    customer_id INTEGER PRIMARY KEY,</code> | 고객 번호를 정수 기본 키로 선언한다. SQLite에서는 rowid와 연결되어 중복이 차단된다. |
| 9 | <code>    customer_name TEXT NOT NULL,</code> | 고객 이름은 문자열이고 NULL을 허용하지 않는다. 빈 문자열까지 막는 규칙은 아니다. |
| 10 | <code>    email TEXT NOT NULL UNIQUE</code> | 이메일은 필수 문자열이며 같은 이메일을 두 번 저장할 수 없다. |
| 14 | <code>CREATE TABLE menu (</code> | 현재 판매 메뉴를 관리하는 menu 테이블을 만든다. |
| 15 | <code>    menu_id INTEGER PRIMARY KEY,</code> | 각 메뉴를 구별하는 정수 기본 키다. |
| 16 | <code>    menu_name TEXT NOT NULL UNIQUE,</code> | 메뉴 이름은 필수이고 같은 이름의 중복 등록을 막는다. |
| 17 | <code>    category TEXT NOT NULL CHECK (category IN (&#x27;coffee&#x27;, &#x27;tea&#x27;, &#x27;dessert&#x27;)),</code> | 분류는 coffee·tea·dessert 중 하나여야 한다. CHECK가 허용 목록 밖의 값을 차단한다. |
| 18 | <code>    price_won INTEGER NOT NULL CHECK (price_won &gt;= 0),</code> | 메뉴의 현재 가격을 원 단위 정수로 저장하고 음수 가격을 막는다. |
| 19 | <code>    is_available INTEGER NOT NULL CHECK (is_available IN (0, 1))</code> | SQLite의 별도 불리언 저장형 대신 0은 판매 중단, 1은 판매 가능이라는 규칙을 적용한다. |
| 23 | <code>CREATE TABLE cafe_order (</code> | 주문 머리 정보를 담는 cafe_order 테이블을 만든다. 예약어 ORDER와 혼동하지 않는 이름이다. |
| 24 | <code>    order_id INTEGER PRIMARY KEY,</code> | 각 주문을 구별하는 정수 기본 키다. |
| 25 | <code>    customer_id INTEGER NOT NULL,</code> | 이 주문을 넣은 고객 번호다. NULL을 금지하므로 익명 주문은 다루지 않는다. |
| 26 | <code>    ordered_at TEXT NOT NULL,</code> | 주문 시각을 YYYY-MM-DD HH:MM:SS 문자열로 저장한다. SQLite의 TEXT 사용이며 형식 자체를 검사하는 제약은 없다. |
| 27 | <code>    status TEXT NOT NULL CHECK (status IN (&#x27;paid&#x27;, &#x27;pending&#x27;, &#x27;cancelled&#x27;)),</code> | 주문 상태를 결제 완료·결제 대기·취소의 세 값으로 제한한다. |
| 28 | <code>    FOREIGN KEY (customer_id) REFERENCES customer (customer_id) ON DELETE RESTRICT</code> | 주문의 고객 번호는 실제 customer에 있어야 한다. 주문이 남은 고객을 삭제하면 RESTRICT가 거부한다. |
| 33 | <code>CREATE TABLE order_item (</code> | 주문에 들어간 메뉴별 수량과 당시 가격을 order_item에 저장한다. |
| 34 | <code>    order_item_id INTEGER PRIMARY KEY,</code> | 상세 한 줄을 구별하는 기본 키다. |
| 35 | <code>    order_id INTEGER NOT NULL,</code> | 상세가 속한 주문 번호를 필수로 저장한다. |
| 36 | <code>    menu_id INTEGER NOT NULL,</code> | 어떤 메뉴를 주문했는지 메뉴 번호를 필수로 저장한다. |
| 37 | <code>    quantity INTEGER NOT NULL CHECK (quantity &gt; 0),</code> | 수량은 양수여야 한다. 0개나 음수 개수의 상세를 막는다. |
| 38 | <code>    unit_price_won INTEGER NOT NULL CHECK (unit_price_won &gt;= 0),</code> | 주문 당시 단가를 원 단위로 저장하고 음수를 차단한다. |
| 39 | <code>    UNIQUE (order_id, menu_id),</code> | 하나의 주문에 같은 메뉴를 두 줄 등록하지 않는다. 같은 메뉴 여러 개는 quantity에 합친다. |
| 40 | <code>    FOREIGN KEY (order_id) REFERENCES cafe_order (order_id) ON DELETE RESTRICT,</code> | 실제로 존재하는 주문만 참조할 수 있다. 상세가 있는 주문을 삭제하면 차단한다. |
| 41 | <code>    FOREIGN KEY (menu_id) REFERENCES menu (menu_id) ON DELETE RESTRICT</code> | 실제로 존재하는 메뉴만 참조할 수 있다. 과거 주문 상세가 있는 메뉴를 삭제하면 차단한다. |
| 44 | <code>COMMIT;</code> | 네 테이블 생성 작업을 확정한다. 오류가 났다면 확정하지 말고 ROLLBACK으로 되돌린 뒤 새 DB에서 원인을 고친다. |

## sql/02_seed.sql

| 원본 줄 번호 | 해당 코드 | 쉬운 설명 |
| --- | --- | --- |
| 3 | <code>PRAGMA foreign_keys = ON;</code> | 새 연결에서도 외래 키 검사를 켠다. 트랜잭션 밖에서 실행해야 적용된다. |
| 4 | <code>BEGIN TRANSACTION;</code> | 샘플 데이터 전체를 하나의 트랜잭션으로 묶어 함께 저장한다. |
| 7 | <code>INSERT INTO customer (customer_id, customer_name, email)</code> | customer에 넣을 열의 순서를 명시한다. 뒤의 각 값은 이 순서와 일치해야 한다. |
| 8 | <code>VALUES</code> | 여러 행을 한 번의 INSERT로 입력할 값 목록을 시작한다. |
| 9 | <code>    (1, &#x27;김민수&#x27;, &#x27;minsu@example.com&#x27;),</code> | 고객 번호, 이름, 이메일 순서로 1 / 김민수 / minsu@example.com을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 10 | <code>    (2, &#x27;이서연&#x27;, &#x27;seoyeon@example.com&#x27;),</code> | 고객 번호, 이름, 이메일 순서로 2 / 이서연 / seoyeon@example.com을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 11 | <code>    (3, &#x27;박지훈&#x27;, &#x27;jihun@example.com&#x27;),</code> | 고객 번호, 이름, 이메일 순서로 3 / 박지훈 / jihun@example.com을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 12 | <code>    (4, &#x27;최유진&#x27;, &#x27;yujin@example.com&#x27;),</code> | 고객 번호, 이름, 이메일 순서로 4 / 최유진 / yujin@example.com을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 13 | <code>    (5, &#x27;정하늘&#x27;, &#x27;haneul@example.com&#x27;),</code> | 고객 번호, 이름, 이메일 순서로 5 / 정하늘 / haneul@example.com을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 14 | <code>    (6, &#x27;강도윤&#x27;, &#x27;doyun@example.com&#x27;),</code> | 고객 번호, 이름, 이메일 순서로 6 / 강도윤 / doyun@example.com을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 15 | <code>    (7, &#x27;윤수빈&#x27;, &#x27;subin@example.com&#x27;),</code> | 고객 번호, 이름, 이메일 순서로 7 / 윤수빈 / subin@example.com을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 16 | <code>    (8, &#x27;장현우&#x27;, &#x27;hyunwoo@example.com&#x27;),</code> | 고객 번호, 이름, 이메일 순서로 8 / 장현우 / hyunwoo@example.com을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 17 | <code>    (9, &#x27;임지아&#x27;, &#x27;jia@example.com&#x27;),</code> | 고객 번호, 이름, 이메일 순서로 9 / 임지아 / jia@example.com을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 18 | <code>    (10, &#x27;한시우&#x27;, &#x27;siwoo@example.com&#x27;);</code> | 고객 번호, 이름, 이메일 순서로 10 / 한시우 / siwoo@example.com을 저장한다. 마지막 행의 세미콜론으로 INSERT를 끝낸다. |
| 21 | <code>INSERT INTO menu (menu_id, menu_name, category, price_won, is_available)</code> | menu에 넣을 열의 순서를 명시한다. 뒤의 각 값은 이 순서와 일치해야 한다. |
| 22 | <code>VALUES</code> | 여러 행을 한 번의 INSERT로 입력할 값 목록을 시작한다. |
| 23 | <code>    (1, &#x27;아메리카노&#x27;, &#x27;coffee&#x27;, 4000, 1),</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 1 / 아메리카노 / coffee / 4000 / 1을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 24 | <code>    (2, &#x27;카페라떼&#x27;, &#x27;coffee&#x27;, 4500, 1),</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 2 / 카페라떼 / coffee / 4500 / 1을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 25 | <code>    (3, &#x27;바닐라라떼&#x27;, &#x27;coffee&#x27;, 5000, 1),</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 3 / 바닐라라떼 / coffee / 5000 / 1을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 26 | <code>    (4, &#x27;카푸치노&#x27;, &#x27;coffee&#x27;, 4500, 1),</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 4 / 카푸치노 / coffee / 4500 / 1을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 27 | <code>    (5, &#x27;콜드브루&#x27;, &#x27;coffee&#x27;, 5000, 1),</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 5 / 콜드브루 / coffee / 5000 / 1을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 28 | <code>    (6, &#x27;얼그레이&#x27;, &#x27;tea&#x27;, 4500, 1),</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 6 / 얼그레이 / tea / 4500 / 1을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 29 | <code>    (7, &#x27;레몬티&#x27;, &#x27;tea&#x27;, 5000, 1),</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 7 / 레몬티 / tea / 5000 / 1을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 30 | <code>    (8, &#x27;초코케이크&#x27;, &#x27;dessert&#x27;, 6500, 1),</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 8 / 초코케이크 / dessert / 6500 / 1을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 31 | <code>    (9, &#x27;치즈케이크&#x27;, &#x27;dessert&#x27;, 6500, 1),</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 9 / 치즈케이크 / dessert / 6500 / 1을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 32 | <code>    (10, &#x27;버터쿠키&#x27;, &#x27;dessert&#x27;, 2500, 0);</code> | 메뉴 번호, 이름, 분류, 현재 가격, 판매 가능 여부 순서로 10 / 버터쿠키 / dessert / 2500 / 0을 저장한다. 마지막 행의 세미콜론으로 INSERT를 끝낸다. |
| 35 | <code>INSERT INTO cafe_order (order_id, customer_id, ordered_at, status)</code> | cafe_order에 넣을 열의 순서를 명시한다. 뒤의 각 값은 이 순서와 일치해야 한다. |
| 36 | <code>VALUES</code> | 여러 행을 한 번의 INSERT로 입력할 값 목록을 시작한다. |
| 37 | <code>    (1, 1, &#x27;2026-10-01 09:00:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 1 / 1 / 2026-10-01 09:00:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 38 | <code>    (2, 2, &#x27;2026-10-01 10:00:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 2 / 2 / 2026-10-01 10:00:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 39 | <code>    (3, 3, &#x27;2026-10-02 11:00:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 3 / 3 / 2026-10-02 11:00:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 40 | <code>    (4, 1, &#x27;2026-10-03 09:30:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 4 / 1 / 2026-10-03 09:30:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 41 | <code>    (5, 4, &#x27;2026-10-04 13:00:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 5 / 4 / 2026-10-04 13:00:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 42 | <code>    (6, 5, &#x27;2026-10-05 14:00:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 6 / 5 / 2026-10-05 14:00:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 43 | <code>    (7, 6, &#x27;2026-10-06 15:00:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 7 / 6 / 2026-10-06 15:00:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 44 | <code>    (8, 7, &#x27;2026-10-07 16:00:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 8 / 7 / 2026-10-07 16:00:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 45 | <code>    (9, 8, &#x27;2026-10-08 12:00:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 9 / 8 / 2026-10-08 12:00:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 46 | <code>    (10, 2, &#x27;2026-10-09 10:30:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 10 / 2 / 2026-10-09 10:30:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 47 | <code>    (11, 3, &#x27;2026-10-10 11:30:00&#x27;, &#x27;paid&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 11 / 3 / 2026-10-10 11:30:00 / paid을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 48 | <code>    (12, 4, &#x27;2026-10-11 13:30:00&#x27;, &#x27;cancelled&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 12 / 4 / 2026-10-11 13:30:00 / cancelled을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 49 | <code>    (13, 5, &#x27;2026-10-12 14:30:00&#x27;, &#x27;pending&#x27;),</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 13 / 5 / 2026-10-12 14:30:00 / pending을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 50 | <code>    (14, 6, &#x27;2026-10-13 15:30:00&#x27;, &#x27;cancelled&#x27;);</code> | 주문 번호, 고객 번호, 주문 시각, 상태 순서로 14 / 6 / 2026-10-13 15:30:00 / cancelled을 저장한다. 마지막 행의 세미콜론으로 INSERT를 끝낸다. |
| 53 | <code>INSERT INTO order_item (order_item_id, order_id, menu_id, quantity, unit_price_won)</code> | order_item에 넣을 열의 순서를 명시한다. 뒤의 각 값은 이 순서와 일치해야 한다. |
| 54 | <code>VALUES</code> | 여러 행을 한 번의 INSERT로 입력할 값 목록을 시작한다. |
| 55 | <code>    (1, 1, 1, 2, 4000),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 1 / 1 / 1 / 2 / 4000을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 56 | <code>    (2, 1, 8, 1, 6500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 2 / 1 / 8 / 1 / 6500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 57 | <code>    (3, 2, 2, 1, 4500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 3 / 2 / 2 / 1 / 4500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 58 | <code>    (4, 2, 10, 2, 2500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 4 / 2 / 10 / 2 / 2500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 59 | <code>    (5, 3, 3, 2, 5000),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 5 / 3 / 3 / 2 / 5000을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 60 | <code>    (6, 3, 9, 1, 6500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 6 / 3 / 9 / 1 / 6500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 61 | <code>    (7, 4, 5, 1, 5000),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 7 / 4 / 5 / 1 / 5000을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 62 | <code>    (8, 4, 10, 1, 2500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 8 / 4 / 10 / 1 / 2500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 63 | <code>    (9, 5, 6, 1, 4500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 9 / 5 / 6 / 1 / 4500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 64 | <code>    (10, 5, 8, 1, 6500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 10 / 5 / 8 / 1 / 6500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 65 | <code>    (11, 6, 7, 2, 5000),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 11 / 6 / 7 / 2 / 5000을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 66 | <code>    (12, 6, 9, 1, 6500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 12 / 6 / 9 / 1 / 6500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 67 | <code>    (13, 7, 4, 1, 4500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 13 / 7 / 4 / 1 / 4500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 68 | <code>    (14, 7, 10, 2, 2500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 14 / 7 / 10 / 2 / 2500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 69 | <code>    (15, 8, 1, 1, 4000),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 15 / 8 / 1 / 1 / 4000을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 70 | <code>    (16, 8, 8, 1, 6500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 16 / 8 / 8 / 1 / 6500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 71 | <code>    (17, 9, 2, 2, 4500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 17 / 9 / 2 / 2 / 4500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 72 | <code>    (18, 9, 9, 1, 6500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 18 / 9 / 9 / 1 / 6500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 73 | <code>    (19, 10, 5, 2, 5000),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 19 / 10 / 5 / 2 / 5000을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 74 | <code>    (20, 10, 10, 1, 2500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 20 / 10 / 10 / 1 / 2500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 75 | <code>    (21, 11, 3, 1, 5000),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 21 / 11 / 3 / 1 / 5000을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 76 | <code>    (22, 12, 6, 1, 4500),</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 22 / 12 / 6 / 1 / 4500을 저장한다. 쉼표 뒤에 다음 행이 이어진다. |
| 77 | <code>    (23, 13, 7, 1, 5000);</code> | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 순서로 23 / 13 / 7 / 1 / 5000을 저장한다. 마지막 행의 세미콜론으로 INSERT를 끝낸다. |
| 82 | <code>COMMIT;</code> | 모든 샘플 입력을 확정한다. 재입력하려면 기존 DB에 덧붙이지 말고 새 빈 DB를 만든다. |

## sql/03_queries.sql

| 원본 줄 번호 | 해당 코드 | 쉬운 설명 |
| --- | --- | --- |
| 3 | <code>PRAGMA foreign_keys = ON;</code> | 이 연결에서도 외래 키 검사를 활성화한다. BEGIN 전에 실행한다. |
| 4 | <code>BEGIN TRANSACTION;</code> | 15개 SQL을 실행한 뒤 변경과 인덱스를 한 번에 확정한다. |
| 7 | <code>SELECT menu_id, menu_name, price_won</code> | 결과에 메뉴 번호·이름·가격 열을 표시한다. |
| 8 | <code>FROM menu</code> | 메뉴 테이블에서 조회한다. |
| 9 | <code>WHERE is_available = 1 AND price_won &gt;= 5000</code> | 판매 중이면서 5,000원 이상인 행만 남긴다. 5,000원은 이 조회의 검색 기준이다. |
| 10 | <code>ORDER BY price_won ASC, menu_id ASC;</code> | 가격 오름차순으로 정렬하고 같은 가격이면 메뉴 번호로 순서를 고정한다. |
| 13 | <code>SELECT menu_id, menu_name, price_won</code> | 검색된 메뉴의 번호·이름·가격을 표시한다. |
| 14 | <code>FROM menu</code> | 메뉴를 검색 대상으로 삼는다. |
| 15 | <code>WHERE menu_name LIKE &#x27;%라떼%&#x27;</code> | LIKE의 %는 길이 제한 없는 문자열이다. 이름 어디에든 라떼가 들어가면 찾는다. |
| 16 | <code>ORDER BY menu_id ASC;</code> | 메뉴 번호가 작은 것부터 표시해 실행마다 결과 순서를 일정하게 한다. |
| 19 | <code>SELECT order_id, customer_id, ordered_at, status</code> | 최근 주문의 번호·고객 번호·시각·상태를 선택한다. |
| 20 | <code>FROM cafe_order</code> | 주문 테이블을 조회한다. |
| 21 | <code>WHERE ordered_at &gt;= &#x27;2026-10-01 00:00:00&#x27;</code> | 10월 시작 시각 이상인 주문을 포함한다. ISO 형식 문자열이므로 시간 순서와 문자열 순서가 맞는다. |
| 22 | <code>  AND ordered_at &lt; &#x27;2026-11-01 00:00:00&#x27;</code> | 다음 달 시작은 제외하는 반열린 범위로 10월 전체를 선택한다. |
| 23 | <code>ORDER BY ordered_at DESC, order_id DESC</code> | 시각 내림차순으로 최신을 먼저 두고 같은 시각은 주문 번호 내림차순으로 정렬한다. |
| 24 | <code>LIMIT 5;</code> | 정렬 결과 중 5건만 표시한다. 5는 이번 요구의 최근 주문 개수다. |
| 27 | <code>SELECT order_id, customer_id, status</code> | 주문 번호·고객 번호·상태를 결과에 담는다. |
| 28 | <code>FROM cafe_order</code> | 주문 테이블을 읽는다. |
| 29 | <code>WHERE status IN (&#x27;pending&#x27;, &#x27;cancelled&#x27;)</code> | 상태가 목록의 두 값 중 하나인 행만 남긴다. |
| 30 | <code>ORDER BY order_id ASC;</code> | 주문 번호가 작은 순서로 보여준다. |
| 33 | <code>SELECT o.order_id, c.customer_name, o.status</code> | o는 주문, c는 고객의 별칭이다. 주문 번호와 고객 이름·상태를 선택한다. |
| 34 | <code>FROM cafe_order AS o</code> | 주문을 기준 테이블로 잡고 o라고 줄여 부른다. |
| 35 | <code>INNER JOIN customer AS c ON c.customer_id = o.customer_id</code> | 주문에 적힌 고객 번호와 고객 기본 키가 같은 행을 연결한다. 양쪽에 짝이 있는 행만 나온다. |
| 36 | <code>ORDER BY o.order_id ASC;</code> | 주문 번호 순서대로 결과를 표시한다. |
| 39 | <code>SELECT i.order_item_id, m.menu_name, i.quantity,</code> | 상세 번호·메뉴 이름·수량을 선택하며 다음 줄에서 열 선택을 이어간다. |
| 40 | <code>       i.unit_price_won, i.quantity * i.unit_price_won AS subtotal_won</code> | 당시 단가와 수량 곱하기 당시 단가인 소계를 표시한다. AS는 계산 열에 이름을 붙인다. |
| 41 | <code>FROM order_item AS i</code> | 주문 상세를 i라는 별칭으로 읽는다. |
| 42 | <code>INNER JOIN menu AS m ON m.menu_id = i.menu_id</code> | 상세의 메뉴 번호와 메뉴 기본 키가 같은 행을 연결한다. |
| 43 | <code>ORDER BY i.order_item_id ASC;</code> | 상세 번호 순서로 보여준다. 이 조회는 취소·대기를 포함한 상세 내역이며 매출 합계가 아니다. |
| 46 | <code>SELECT c.customer_id, c.customer_name, o.order_id, o.status</code> | 고객 번호·이름과 연결된 주문 번호·상태를 보여준다. |
| 47 | <code>FROM customer AS c</code> | 모든 고객을 보존할 왼쪽 테이블로 삼는다. |
| 48 | <code>LEFT JOIN cafe_order AS o ON o.customer_id = c.customer_id</code> | 주문이 없어도 고객 행은 남기며 주문 열은 NULL로 채운다. 주문이 여럿이면 고객도 여러 줄 나온다. |
| 49 | <code>ORDER BY c.customer_id ASC, o.order_id ASC;</code> | 고객 번호 순서, 같은 고객 안에서는 주문 번호 순서로 정렬한다. |
| 52 | <code>SELECT c.customer_name, o.order_id, m.menu_name, i.quantity</code> | 고객 이름·주문 번호·메뉴 이름·수량을 한 표로 보여준다. |
| 53 | <code>FROM customer AS c</code> | 고객 테이블에서 연결을 시작한다. |
| 54 | <code>INNER JOIN cafe_order AS o ON o.customer_id = c.customer_id</code> | 고객과 주문을 고객 번호로 연결한다. |
| 55 | <code>INNER JOIN order_item AS i ON i.order_id = o.order_id</code> | 주문과 상세를 주문 번호로 연결한다. |
| 56 | <code>INNER JOIN menu AS m ON m.menu_id = i.menu_id</code> | 상세와 메뉴를 메뉴 번호로 연결해 이름을 얻는다. |
| 57 | <code>WHERE c.customer_id = 1 AND o.status = &#x27;paid&#x27;</code> | 1번 고객의 결제 완료 주문만 남긴다. 1은 이 검색에서 지정한 고객 번호다. |
| 58 | <code>ORDER BY o.order_id ASC, i.order_item_id ASC;</code> | 주문 번호와 상세 번호 순서로 내역을 정렬한다. |
| 61 | <code>SELECT status, COUNT(*) AS order_count</code> | 상태와 각 상태 그룹의 전체 행 개수를 표시한다. 주문 테이블의 한 행은 주문 한 건이다. |
| 62 | <code>FROM cafe_order</code> | 상세와 연결하지 않고 주문 자체를 세므로 상세 수 때문에 주문 건수가 늘어나지 않는다. |
| 63 | <code>GROUP BY status</code> | 같은 상태의 주문을 하나의 그룹으로 묶는다. |
| 64 | <code>ORDER BY status ASC;</code> | 상태 문자열 순서로 결과를 정렬한다. |
| 67 | <code>SELECT c.customer_id, c.customer_name,</code> | 고객 번호와 이름을 표시하고 다음 줄에서 집계 열을 이어 쓴다. |
| 68 | <code>       SUM(i.quantity * i.unit_price_won) AS total_paid_won</code> | 각 상세의 수량과 당시 단가를 곱한 소계를 같은 고객별로 모두 더한다. |
| 69 | <code>FROM customer AS c</code> | 고객 테이블을 c로 부른다. |
| 70 | <code>INNER JOIN cafe_order AS o ON o.customer_id = c.customer_id</code> | 고객의 주문을 연결한다. |
| 71 | <code>INNER JOIN order_item AS i ON i.order_id = o.order_id</code> | 각 주문의 상세를 연결해 금액 계산에 쓴다. |
| 72 | <code>WHERE o.status = &#x27;paid&#x27;</code> | 취소와 결제 대기는 매출에 넣지 않는다. |
| 73 | <code>GROUP BY c.customer_id, c.customer_name</code> | 고객 번호와 이름을 기준으로 상세들을 묶어 고객별 합계를 만든다. |
| 74 | <code>ORDER BY total_paid_won DESC, c.customer_id ASC;</code> | 구매액이 많은 고객부터 정렬하고 동액이면 고객 번호로 정렬한다. |
| 77 | <code>SELECT category, ROUND(AVG(price_won), 2) AS average_price_won</code> | 분류별 산술 평균 가격을 구하고 소수 둘째 자리로 반올림한다. 판매량 가중 평균은 아니다. |
| 78 | <code>FROM menu</code> | 현재 메뉴 가격을 평균의 입력 데이터로 사용한다. |
| 79 | <code>WHERE is_available = 1</code> | 현재 판매 중인 메뉴만 평균 계산에 포함한다. |
| 80 | <code>GROUP BY category</code> | 메뉴들을 coffee·tea·dessert 분류별로 묶는다. |
| 81 | <code>ORDER BY category ASC;</code> | 분류 이름 순서로 결과를 표시한다. |
| 84 | <code>SELECT c.customer_id, c.customer_name</code> | 주문 기록이 없는 고객의 번호와 이름을 선택한다. |
| 85 | <code>FROM customer AS c</code> | 고객마다 내부 조회의 존재 여부를 확인한다. |
| 86 | <code>WHERE NOT EXISTS (</code> | 괄호 안 조회가 한 행도 찾지 못한 고객만 바깥 결과에 남긴다. |
| 87 | <code>    SELECT 1</code> | 행이 존재하는지만 필요하므로 구체적인 주문 열 대신 상수 1을 선택한다. |
| 88 | <code>    FROM cafe_order AS o</code> | 내부 조회의 대상은 주문 테이블이다. |
| 89 | <code>    WHERE o.customer_id = c.customer_id</code> | 현재 바깥 고객의 번호와 같은 고객 번호를 가진 주문이 있는지 검사하는 상관 서브쿼리다. |
| 91 | <code>ORDER BY c.customer_id ASC;</code> | 주문 없는 고객을 번호 순서대로 표시한다. |
| 94 | <code>UPDATE cafe_order</code> | 기존 주문 행을 수정한다. 새로운 주문을 추가하지 않는다. |
| 95 | <code>SET status = &#x27;paid&#x27;</code> | 조건을 통과한 주문의 상태를 결제 완료로 바꾼다. |
| 96 | <code>WHERE order_id = 13 AND status = &#x27;pending&#x27;;</code> | 13번 주문이면서 아직 결제 대기인 경우만 수정한다. 재실행하면 이미 paid라서 변경 행은 0이다. |
| 99 | <code>DELETE FROM cafe_order</code> | 조건에 맞는 주문 행을 실제로 지운다. 삭제를 확정하면 복구에는 초기 DB 재생성이 필요하다. |
| 100 | <code>WHERE order_id = 14 AND status = &#x27;cancelled&#x27;;</code> | 미리 정한 14번 취소 주문만 삭제한다. 이 샘플에는 상세가 없어 FK를 위반하지 않는다. 상세가 있으면 RESTRICT가 막는다. |
| 103 | <code>CREATE INDEX IF NOT EXISTS idx_cafe_order_recent</code> | 같은 이름이 없을 때 주문 검색용 인덱스를 만든다. 이 명령은 조회 결과 행을 반환하지 않는다. |
| 104 | <code>ON cafe_order (ordered_at DESC, order_id DESC);</code> | 주문 시각·주문 번호 내림차순으로 찾을 수 있게 한다. Q03의 월 범위와 정렬 순서에 맞춘다. 실제 사용 여부는 실행 계획으로 확인한다. |
| 106 | <code>COMMIT;</code> | Q13 수정·Q14 삭제·Q15 인덱스 생성을 확정한다. 도중 오류 시 COMMIT하지 말고 ROLLBACK한다. |

## 4. 실행·검증 명령 해설

아래 번호는 소스 줄 번호가 아니라 README의 **명령 블록 내부 해설 번호**다. 명령은 운영체제 터미널 → SQLite CLI 또는 Python 콘솔의 해당 위치에서 실행한다.

| 번호 | 명령·문법 | 뜻과 상태 변화 |
| --- | --- | --- |
| C01 | `sqlite3 cafe_practice.db` | 터미널에서 SQLite CLI를 실행하고 지정한 로컬 DB를 연다. 파일이 없으면 만든다. |
| C02 | `.bail on` | CLI가 SQL 오류를 만났을 때 스크립트 처리를 중단하게 한다. 이미 확정된 작업을 자동 복구하는 명령은 아니다. |
| C03 | `.headers on` | 출력에 열 이름을 표시한다. DB 데이터는 바꾸지 않는다. |
| C04 | `.mode list` | 결과를 구분자가 있는 텍스트 행으로 표시한다. |
| C05 | `.read sql/01_schema.sql` | 현재 작업 폴더를 기준으로 파일을 읽어 SQL을 실행한다. |
| C06 | `.read sql/02_seed.sql` | 부모부터 입력하도록 작성한 샘플 SQL을 실행한다. |
| C07 | `PRAGMA foreign_keys;` | 이 연결의 FK 설정을 조회한다. 결과 1이 활성화다. |
| C08 | `SELECT COUNT(*) FROM cafe_order;` | 주문 한 행을 한 건으로 세어 초기 14건을 반환한다. |
| C09 | `.echo on` | 파일에서 읽는 SQL 명령도 결과와 함께 표시한다. |
| C10 | `.output results/my_run.txt` | 이후 CLI 출력을 파일에 기록한다. 파일이 있으면 덮어쓰므로 별도 이름을 사용한다. |
| C11 | `.read sql/03_queries.sql` | 쿼리 전체를 순서대로 실행한다. Q13 이후 실제 데이터가 바뀐다. |
| C12 | `.output stdout` | 출력을 다시 터미널로 돌린다. |
| C13 | `.echo off` | 실행 SQL 자체의 출력 설정을 끈다. |
| C14 | `.quit` | CLI를 종료한다. 미확정 작업이 없도록 COMMIT 또는 ROLLBACK 후 종료한다. |
| C15 | `SELECT changes() AS changed_rows;` | 같은 연결의 마지막 UPDATE·DELETE 등 변경 SQL이 바꾼 행 수를 확인한다. 검증하려는 명령 직후 실행한다. |
| C16 | `SELECT order_id, status FROM cafe_order WHERE order_id IN (13, 14);` | 상태 변경·삭제 대상 두 ID만 확인한다. 전체 실행 후에는 13번 paid만 보인다. |
| C17 | `ROLLBACK;` | 열려 있는 트랜잭션의 미확정 변경을 취소한다. 이미 COMMIT된 변경에는 효과가 없다. |
| C18 | `PRAGMA foreign_key_check;` | 저장 데이터에서 FK 위반을 찾는다. 정상 결과는 0행이다. 오류 입력이 실제 차단되는지 시험하는 것과도 구분한다. |
| C19 | `PRAGMA integrity_check;` | DB 구조의 무결성을 검사한다. 정상은 ok다. FK 검사와는 별개다. |
| C20 | `SELECT 'customer' AS table_name, COUNT(*) AS row_count FROM customer` | customer라는 고정 이름과 행 수를 결과로 만든다. 아래 UNION ALL과 합쳐 네 테이블을 확인한다. |
| C21 | `UNION ALL SELECT 'menu', COUNT(*) FROM menu` | menu 행 수 결과를 이전 결과 아래에 추가한다. 중복 제거를 하지 않는다. |
| C22 | `UNION ALL SELECT 'cafe_order', COUNT(*) FROM cafe_order` | 주문 행 수 결과를 추가한다. 초기 14, 삭제 후 13이다. |
| C23 | `UNION ALL SELECT 'order_item', COUNT(*) FROM order_item;` | 상세 행 수를 추가하고 SQL을 끝낸다. 샘플은 23행이다. |
| C24 | `EXPLAIN QUERY PLAN SELECT ...` | SELECT를 어떻게 읽을 계획인지 반환한다. SELECT 대신 결과 데이터를 반환하는 명령은 아니다. Q15.png에서 인덱스 생성 전후 실행 계획을 확인할 수 있다. |
| C25 | `SELECT name, sql FROM sqlite_master WHERE type='index' AND name='idx_cafe_order_recent';` | SQLite의 구조 메타데이터에서 지정 인덱스의 이름과 생성 SQL을 확인한다. |

### README의 Python 보조 실행 블록

이 부분은 SQL을 실행하기 위한 보조 예제이며 Python 앱 구현 과제가 아닙니다. `sqlite3`는 Python 표준 SQLite 모듈, `Path`는 UTF-8 파일을 읽기 위한 표준 경로 도구입니다. import 줄은 역할을 이 문단에서 설명하고 아래 표에서 제외합니다.

아래 번호는 **README Python 블록의 원래 줄 번호**입니다. 실행 파일 줄 번호나 SQL 파일 줄 번호와 다릅니다. 파일 읽기와 DB 실행을 나눠 PEP 8의 79자 줄 길이에 맞췄습니다.

| 블록 줄 번호 | 해당 코드 | 쉬운 설명 |
| --- | --- | --- |
| 4 | `connection = sqlite3.connect('cafe_python_practice.db')` | 이름을 지정한 로컬 DB에 연결합니다. 파일이 없으면 생성되므로 새 파일명을 사용합니다. |
| 5 | `schema_sql = Path('sql/01_schema.sql').read_text(encoding='utf-8')` | 스키마 SQL을 UTF-8로 읽어 저장합니다. 아직 DB에 실행한 것은 아닙니다. |
| 6 | `seed_sql = Path('sql/02_seed.sql').read_text(encoding='utf-8')` | 샘플 입력 SQL을 읽습니다. 읽는 단계와 DB를 변경하는 단계를 구분합니다. |
| 7 | `query_sql = Path('sql/03_queries.sql').read_text(encoding='utf-8')` | 핵심 쿼리 파일 전체를 문자열로 읽습니다. |
| 9 | `connection.executescript(schema_sql)` | 스키마 SQL을 실행해 테이블과 제약조건을 생성합니다. |
| 10 | `connection.executescript(seed_sql)` | 샘플 SQL을 실행해 부모에서 자식 순서로 데이터를 저장합니다. |
| 11 | `connection.execute('PRAGMA foreign_keys').fetchall()` | 같은 연결의 FK 설정을 확인합니다. 대화형 콘솔에서 [(1,)]이 표시되어야 합니다. |
| 12 | `connection.execute('SELECT COUNT(*) FROM cafe_order').fetchall()` | 초기 주문 건수를 읽습니다. [(14,)]이며 아직 수정·삭제 전입니다. |
| 13 | `connection.executescript(query_sql)` | 15개 SQL을 순서대로 실행합니다. Q13·Q14의 데이터 변경과 Q15 인덱스를 확정하지만 SELECT 표를 자동 출력하지는 않습니다. |
| 14 | `connection.execute(` | 긴 조회 호출을 괄호 안에서 여러 줄로 나눕니다. 다음 줄의 SQL을 실행할 준비를 합니다. |
| 15 | `    "SELECT order_id, status FROM cafe_order WHERE order_id = 13"` | 13번 주문의 번호와 상태를 읽을 SQL 문자열입니다. 바로 위 execute에 전달합니다. |
| 16 | `).fetchall()` | execute 호출을 닫고 결과 행 전체를 가져옵니다. [(13, 'paid')]를 확인합니다. |
| 17 | `connection.close()` | DB 연결을 닫습니다. SQL 안에서 COMMIT한 내용은 파일에 남습니다. |

오류가 발생하면 이어지는 줄을 실행하지 않습니다. 같은 연결에서 `connection.rollback()`으로 열린 미확정 변경을 되돌리고 원인을 해결한 뒤 새 파일명으로 다시 시작합니다. SQL 파일 안에서 이미 COMMIT된 작업은 이 메서드로 되돌릴 수 없습니다.
