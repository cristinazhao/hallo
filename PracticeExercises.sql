-- Who are all the customers by name, the names of their nations, and the names of their regions? Use appropriate aliases for
-- fields and tables. Sort by customer name, ascending.
select
  c.c_name as customer_name,
  n.n_name as nation,
  r.r_name as region
from
  tpch_sf10.customer as c
  join
    tpch_sf10.nation as n
      on n.n_nationkey = c.c_nationkey
  join
    tpch_sf10.region as r
      on r.r_regionkey = n.n_regionkey
order by 1
;

-- What is the total revenue by orderkey, orderdate, and shippriority for orders placed prior to 3/15/1995 and shipped after
-- 3/15/1995 in the 'BUILDING' market segment. Return only the top 20 highest revenue amounts by date. (Revenue is defined as
-- extendedprice minus the discounted amount.)
select
  l.l_orderkey,
  sum(l.l_extendedprice * (1 - l.l_discount)) as revenue,
  o.o_orderdate,
  o.o_shippriority
from
  customer as c
  join orders as o
    on o.o_custkey = c.c_custkey
  join lineitem as l
    on l.l_orderkey = o.o_orderkey
where
  c.c_mktsegment = 'BUILDING'
  and o.o_orderdate < to_date('1995-03-15')
  and l.l_shipdate > to_date('1995-03-15')
group by
  l.l_orderkey,
  o.o_orderdate,
  o.o_shippriority
order by
  revenue desc,
  o.o_orderdate
limit 20
;

-- List for each nation in Asia the revenue volume in 1994 that resulted from lineitem transactions in which the customer
-- ordering parts and the supplier filling them were both within that nation. Return the nations and revenue volume in
-- descending order by revenue. Revenue volume for all qualifying lineitems in a particular nation is defined as
-- sum(l_extendedprice * (1 - l_discount)).
select
  n.n_name,
  sum(l.l_extendedprice * (1 - l.l_discount)) as revenue
from
  customer as c
  join orders as o
    on o.o_custkey = c.c_custkey
  join lineitem as l
    on l.l_orderkey = o.o_orderkey
  join supplier as s
    on s.s_suppkey = l.l_suppkey
    and s.s_nationkey = c.c_nationkey
  join nation as n
    on n.n_nationkey = s.s_nationkey
  join region as r
    on r.r_regionkey = n.n_regionkey
where
  r.r_name = 'ASIA'
  and o.o_orderdate >= to_date('1994-01-01')
  and o.o_orderdate < to_date('1994-01-01') + interval '1 year'
group by
  n_name
order by
  revenue desc;

-- Find the top 20 customers, in terms of their effect on lost revenue in the fourth quarter of 1993, who have returned
-- parts. Consider only parts that were ordered in the specified quarter. List the customer's name, address, nation, phone
-- number, account balance, comment information and revenue lost. List the customers in descending order of lost revenue.
-- Revenue lost is defined as sum(l_extendedprice*(1-l_discount)) for all qualifying lineitems.
select
  c.c_custkey,
  c.c_name,
  sum(l.l_extendedprice * (1 - l.l_discount)) as revenue,
  c.c_acctbal,
  n.n_name,
  c.c_address,
  c.c_phone,
  c.c_comment
from
  customer as c
  join orders as o
    on o_custkey = c_custkey
  join lineitem as l
    on l_orderkey = o_orderkey
  join nation as n
    on n_nationkey = c_nationkey
where
  o.o_orderdate >= to_date('1993-10-01')
  and o.o_orderdate < to_date('1993-10-01') + interval '3 months'
  and l.l_returnflag = 'R'
group by
  c.c_custkey,
  c.c_name,
  c.c_acctbal,
  c.c_phone,
  n.n_name,
  c.c_address,
  c.c_comment
order by
  revenue desc
limit 20;

-- Count, by ship mode, lineitems actually received by customers in 1994, the number of lineitems belonging to orders for
-- which the l_receiptdate exceeds the l_commitdate for either 'MAIL' or 'SHIP' ship modes. Return only lineitems that were
-- actually shipped before the l_commitdate. Partition the line items into two groups, those with priority URGENT or HIGH,
-- and those with a priority other than URGENT or HIGH.
select
  l.l_shipmode,
  sum(case
      when o.o_orderpriority = '1-URGENT'
          or o.o_orderpriority = '2-HIGH'
          then 1
      else 0
  end) as high_line_count,
  sum(case
      when o.o_orderpriority <> '1-URGENT'
          and o.o_orderpriority <> '2-HIGH'
          then 1
      else 0
  end) as low_line_count
from
  orders as o
  join lineitem as l
    on l.l_orderkey = o.o_orderkey
where
  l.l_shipmode in ('MAIL', 'SHIP')
  and l.l_commitdate < l.l_receiptdate
  and l.l_shipdate < l.l_commitdate
  and l.l_receiptdate >= to_date('1994-01-01')
  and l.l_receiptdate < to_date('1994-01-01') + interval '1 year'
group by
  l.l_shipmode
order by
  l.l_shipmode;

-- What is the total revenue for brands 'Brand#12', 'Brand#23', and 'Brand#34'? Count only Brand#12 orders where the container
-- was 'SM CASE', 'SM BOX', 'SM PACK', OR 'SM PKG', had a quantity greater or equal to 1 and less than or equal to 11 and the
-- size was between 1 and 5. Only count Brand#23 orders in 'MED CASE', 'MED BOX', 'MED PACK', OR 'MED PKG', had a quantity greater
-- or equal to 10 and less than or equal to 20 and the size was between 1 and 10. Count only Brand#34 orders where the container
-- was 'LG CASE', 'LG BOX', 'LG PACK', OR 'LG PKG', had a quantity greater or equal to 20 and less than or equal to 30 and the
-- size was between 1 and 15. All brands should have a shipmode of 'AIR' or 'AIR REG' and shipping instructions to 'DELIVER IN PERSON'.
select
  sum(l.l_extendedprice* (1 - l.l_discount)) as revenue
from
  lineitem as l
  join part as p
    on p.p_partkey = l.l_partkey
where
  (
    p.p_brand = 'Brand#12'
    and p.p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
    and l.l_quantity >= 1
    and l.l_quantity <= 1 + 10
    and p.p_size between 1 and 5
    and l.l_shipmode in ('AIR', 'AIR REG')
    and l.l_shipinstruct = 'DELIVER IN PERSON'
  )
  or
  (
    p.p_brand = 'Brand#23'
    and p.p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
    and l.l_quantity >= 10
    and l.l_quantity <= 10 + 10
    and p.p_size between 1 and 10
    and l.l_shipmode in ('AIR', 'AIR REG')
    and l.l_shipinstruct = 'DELIVER IN PERSON'
  )
  or
  (
    p.p_brand = 'Brand#34'
    and p.p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
    and l.l_quantity >= 20
    and l.l_quantity <= 20 + 10
    and p.p_size between 1 and 15
    and l.l_shipmode in ('AIR', 'AIR REG')
    and l.l_shipinstruct = 'DELIVER IN PERSON'
  );

-- What are the unique primary keys for each table? You should validate this using a query for each table.
-- E.G.
select
  c_custkey,
  count(c_custkey) as count
from customer
group by 1
order by 2 desc;

select
  c_nationkey,
  count(c_nationkey) as count
from customer
group by 1
order by 2 desc;

-- How much revenue was generated from the part most often sold? You should write a single query for this.
select
    p.p_name as part_name,
    sum(l.l_extendedprice* (1 - l.l_discount)) as revenue
from lineitem as l
    join part as p
        on p.p_partkey = l.l_partkey
group by 1
order by 2 desc
limit 1;

-- Find the supplier in Europe who can supply parts of type 'BRASS' and size '20' at minimum cost. If several suppliers in
-- that region offer the desired part type and size at the same (minimum) cost, list the parts from suppliers with the 100
-- highest account balances. For each supplier, list their account balance, name and nation; the part's number and manufacturer;
-- the supplier's address, phone number and comment information.
select
  s.s_acctbal,
  s.s_name,
  n.n_name,
  p.p_partkey,
  p.p_mfgr,
  s.s_address,
  s.s_phone,
  s.s_comment
from
  part as p
  join partsupp as ps
    on ps.ps_partkey = p.p_partkey
  join supplier as s
    on s.s_suppkey = ps.ps_suppkey
  join nation as n
    on n.n_nationkey = s.s_nationkey
  join region as r
    on r.r_regionkey = n.n_regionkey
where
    p.p_size = 20
    and p.p_type like '%BRASS'
    and r.r_name = 'EUROPE'
    and ps.ps_supplycost = (
                        select
                          min(ps.ps_supplycost)
                        from
                          partsupp as ps
                          join supplier as s
                            on s.s_suppkey = ps.ps_suppkey
                          join nation as n
                            on n.n_nationkey = s.s_nationkey
                          join region as r
                            on r.r_regionkey = n.n_regionkey
                        where
                          p.p_partkey = ps.ps_partkey
                            and r.r_name = 'EUROPE'
                        )
order by
  s.s_acctbal desc,
  n.n_name,
  s.s_name,
  p.p_partkey
  ;

-- Count the number of orders ordered in the second quarter of 1993 in which at least one lineitem was received by the customer
-- later than its committed date. List the count of such orders for each order priority sorted in ascending priority order.
select
  o.o_orderpriority,
  count(*) as order_count
from
  orders as o
where
  o.o_orderdate >= to_date('1993-07-01')
    and o.o_orderdate < to_date('1993-07-01') + interval '3 months'
    and exists (
                select
                  *
                from
                  lineitem as l
                where
                  l.l_orderkey = o.o_orderkey
                  and l.l_commitdate < l.l_receiptdate
                )
group by
  o.o_orderpriority
order by
  o.o_orderpriority;

-- Find, for France and Germany, the gross discounted revenues derived from lineitems in which parts were shipped from a supplier
-- in either nation to a customer in the other nation during 1995 and 1996. List the supplier nation, the customer nation, the year,
-- and the revenue from shipments that took place in that year. Order the answer by Supplier nation, Customer nation, and year
--(all ascending).
select
  supp_nation,
  cust_nation,
  l_year, sum(volume) as revenue
from (
      select
        n1.n_name as supp_nation,
        n2.n_name as cust_nation,
        extract(year from l.l_shipdate) as l_year,
        l.l_extendedprice * (1 - l.l_discount) as volume
      from
        supplier as s
        join lineitem as l
          on l.l_suppkey = s.s_suppkey
        join orders as o
          on o.o_orderkey = l.l_orderkey
        join customer as c
          on c.c_custkey = o.o_custkey
        join nation as n1
          on n1.n_nationkey = s.s_nationkey
        join nation as n2
          on n2.n_nationkey = c.c_nationkey
      where
         (
          (n1.n_name = 'FRANCE' and n2.n_name = 'GERMANY')
          or (n1.n_name = 'FRANCE' and n2.n_name = 'GERMANY')
          )
          and l.l_shipdate between to_date('1995-01-01') and to_date('1996-12-31')
          ) as shipping
group by
  supp_nation,
  cust_nation,
  l_year
order by
  supp_nation,
  cust_nation,
  l_year;

-- The market share for a given nation within a given region is defined as the fraction of the revenue (the sum of
-- [l_extendedprice * (1-l_discount)]) from the products of a specified type in that region that was supplied by suppliers
-- from the given nation. Find the market share for Brazil in the 'AMERICA' region for 'ECONOMY ANODIZED STEEL' in the years
-- 1995 and 1996 presented in this order.
select
  o_year,
  sum(case
        when nation = 'BRAZIL'
          then volume
        else 0
        end) / sum(volume) as mkt_share
from (
      select
        extract(year from o.o_orderdate) as o_year,
        l.l_extendedprice * (1-l.l_discount) as volume,
        n2.n_name as nation
      from
        part as p
        join lineitem as l
          on l.l_partkey = p.p_partkey
        join supplier as s
          on s.s_suppkey = l.l_suppkey
        join orders as o
          on o.o_orderkey = l.l_orderkey
        join customer as c
          on c.c_custkey = o.o_custkey
        join nation as n1
          on n1.n_nationkey = c.c_nationkey
        join nation as n2
          on n2.n_nationkey = s.s_nationkey
        join region as r
          on r.r_regionkey = n1.n_regionkey
      where
          r.r_name = 'AMERICA'
          and o.o_orderdate between to_date('1995-01-01') and to_date('1996-12-31')
          and p.p_type = 'ECONOMY ANODIZED STEEL'
        ) as all_nations
group by
  o_year
order by
  o_year;

-- Find, for each nation and each year, the profit for all parts ordered in that year that contain 'green' in their names and
-- that were filled by a supplier in that nation. The profit is defined as the sum of [(l_extendedprice*(1-l_discount)) -
-- (ps_supplycost * l_quantity)] for all lineitems describing parts in the specified line. List the nations in ascending alphabetical
-- order and, for each nation, the year and profit in descending order by year (most recent first).
select
  nation,
  o_year,
  sum(amount) as sum_profit
from (
      select
        n.n_name as nation,
        extract(year from o.o_orderdate) as o_year,
        l.l_extendedprice * (1 - l.l_discount) - ps.ps_supplycost * l.l_quantity as amount
      from
        part as p
        join lineitem as l
          on l.l_partkey = p.p_partkey
        join supplier as s
          on s.s_suppkey = l.l_suppkey
        join partsupp as ps
          on ps.ps_suppkey = l.l_suppkey
          and ps.ps_partkey = l.l_partkey
        join orders as o
          on o.o_orderkey = l.l_orderkey
        join nation as n
          on n.n_nationkey = s.s_nationkey
      where
        p_name like '%green%'
      ) as profit
group by
  nation,
  o_year
order by
  nation,
  o_year desc;

-- Find, from scanning the available stock of suppliers in Germany, all the parts that are more than .0001 of the total value of
-- all available parts. Display the part number and the value of those parts in descending order of value.
-- Needs rework
select
  ps.ps_partkey,
  sum(ps.ps_supplycost * ps.ps_availqty) as value
from
  partsupp as ps
  join supplier as s
    on s.s_suppkey = ps.ps_suppkey
  join nation as n
    on n.n_nationkey = s.s_nationkey
where
   n.n_name = 'GERMANY'
group by
  ps.ps_partkey
having
  sum(ps.ps_supplycost * ps.ps_availqty) > (
                                      select
                                        sum(ps.ps_supplycost * ps.ps_availqty) * 0.0001
                                      from
                                        partsupp as ps
                                        join supplier as s
                                          on s_suppkey = ps_suppkey
                                        join nation as n
                                          on n_nationkey = s_nationkey
                                      where
                                        n.n_name = 'GERMANY'
                                      )
order by
  value desc;

-- Determine the distribution of customers by the number of orders they have made, including customers who have no record of
-- orders, past or present. Count and report how many customers have no orders, how many have 1, 2, 3, etc. Check to ensure
-- the orders counted do not fall into one of several special categories of orders. Special categories are identified in the
-- order comment column by looking for comments with the words 'special' followed by 'requests'.
select
  c_count,
  count(*) as custdist
from (
      select
        c.c_custkey,
        count(o.o_orderkey) as c_count
      from
        customer as c
        left outer join orders as o
          on c.c_custkey = o.o_custkey
          and o.o_comment not like '%special%requests%'
      group by
        c.c_custkey
      ) as c_orders
group by
  c_count
order by
  custdist desc,
  c_count desc;

-- Determine what percentage of the revenue in September of 1995 was derived from promotional parts. Consider only parts
-- actually shipped in that month and give the percentage. Revenue is defined as (l_extendedprice * (1-l_discount)).
select
  100.00 * sum(case
                when p.p_type like 'PROMO%'
                then l.l_extendedprice*(1 - l.l_discount)
                else 0
                end) / sum(l.l_extendedprice * (1 - l.l_discount)) as promo_revenue
from
  lineitem as l
  join part as p
    on p.p_partkey = l.l_partkey
where
    l.l_shipdate >= to_date('1995-09-01')
    and l_shipdate < to_date('1995-09-01') + interval '1 month';

-- Count the number of suppliers who can supply parts that satisfy a particular customer's requirements. The customer is interested
-- in parts of eight different sizes (49, 14, 23, 45, 19, 3, 36, 9) as long as they are not of type 'MEDIUM POLISHED', not of brand
-- 'Brand#45', and not from a supplier who has had complaints registered at the Better Business Bureau. Results must be presented in
-- descending count and ascending brand, type, and size.
select
  p.p_brand,
  p.p_type,
  p.p_size,
  count(distinct ps.ps_suppkey) as supplier_cnt
from
  partsupp as ps
  join part as p
    on p_partkey = ps_partkey
where
  p.p_brand <> 'Brand#45.'
  and p.p_type not like 'MEDIUM POLISHED%'
  and p.p_size in (49, 14, 23, 45, 19, 3, 36, 9)
  and ps.ps_suppkey not in (
                          select
                            s_suppkey
                          from
                            supplier
                          where
                            s_comment like '%Customer%Complaints%'
                          )
group by
  p.p_brand,
  p.p_type,
  p.p_size
order by
  supplier_cnt desc,
  p.p_brand,
  p.p_type,
  p.p_size;

-- Determine the average lineitem quantity of parts of Brand#23. Consider parts of brand Brand#23 with a container type of 'MED BOX'
-- and determine the average lineitem quantity of such parts ordered for all orders (past and pending) in the 7-year database. What
-- would be the average yearly gross (undiscounted) loss in revenue if orders for these parts with a quantity of less than 20% of
-- this average were no longer taken?
select
  sum(l.l_extendedprice) / 7.0 as avg_yearly
from
  lineitem as l
  join part as p
    on p_partkey = l_partkey
where
    p.p_brand = 'Brand#23'
    and p.p_container = 'MED BOX'
    and l.l_quantity < (
                      select
                        0.2 * avg(l_quantity)
                      from
                        lineitem
                      );

-- List the top 100 customers who have ever placed orders of quantity > 300. List the customer name, customer key, the order key,
-- date and total price and the quantity for the order.
select
  c.c_name,
  c.c_custkey,
  o.o_orderkey,
  o.o_orderdate,
  o.o_totalprice,
  sum(l.l_quantity)
from
  customer as c
  join orders as o
    on o.o_custkey = c.c_custkey
  join lineitem as l
    on l.l_orderkey = o.o_orderkey
where
  o.o_orderkey in (
                select
                  l_orderkey
                from
                  lineitem
                group by
                  l_orderkey
                having
                  sum(l_quantity) > 300
                )
group by
  c.c_name,
  c.c_custkey,
  o.o_orderkey,
  o.o_orderdate,
  o.o_totalprice
order by
  o.o_totalprice desc,
  o.o_orderdate;

-- Identify suppliers who have an excess of a given part available; an excess is defined to be more than 50% of the parts like
-- the given part that the supplier shipped in 1994 for 'CANADA'. Only parts whose names contain 'forest' should be considered.
select
  s.s_name,
  s.s_address
from
  supplier as s
  join nation as n
    on n.n_nationkey = s.s_nationkey
where
  s_suppkey in (
                select
                  ps_suppkey
                from
                  partsupp
                where
                  ps_partkey in (
                                  select
                                    p_partkey
                                  from
                                    part
                                  where
                                    p_name like 'forest%'
                                  )
                and ps_availqty > (
                                  select
                                    0.5 * sum(l_quantity)
                                  from
                                    lineitem
                                  where
                                    l_partkey = ps_partkey
                                    and l_suppkey = ps_suppkey
                                    and l_shipdate >= to_date('1994-01-01')
                                    and l_shipdate < to_date('1994-01-01') + interval '1 year'
                                  )
                                )
    and n_name = 'CANADA'
order by
  s_name;

-- Identify suppliers, for SAUDI ARABIA, whose product was part of a multi-supplier order (with current status of 'F') where they
-- were the only supplier who failed to meet the committed delivery date.
select
  s.s_name,
  count(*) as numwait
from
  supplier as s
  join lineitem as l1
    on l1.l_suppkey = s_suppkey
  join orders as o
    on o_orderkey = l1.l_orderkey
  join nation as n
    on s_nationkey = n_nationkey
where
  o.o_orderstatus = 'F'
  and l1.l_receiptdate > l1.l_commitdate
  and exists (
              select
                *
              from
                lineitem as l2
              where
                l2.l_orderkey = l1.l_orderkey
                and l2.l_suppkey <> l1.l_suppkey
              )
  and not exists (
                  select
                    *
                  from
                    lineitem as l3
                  where
                    l3.l_orderkey = l1.l_orderkey
                    and l3.l_suppkey <> l1.l_suppkey
                    and l3.l_receiptdate > l3.l_commitdate
                  )
  and n.n_name = 'SAUDI ARABIA'
group by
  s.s_name
order by
  numwait desc,
  s.s_name;

-- Count how many customers with country codes in ('13','31’,'23','29','30','18','17') who have not placed orders for 7 years but
-- who have a greater than average “positive” account balance. Show the magnitude of that balance. Country code is defined as the
-- first two characters of c_phone.
select
  cntrycode,
  count(*) as numcust,
  sum(c_acctbal) as totacctbal
from (
      select
        substring(c_phone, 1, 2) as cntrycode,
        c_acctbal
      from
        customer
      where
        substring(c_phone, 1, 2) in ('13','31','23','29','30','18','17')
        and c_acctbal > (
                          select
                            avg(c_acctbal)
                          from
                            customer
                          where
                            c_acctbal > 0.00
                            and substring (c_phone, 1, 2) in ('13','31','23','29','30','18','17')
                          )
        and not exists (
                        select
                          *
                        from
                          orders
                        where
                          o_custkey = c_custkey
                        )
        ) as custsale
group by
  cntrycode
order by
  cntrycode;
