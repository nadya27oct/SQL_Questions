1174 - Intermediate Food Delivery II

/* Write an SQL query to find the percentage of immediate orders in the first orders of all customers, rounded to 2 decimal places.
If the preferred delivery date of the customer is the same as the order date then the order is called immediate otherwise it's called scheduled.

The first order of a customer is the order with the earliest order date that customer made. It is guaranteed that a customer has exactly one first order.

Denominator - total customers
Numerator - customers where min order date is delivery date & group by customer ID
*/

select
    round(
      ((select count(distinct customer_id)
        from Delivery
        where MIN(order_date) = MIN(customer_pref_delivery_date)
        group by customer_id)
        /
        (select count(distinct customer_id) from Delivery)
      )*100,2) as immediate_percentage;

1322 - Ads Perfomance Problem

/*
CTR = Ad Total Clicks / [Ad Total Clicks + Ad Total Views]
Write a query to find Click Through Rate of each Ad.
Round ctr to 2 decimal points. Order the result table by ctr in descending order and by ad_id in ascending order in case of a tie.

Ads table:
+-------+---------+---------+
| ad_id | user_id | action  |
+-------+---------+---------+
| 1     | 1       | Clicked |
| 2     | 2       | Clicked |
| 3     | 3       | Viewed  |
| 1     | 7       | Ignored |
| 2     | 7       | Viewed  |
| 3     | 5       | Clicked |
| 1     | 4       | Viewed  |
| 2     | 11      | Viewed  |
| 1     | 2       | Clicked |
+-------+---------+---------+
Approach -
Group by ad_id : total ads clicked, total ads viewed  - self join

*/
with distinct_ads as
  (select distinct ad_id from Ads),
clicks_and_views as
  (select a1.ad_id,count(distinct a1.user_id) as total_clicks, count(distinct a2.user_id) as total_views
    from Ads a1, Ads a2
    where t1.ad_id = a1.ad_id
    and a1.action = 'Clicked'
    and a2.action = 'Viewed'
  group by t1.id)
select t1.ad_id,ifnull(round((t2.total_clicks/(t2.total_clicks + t2.total_views)) * 100,2),0) as ctr
from distinct_ads t1
left join clicks_and_views t2
on t1.ad_id = t2.ad_id
order by 2 desc,1;

1211 - Queries quality and percentage problem.

/*
+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| query_name  | varchar |
| result      | varchar |
| position    | int     |
| rating      | int     |
+-------------+---------+
There is no primary key for this table, it may have duplicate rows.
This table contains information collected from some queries on a database.
The position column has a value from 1 to 500.
The rating column has a value from 1 to 5. Query with rating less than 3 is a poor query.

Query quality =  Average ratio between query rating and its position.
Poor query percentage = Percentage of all queries with rating less than 3

Write an SQL query to find each query_name, the quality and poor_query_percentage.
*/

select query_name,
round(avg(rating/position),2) as quality,
round((sum(case when rating < 3 then 1 else 0) / count(distinct result)) * 100, 2) as
from Queries
group by query_name

1321 - Restuarant Growth Problem
Write an SQL query to compute moving average of how much customer paid in a 7 days window (current day + 6 days before) .

/*
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| customer_id   | int     |
| name          | varchar |
| visited_on    | date    |
| amount        | int     |
+---------------+---------+
(customer_id, visited_on) is the primary key for this table.
This table contains data about customer transactions in a restaurant.
visited_on is the date on which the customer with ID (customer_id) have visited the restaurant.
amount is the total paid by a customer.
*/
with revenue_by_vists as
  (select visited_on,sum(amount) as amount
  from Customer),
rolling_avg as
  (select visited_on,
  sum(amount) over (order by visited_on rows between 6 preceding and current row) as amount,
  avg(amount) over (order by visited_on rows between 6 preceding and current row) as average_amount
  from revenue_by_vists)
select visited_on, amount, average_amount
from rolling_avg
where visited_on = (select date_add(min(rolling_avg), interval 7 day) from Customer);

1398 - Customers who bought products A & B but NOT C
/*
Write an SQL query to report the customer_id and customer_name of customers who bought products “A”, “B” but did not buy the product “C” since we want to recommend them buy this product.

Return the result table ordered by customer_id.
Customers table:
+-------------+---------------+
| customer_id | customer_name |
+-------------+---------------+
| 1           | Daniel        |
| 2           | Diana         |
| 3           | Elizabeth     |
| 4           | Jhon          |
+-------------+---------------+

Orders table:
+------------+--------------+---------------+
| order_id   | customer_id  | product_name  |
+------------+--------------+---------------+
| 10         |     1        |     A         |
| 20         |     1        |     B         |
| 30         |     1        |     D         |
| 40         |     1        |     C         |
| 50         |     2        |     A         |
| 60         |     3        |     A         |
| 70         |     3        |     B         |
| 80         |     3        |     D         |
| 90         |     4        |     C         |
+------------+--------------+---------------+
*/

with both_a_b_customers as
  (select o1.customer_id
    from Orders o1, Orders o2
    where o1.customer_id = o2.customer_id
    and o1.product_name = 'A'
    and o2.product_name = 'B'),
c_customers as
  (select o1.customer_id from Orders where product_name = 'C')
select
from both_a_b_customers t1
left join c_customers t2
on t1.customer_id = t2.customer_id
where t2.customer_id is null;

1205 - Monthly Transactions II Problem

/*
Write an SQL query to find for each month and country, the number of approved transactions and their total amount, the number of chargebacks and their total amount.

Transactions table:
+------+---------+----------+--------+------------+
| id   | country | state    | amount | trans_date |
+------+---------+----------+--------+------------+
| 101  | US      | approved | 1000   | 2019-05-18 |
| 102  | US      | declined | 2000   | 2019-05-19 |
| 103  | US      | approved | 3000   | 2019-06-10 |
| 104  | US      | approved | 4000   | 2019-06-13 |
| 105  | US      | approved | 5000   | 2019-06-15 |
+------+---------+----------+--------+------------+

Chargebacks table:
+------------+-------------+
| trans_id   | charge_date |
+------------+-------------+
| 102        | 2019-05-29  |
| 101        | 2019-06-30  |
| 105        | 2019-09-18  |
+------------+-------------+

Result table:
+----------+---------+----------------+-----------------+-------------------+--------------------+
| month    | country | approved_count | approved_amount | chargeback_count  | chargeback_amount  |
+----------+---------+----------------+-----------------+-------------------+--------------------+
| 2019-05  | US      | 1              | 1000            | 1                 | 2000               |
| 2019-06  | US      | 3              | 12000           | 1                 | 1000               |
| 2019-09  | US      | 0              | 0               | 1                 | 5000               |
+----------+---------+----------------+-----------------+-------------------+--------------------+

Approa ch -
approved count from transactions table
05 | 1 | 1000
06 | 3 | 12000

chargeback count
05 | 1 | 2000
06 | 1 | 1000
09 | 1 | 5000

chargeback left join approved on month
05 | 1 | 1000 | 1 | 2000
*/

with approved_txns as
  (select date_format(trans_date,'%Y-%m') as month, country, count(case when state = 'approved' then 1 else 0 end) as approved_count,
  sum(case when state = 'approved' then amount else 0 end) as approved_amount
  from Transactions
  group by 1),
chargeback_amts as
  (select date_format(c.charge_date,'%Y-%m') as month, t.country, count(c.trans_id) as chargeback_count, sum(t.amount) as chargeback_amount
  from Chargebacks c, Transactions t
  where c.trans_id = t.id
  group by 1)
select t2.month, t2.country, nullif(t1.approved_count,0) as approved_count, nullif(t1,approved_amount,0) as approved_amount,
  t2.chargeback_count, t2.chargeback_amount
from chargeback_amts t1
left join approved_txns t2
on t1.month = t2.month
order by t2.month;

1364 - Number of Trusted contacts of a customer
/*
Write an SQL query to find the following for each invoice_id:

customer_name: The name of the customer the invoice is related to.
price: The price of the invoice.
contacts_cnt: The number of contacts related to the customer.
trusted_contacts_cnt: The number of contacts related to the customer and at the same time they are customers to the shop. (i.e His/Her email exists in the Customers table.)
Order the result table by invoice_id.

Customers table:
+-------------+---------------+--------------------+
| customer_id | customer_name | email              |
+-------------+---------------+--------------------+
| 1           | Alice         | alice@leetcode.com |
| 2           | Bob           | bob@leetcode.com   |
| 13          | John          | john@leetcode.com  |
| 6           | Alex          | alex@leetcode.com  |
+-------------+---------------+--------------------+
Contacts table:
+-------------+--------------+--------------------+
| user_id     | contact_name | contact_email      |
+-------------+--------------+--------------------+
| 1           | Bob          | bob@leetcode.com   |
| 1           | John         | john@leetcode.com  |
| 1           | Jal          | jal@leetcode.com   |
| 2           | Omar         | omar@leetcode.com  |
| 2           | Meir         | meir@leetcode.com  |
| 6           | Alice        | alice@leetcode.com |
+-------------+--------------+--------------------+
Invoices table:
+------------+-------+---------+
| invoice_id | price | user_id |
+------------+-------+---------+
| 77         | 100   | 1       |
| 88         | 200   | 1       |
| 99         | 300   | 2       |
| 66         | 400   | 2       |
| 55         | 500   | 13      |
| 44         | 60    | 6       |
+------------+-------+---------+
Result table:
+------------+---------------+-------+--------------+----------------------+
| invoice_id | customer_name | price | contacts_cnt | trusted_contacts_cnt |
+------------+---------------+-------+--------------+----------------------+
| 44         | Alex          | 60    | 1            | 1                    |
| 55         | John          | 500   | 0            | 0                    |
| 66         | Bob           | 400   | 2            | 0                    |
| 77         | Alice         | 100   | 3            | 2                    |
| 88         | Alice         | 200   | 3            | 2                    |
| 99         | Bob           | 300   | 2            | 0                    |
+------------+---------------+-------+--------------+----------------------+

Approach - step 1 - count contacts by customer ID (join Customers & Contacts on customer ID/ User ID)

1 | alice | 3
2 | bob | 2
13 | john | 0
6 | alex | 1

select c.customer_id, c.customer_name,count(t.contact_name) as contacts_cnt
from Customers c
left join contacts t on c.customer_id = t.user_id
group by 1,2

step 2 - Trusted contacts by customer ID

1 | alice | 2
2 | bob | 0
13| John | 0
6 | alex | 1

select c.customer_id, c.customer_name,
sum(case when t.contact_name in (select customer_name from Customers) then 1 else 0 end) as cnt
from Customers c
left join contacts t on c.customer_id = t.user_id
group by 1,2
*/

select invoice_id, c.customer_name, price,
count(t.contact_name) as contact_cnt,
sum(case when t.contact_name in (select customer_name from Customers) then 1 else 0 end) as trusted_contacts_cnt
from Invoices i
join  Customers c
on i.user_id = c.customer_id
left join Contacts t
on c.customer_id = t.user_id
group by 1,2
order by invoice_id;

1907 - Count Salary Categories

Write an SQL query to report the number of bank accounts of each salary category. The salary categories are:

"Low Salary": All the salaries strictly less than $20000.
"Average Salary": All the salaries in the inclusive range [$20000, $50000].
"High Salary": All the salaries strictly greater than $50000.
/*
Accounts table:
+------------+--------+
| account_id | income |
+------------+--------+
| 3          | 108939 |
| 2          | 12747  |
| 8          | 87709  |
| 6          | 91796  |
+------------+--------+

Result table:
+----------------+----------------+
| category       | accounts_count |
+----------------+----------------+
| Low Salary     | 1              |
| Average Salary | 0              |
| High Salary    | 3              |
+----------------+----------------+
*/
with account_category as
  (select account_id,
  	case when income < 20000 then 'low'
      when income >= 20000 and income <=50000 then 'average'
      else 'high'
      end as category
  from accounts),
types as
  (select 'low' as category union
    select 'high' as category union
    select 'average' as category)
select t1.category, count(account_id) as accounts_cnt
from types t1
left join account_category t2 on t1.category = t2.category
group by 1
order by case t1.category
   when 'low' then 1
   when 'average' then 2
   when 'high' then 3
end;

1393 - Capital Gains Loss

+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| stock_name    | varchar |
| operation     | enum    |
| operation_day | int     |
| price         | int     |
+---------------+---------+
(stock_name, day) is the primary key for this table.
The operation column is an ENUM of type ('Sell', 'Buy')
Each row of this table indicates that the stock which has stock_name had an operation on the day operation_day with the price.
It is guaranteed that each 'Sell' operation for a stock has a corresponding 'Buy' operation in a previous day.

Write an SQL query to report the Capital gain/loss for each stock.

The capital gain/loss of a stock is total gain or loss after buying and selling the stock one or many times.

---------------+-----------+---------------+--------+
| stock_name    | operation | operation_day | price  |
+---------------+-----------+---------------+--------+
| Leetcode      | Buy       | 1             | 1000   |
| Corona Masks  | Buy       | 2             | 10     |
| Leetcode      | Sell      | 5             | 9000   |
| Handbags      | Buy       | 17            | 30000  |
+---------------+-----------+---------------+--------+

with capital_gains as
  (select s1.stock_name,s1.operation as purchased, s2.operation as sold, s1.price as purchase_price, s2.price as sale_price,
    (s2.price - s1.price) as gain_or_loss
    from Stocks s1, Stocks s2
    where s1.stock_name = s2.stock_name
    and s1.operation = 'Buy'
    and s2.operation = 'Sell'
    and s1.operation_day < s2.operation_day
  group by s1.stock_name,s1.operation,s1.operation_day)
select stock_name,sum(gain_or_loss) as capital_gain_loss
from capital_gains
group by stock_name;

with stock_performance as
  (select stock_name,operation, sum(price) as total_value from Stocks where operation = 'Buy' group by 1
  union
  select stock_name,operation, sum(price) as total_value from Stocks where operation = 'Sell' group by 1)
select t1.stock_name,t2.total_value - t1.total_value as capital_gain_loss
from stock_performance t1, stock_performance t2
where t1.stock_name = t2.stock_name
and t1.operation = 'Buy'
and t2.operation = 'Sell';

1468 - Calculate salaries

/*
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| company_id    | int     |
| employee_id   | int     |
| employee_name | varchar |
| salary        | int     |
+---------------+---------+
(company_id, employee_id) is the primary key for this table.
This table contains the company id, the id, the name and the salary for an employee.

Write an SQL query to find the salaries of the employees after applying taxes.

The tax rate is calculated for each company based on the following criteria:

0% If the max salary of any employee in the company is less than 1000$.
24% If the max salary of any employee in the company is in the range [1000, 10000] inclusive.
49% If the max salary of any employee in the company is greater than 10000$.
Return the result table in any order. Round the salary to the nearest integer.
*/

company_id | employee_id | employee_name | salary | max    | tax rate |
+------------+-------------+---------------+--------+------+---------+
| 1          | 1           | Tony          | 2000   | 21300 | 49%
| 1          | 2           | Pronub        | 21300  | 21300
| 1          | 3           | Tyrrox        | 10800  | 21300

with company_max_sal as
  (select  company_id,employee_id, employee_name, salary,
  max(salary) over (partition by company_id) as max_salary
  from Salaries),
company_tax_rate as
  (select company_id,employee_id, employee_name, salary, max_salary,
  case when max_salary < 1000 then 0.0
       when max_salary >= 1000 and max_salary <= 10000 then 0.24
       else 0.49
  end as tax_rate
  from company_max_sal)
select company_id, employee_id, employee_name, round(salary * (1-tax_rate),0) as salary
from company_tax_rate;

1212 - Team Scores in Football Tournament

host_team    | guest_team    | host_goals  | guest_goals  | points_guest | points_host
+------------+--------------+---------------+-------------
10           | 20            | 3           | 0            | 3 | 0
30           | 10            | 2           | 2            | 1 | 1
10           | 50            | 5           | 1            | 3 | 0
20           | 30            | 1           | 0            | 3 | 0
50           | 30            | 1           | 0            | 3 | 0
team
select host team, points_host from t where
select guest team, points guest from t
10 --> 3
10 --> 3
10 --> 1
20 --> 3
20 --> 0
3

with goals_tables as
  (select host_team,guest_team,host_goals,host_points,guest_points,
  case when host_goals > guest_goals then 3
      when host_goals = guest_goals then 1
      else 0 end as host_points,
  case when host_goals < guest_goals then 0
          when host_goals = guest_goals then 1
          else 3 end as guest_points,
  from Matches),
union_points as
  (select host_team as team_id, host_points as points from goals_tables
    union
    select guest_team as team_id, guest_points as points from goals_tables)
select t.team_id,t.team_name, sum(u.points) as num_points
from Teams t
left join union_points u
on t.team_id = u.team_id
group by t.team_id
order by num_points desc, team_id;


1097 - Game Play Analysis V Problem

/*
Table Name - Activity
+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| player_id    | int     |
| device_id    | int     |
| event_date   | date    |
| games_played | int     |
+--------------+---------+
(player_id, event_date) is the primary key of this table.
This table shows the activity of players of some game.
Each row is a record of a player who logged in and played a number of games (possibly 0) before logging out on some day using some device.

Install date of a player is the first login day of that player.

We also define day 1 retention of some date X to be the number of players whose install date is X and they logged back in on the day right after X,
divided by the number of players whose install date is X, rounded to 2 decimal places.

Write an SQL query that reports for each install date, the number of players that installed the game on that day and the day 1 retention.
*/
with min_date as
  (select player_id, min(event_date) as install_date
    from Activity
  group by player_id)
select i.install_date, count(i.player_id) as installs, round(count(a1.player_id)/count(i.player_id),2) as day_1_retention
from min_date i, Activity a1
where a1.event_date = date_add(i.install_date, interval 1 day)
and a2.player_id = a1.player_id
group by 1
order by 1;

1454 - Active Users

/*
Accounts
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| id            | int     |
| name          | varchar |
+---------------+---------+
the id is the primary key for this table.
This table contains the account id and the user name of each account.

Logins
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| id            | int     |
| login_date    | date    |
+---------------+---------+
There is no primary key for this table, it may contain duplicates.
This table contains the account id of the user who logged in and the login date. A user may log in multiple times in the day.

Write an SQL query to find the id and the name of active users.
Active users are those who logged in to their accounts for 5 or more consecutive days.
Return the result table ordered by the id.
*/
select a.id,a.name
from
  (select id,count(*) no_of_login_days
  from
    (select id, min(login_date) as first_login
    from Logins
    group by 1) t1, Logins t2
  where t1.id = t2.id
  and date_add(t1.first_login, interval 5 day) >= t2.login_date
  having count(*) >= 5) t, Accounts a
  where t.id = a.id
  order by a.id;

579 - Find Cumulative Salary of an Employee

/* The Employee table holds the salary information in a year.
Write a SQL to get the cumulative sum of an employee's salary over a period of 3 months but exclude the most recent month.
The result should be displayed by 'Id' ascending, and then by 'Month' descending.
*/

with most_recent_month as
  (select Id, max(Month) as most_recent from Employee group by Id),
cum_salary as
    (select e.Id, e.Month,
    sum(e.Salary) over (partition by e.Id order by e.Month) as Salary
    from Employee e, most_recent_month m
    where e.ID = m.Id
    and e.Month != m.most_recent)
select Id, Month, Salary
from cum_salary
order by 1 asc, 2 desc;
