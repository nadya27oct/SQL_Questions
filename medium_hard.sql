with t1 as
  (select p1.meeting_id, p1.person_id as id_1, p2.person_id as id_2, count(*) as meeting_count
  from participant p1, participant p2
  where p1.person_id < p2.person_id
  and p1.meeting_id = p2.meeting_id
  group by p1.person_id, p2.person_id)
select
m1.title as meeting
concat(p1.first_name,p1.last_name) as first_person,
concat(p1.first_name,p1.last_name) as second_person,
from t1, meeting_id m1, person p1
where t1.meeting_id = m1.meeting_id
and t1.id_1 = p1.person_id
and t1.id_2 = p1.person_id
and t1.meeting_count = (select max(meeting_count) from t1)

Question 1 - Month over Month percentage change for MAU.

/*
For each month, what is the count of distinct user ID.
Is this for only year 2018?
Add a column that represents each month.
Group by month count
another function to get lag and call that column prev_month_active_users
DATE_TRUNC('month',date_id)
*/
with
monthly_users as
  (select extract(month from date_id) as month, count(distinct user_id) as user_count
  from logins
  group by extract(month from date_id)),
prev_month_users as
    (select t1.*, lag(t1.user_count) over (partition by () order by t1.t1.month) as prev_month_uc
    from monthly_users t1)
select t2.month, round((t2.prev_month_uc - t2.user_count)/t2.user_count,2) as percent_change_mau
from prev_month_users t2;

Question 2 - Label each node as root, inner and leaf

select node,
case (
  when parent is null then 'Root'
  when parent = (select node from tree where parent is null) then 'Inner'
  else 'Leaf'
) end label
from tree;

Question 3 -
Part 1 - No of retained users per month. Retention for any month is number of users who logged in that month as well as previous month.

with users_in_both_months as
  (select t1.user_id,DATE_TRUNC('month',t1.date) as current_month, DATE_TRUNC('month',t2.date) as previous_month
  from logins t1, logins t2
  where t1.user_id = t2.user_id
  and DATE_TRUNC('month',t1.date) = DATE_TRUNC('month',t2.date) + interval '1 Month'),
monthly_retained_users
  (select u1.current_month,u1.previous_month,count(distinct u1.user_id) as user_count
  from users_in_both_months u1
  group by u1.current_month,u1.previous_month)
select m1.current_month, m1.user_count as retained_users
from monthly_retained_users m1

Part 2 - No of churned users. Those who did not come back this month

with monthly_retained_users as
  (select DATE_TRUNC('month',t1.date_id) as current_month,
  DATE_TRUNC('month',t2.date_id) as prev_month,
  count(distinct t1.user_id) as users_retained
  from logins t1, logins t2
  where t1.user_id = t2.user_id
  and DATE_TRUNC('month',t1.date) = DATE_TRUNC('month',t2.date) + interval '1 Month')
  group by DATE_TRUNC('month',t1.date_id), DATE_TRUNC('month',t2.date_id)),
total_users as
  (select DATE_TRUNC('month',date) as month_cur, count(distinct user_id) as total_monthly_users
  from logins
  group by DATE_TRUNC('month',date) )

select m.current_month, t.total_monthly_users - m.users_retained as users_churned
from monthly_retained_users m, total_users t
where m.current_month = t.month_cur - interval '1 month'

Part 3 - No. of reactivated users in a given month

select t1.max_month_active as given_month, count(distinct t1.user_id) as reactivated_users
from
  (select user_id,min(extract(month from date_id)) as min_month_active,
  max(extract(month from date_id)) as max_month_active,
  max(extract(month from date_id)) - min(extract(month from date_id)) + 1 as ideal_active_months,
  count(distinct (extract(month from date_id))) as actual_active_months
  from login
  group by user_id) t1
where t1.min_month_active != t1.max_month_active
and t1.actual_active_months < t1.ideal_active_months
group by t1.max_month_active;

Question 4 - Cumulative cash flow for each day

select date,
sum(cash_flow) over (partition by () order by date) as cumulative_cash_flow
from transactions;

Question 5 - 7 day rolling average of signups.

select date,
avg(signups) over (partition by () order by date
rows between preceding 6 and current row)
from signups

Question 6 - Response time per email ID sent to Zach

-- Get IDs that is from zach@g.com

select e.id, timestampdiff(second, e.timestamp - z.timestamp) as response_time
  from emails z, emails e
  where z.subject = e.subject
  and z.to = e.from
  and z.from = 'zach@g.com'

Question 7 Part 1 - Get employee number with highest salary

select empno where salary =  (select max(salary) from salaries);

with salary_rank as
  (select depname,empno, salary,
  rank(empno) over (order by salary desc) as rank_based_on_sal
  from salaries)
select empno from salary_rank
where rank_based_on_sal = 1;

Question 7 Part 2 - Average salary per department

select depname, empno, salary,
avg(salary) over (partition by depname)
as average_dept_salary
from  salaries;

Question 7 Part 3 - Rank each employee based on salary within their department. Highest salary should get a rank of 1.

select depname, empno, salary,
rank() over (partition by depname order by salary desc) rank_within_dept
from salaries;

Question 8 - Create a histogram of streaming session. Display number of sessions within a streaming length bucket of size 5 seconds.

with bins as
  (select session_id, length_sessions, floor(length_sessions / 5) * 5 as lower_limit
  from sessions)
select lower_limit,lower_limit+5,count(distinct session_id) as number_of_sessions
from bins
group by lower_limit;



Question 9 - Get pairs of state with streaming amounts within 1000 of each other.

Final result
state a | state b
 -------| -------
NC      |   WY
LA      |   NJ

select t1.state as state_a, t2.state as state_b
from state_streams t1, state_streams t2
where ABS(1.total_streams - t2.total_streams) < 1000
and t1.state != t2.state;

Question 10 - Count users in each class based on the mapping.

select class,count(distinct user) as users_per_class
from
(select user, class,
  from table
  group by user
  having count(distinct class) < 2
union
select user, 'b' as class,
  from table
  group by user
  having count(distinct class) = 2) t1
group by class;

/*
Get 2nd highest salary.
*/

select ifnull(t1.Salary,NULL)
from
  (select ID, Salary, rank() over (order by Salary DESC)
  from Employees) t1
where t1.rank = 2;

select Salary from Employees order by Salary Desc Offset 1 Limit 1;

/*
Find duplicate emails
*/
select Email from Person group by Email
having count(distinct Id) > 1;

/* Find Dates with higher temperature than previous dates.

---------+------------------+------------------+
| Id(INT) | RecordDate(DATE) | Temperature(INT) |
+---------+------------------+------------------+
|       1 |       2015-01-01 |               10 |
|       2 |       2015-01-02 |               25 |
|       3 |       2015-01-03 |               20 |
|       4 |       2015-01-04 |               30 |
+---------+------------------+------------------+
*/
select w1.RecordDate
from Weather w1, Weather w2
where w1.RecordDate = DATE_ADD(w2.RecordDate, Interval 1 Day)
and w1.Temperature > w2.Temperature;

/* Find employees who have the highest salary in each department.
Output Department, Employee, Salary
*/
Select d.Name as Department,e.Name as Employee, e.Salary
from
  (select Name, Salary, DepartmentId,
  rank () over (partition by DepartmentId order by Salary DESC) as salary_rank_per_dept
  from Employee) e
    join Department d
    on e.DepartmentId = d.ID
    where e.salary_rank_per_dept = 1;

/*
Change seats for adjacent students.
*/

select t1.new_id,t1.student 
  (select id, student,
  case
  (when id = (select max(id) from student) then id
   when id % 2 = 0 then id - 1
   else id % 2 = 1 and id not in (select max(id) from student) then id + 1
   ) end new_id
  from seat) t1
order by t1.new_id
