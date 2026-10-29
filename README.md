# 카페 주문 데이터베이스

SQLite로 고객·메뉴·주문·주문 상세를 관리하는 SQL 실습 프로젝트다. 테이블 생성, 샘플 데이터 입력, 조회·조인·집계·수정·삭제를 다룬다.

## 1. 파일과 읽는 순서

`01_schema.sql` → `02_seed.sql` → `03_queries.sql` → 실행 결과 순서로 확인한다.

| 파일 | 역할 |
| --- | --- |
| [01_schema.sql](sql/01_schema.sql) | 테이블 4개와 PK·FK 생성 |
| [02_seed.sql](sql/02_seed.sql) | 고객 10명·메뉴 10개·주문 14건·상세 23행 입력 |
| [03_queries.sql](sql/03_queries.sql) | 핵심 쿼리 15개 |
| [cafe.db](data/cafe.db) | 테이블과 샘플 데이터가 준비된 DB |
| `results/Q01.txt` ~ `Q15.txt` | 쿼리별 SQL과 실행 결과 |
| [실행 화면 모음](results/screenshots/README.md) | 쿼리별 캡처 15장 |

## 2. 데이터 구조

| 테이블 | 저장 내용 | 관계 |
| --- | --- | --- |
| `customer` | 고객 이름·이메일 | 고객 1명 → 주문 여러 건 |
| `menu` | 메뉴 이름·분류·현재 가격 | 메뉴 1개 → 주문 상세 여러 줄 |
| `cafe_order` | 주문 고객·시각·상태 | 주문 1건 → 주문 상세 여러 줄 |
| `order_item` | 주문 메뉴·수량·주문 당시 단가 | 주문과 메뉴 연결 |

매출은 결제 완료(`paid`) 주문의 `quantity × unit_price_won`으로 계산한다. `price_won`은 현재 메뉴 가격, `unit_price_won`은 주문 당시 가격이다.

## 3. 실행 환경

- SQLite 3.x / `sqlite3` CLI
- WSL(Ubuntu) 또는 macOS 터미널

## 4. 실행방법

프로젝트 폴더에서 실행한다. 아래 명령은 WSL과 macOS에서 공통으로 사용한다.

### 메뉴 조회

```bash
sqlite3 -header -column data/cafe.db 'SELECT * FROM menu;'
```

### 전체 쿼리 실행

원본을 복사한 연습용 DB에서 실행한다. 다시 실행하면 복사 단계에서 연습용 DB가 초기화된다.

```bash
cp data/cafe.db data/cafe_work.db
sqlite3 -bail -header -column -echo data/cafe_work.db '.read sql/03_queries.sql'
```

Q13은 13번 주문을 결제 완료로 바꾸고, Q14는 14번 취소 주문을 삭제한다. Q15는 주문 검색용 인덱스를 만든다.

### 새 DB 생성

`cafe_new.db`는 아직 없는 파일명으로 지정한다.

```bash
sqlite3 -bail cafe_new.db '.read sql/01_schema.sql' '.read sql/02_seed.sql'
sqlite3 -header -column cafe_new.db 'SELECT COUNT(*) AS order_count FROM cafe_order;'
```

초기 주문 수는 14건이다.

## 5. 핵심 쿼리 15개

| 번호 | 내용 | 결과 |
| --- | --- | --- |
| Q01 | 판매 가능한 5,000원 이상 메뉴 | [Q01](results/Q01.txt) |
| Q02 | 이름에 라테가 포함된 메뉴 | [Q02](results/Q02.txt) |
| Q03 | 10월 최근 주문 5건 | [Q03](results/Q03.txt) |
| Q04 | 결제 대기·취소 주문 | [Q04](results/Q04.txt) |
| Q05 | 주문과 고객 연결 · INNER JOIN | [Q05](results/Q05.txt) |
| Q06 | 주문 상세와 메뉴 연결 · INNER JOIN | [Q06](results/Q06.txt) |
| Q07 | 주문 없는 고객도 포함 · LEFT JOIN | [Q07](results/Q07.txt) |
| Q08 | 고객·주문·상세·메뉴 연결 | [Q08](results/Q08.txt) |
| Q09 | 상태별 주문 수 · COUNT | [Q09](results/Q09.txt) |
| Q10 | 고객별 결제 금액 · SUM | [Q10](results/Q10.txt) |
| Q11 | 분류별 판매 메뉴 평균 가격 · AVG | [Q11](results/Q11.txt) |
| Q12 | 주문 없는 고객 · NOT EXISTS | [Q12](results/Q12.txt) |
| Q13 | 13번 주문 상태 수정 · UPDATE | [Q13](results/Q13.txt) |
| Q14 | 14번 취소 주문 삭제 · DELETE | [Q14](results/Q14.txt) |
| Q15 | 최근 주문 검색용 인덱스 생성 | [Q15](results/Q15.txt) |

## 6. 실행 결과

Q01~Q12의 결과는 수정·삭제 전 기준이다.

| 항목 | 결과 |
| --- | --- |
| 주문 상태 | 결제 완료 11건·취소 2건·대기 1건 |
| 최고 구매액 | 김민수·이서연 각 22,000원 |
| 주문 없는 고객 | 임지아·한시우 |
| Q13 실행 후 | 13번 주문 `pending` → `paid` |
| Q14 실행 후 | 주문 14 → 13건, 상세 23행 유지 |
| Q15 실행 후 | `idx_cafe_order_recent` 인덱스로 검색 |

[전체 실행 화면](results/screenshots/README.md) · [제약조건 검증 기록](results/validation.txt)

## 7. 오류 해결

| 오류 | 해결 |
| --- | --- |
| `no such table` | DB 경로를 확인하거나 새 DB에 01 → 02 순서로 실행한다. |
| `table ... already exists` / `UNIQUE constraint failed` | 초기화 파일을 중복 실행했는지 확인하고 새 DB에서 시작한다. |
| `FOREIGN KEY constraint failed` | 참조할 고객·주문·메뉴가 있는지 확인한다. |
| `cannot start a transaction within a transaction` | 진행 중인 작업을 COMMIT 또는 ROLLBACK한 뒤 실행한다. |

## 8. 추가 설명

| 내용 | 자료 |
| --- | --- |
| 엑셀과 DB의 관계 저장·무결성 비교 | [비교표](docs/basic_knowledge.md#엑셀과-db를-비교할-때-볼-점) |
| Q08의 단계별 SQL과 중간 결과 | [실행 결과](results/Q08_steps.txt) |
| 문제·원인·해결 과정 | [재현 결과](results/troubleshooting.txt) |
