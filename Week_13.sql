-- SETUP 
create or replace table testing_data(id int autoincrement start 1 increment 1, product string, stock_amount int,date_of_check date);
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero capes',1,'2022-01-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero capes',2,'2022-01-02');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero capes',NULL,'2022-02-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero capes',NULL,'2022-03-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero masks',5,'2022-01-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero masks',NULL,'2022-02-13');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero pants',6,'2022-01-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero pants',NULL,'2022-01-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero pants',3,'2022-04-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero pants',2,'2022-07-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero pants',NULL,'2022-01-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero pants',3,'2022-05-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero pants',NULL,'2022-10-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero masks',10,'2022-11-01');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero masks',NULL,'2022-02-14');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero masks',NULL,'2022-02-15');
insert into testing_data (product,stock_amount,date_of_check) values ('Superhero masks',NULL,'2022-02-13');

-- OUTPUT
select 
    id,
    product,
    stock_amount,
    IFNULL(
        stock_amount,
        lag(stock_amount) ignore nulls over (partition by product order by date_of_check) 
    ) as stock_amount_filled_out,
    date_of_check
from testing_data
order by product, date_of_check asc;