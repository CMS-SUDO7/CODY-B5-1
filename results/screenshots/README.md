# SQL 실행 화면

2026-10-29에 SQLite CLI 3.43.2로 새 임시 DB를 만들고 `01_schema.sql` → `02_seed.sql` → Q01~Q15를 실행했다. 핵심 쿼리는 한 연결의 BEGIN/COMMIT 안에서 순서대로 실행했다.

각 PNG는 실제 CLI 출력 로그를 [결과 보기 화면](execution_results.html)에 표시하고 Chrome에서 캡처한 이미지다. SQL과 결과를 함께 담았으며, 원본 로그도 아래에 연결했다. Q01~Q12는 수정·삭제 전 상태이고, Q13·Q14는 변경 전후와 변경 행 수, Q15는 인덱스 생성 전후 실행 계획을 보여준다.

| 쿼리 | 실행 내용 | 실행 결과 화면 | 원본 CLI 출력 |
| --- | --- | --- | --- |
| Q01 | 판매 가능한 5,000원 이상 메뉴 | [Q01.png](Q01.png) | [Q01.txt](../terminal/Q01.txt) |
| Q02 | 라테 이름 검색 | [Q02.png](Q02.png) | [Q02.txt](../terminal/Q02.txt) |
| Q03 | 10월 최근 주문 5건 | [Q03.png](Q03.png) | [Q03.txt](../terminal/Q03.txt) |
| Q04 | 결제 대기·취소 주문 | [Q04.png](Q04.png) | [Q04.txt](../terminal/Q04.txt) |
| Q05 | 주문과 고객 INNER JOIN | [Q05.png](Q05.png) | [Q05.txt](../terminal/Q05.txt) |
| Q06 | 상세와 메뉴·소계 | [Q06.png](Q06.png) | [Q06.txt](../terminal/Q06.txt) |
| Q07 | 주문 없는 고객까지 LEFT JOIN | [Q07.png](Q07.png) | [Q07.txt](../terminal/Q07.txt) |
| Q08 | 고객·주문·상세·메뉴 연결 | [Q08.png](Q08.png) | [Q08.txt](../terminal/Q08.txt) |
| Q09 | 상태별 주문 수 | [Q09.png](Q09.png) | [Q09.txt](../terminal/Q09.txt) |
| Q10 | 고객별 결제 금액 합계 | [Q10.png](Q10.png) | [Q10.txt](../terminal/Q10.txt) |
| Q11 | 메뉴 분류별 평균 가격 | [Q11.png](Q11.png) | [Q11.txt](../terminal/Q11.txt) |
| Q12 | 주문 없는 고객 | [Q12.png](Q12.png) | [Q12.txt](../terminal/Q12.txt) |
| Q13 | 13번 주문 상태 변경 | [Q13.png](Q13.png) | [Q13.txt](../terminal/Q13.txt) |
| Q14 | 14번 취소 주문 삭제 | [Q14.png](Q14.png) | [Q14.txt](../terminal/Q14.txt) |
| Q15 | 인덱스 생성과 실행 계획 | [Q15.png](Q15.png) | [Q15.txt](../terminal/Q15.txt) |

## 조회 예시: Q01

![Q01의 SQL과 메뉴 5행](Q01.png)

## 복잡한 JOIN: Q08

![Q08의 SQL과 고객 1번의 메뉴 상세 4행](Q08.png)

[단계별 실행 결과](../Q08_steps.txt)에서 각 JOIN의 연결 기준과 중간 결과를 확인할 수 있다.

## 변경 예시: Q13·Q14

![Q13 실행 전 pending, 변경 1행, 실행 후 paid](Q13.png)

![Q14 실행 전후 주문 수 14에서 13, 상세 수 23 유지](Q14.png)

## 인덱스 예시: Q15

![Q15 생성 전 SCAN과 정렬, 생성 후 인덱스 SEARCH](Q15.png)
