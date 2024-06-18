create database if not exists Library;

create table publisher(
				publisher_name varchar(50) not null  primary key,
                publisher_address varchar(255),
                publisher_phone varchar(50),
				constraint chk_publisher_phone check (publisher_phone regexp '^[0-9]{3}-[0-9]{3}-[0-9]{4}$')
			);
            
create table books(
				book_id int primary key,
                book_title varchar(50),
				book_publisher_name varchar(50),
                CONSTRAINT fk_publisher FOREIGN KEY (book_publisher_name) REFERENCES publisher(publisher_name),
				CONSTRAINT chk_book_title CHECK (book_title <> '')
				);
                
                
create table book_authors(
				author_book_id int,
                author_name varchar(50),
                foreign key (author_book_id)
                references books(book_id)
				on delete cascade
                on update cascade,
				constraint chk_author_name check (author_name <> '')
                );

alter table book_authors 
add column author_id int auto_increment primary key first;
                
create table library_branch(
			    branch_name varchar(50) not null,
				branch_address varchar(50)
                );
                
alter table library_branch
add column branch_id int auto_increment primary key first;

create table book_copies(
				copy_book_id int,
                copy_branch_id int,
                number_of_copies int,
                
                foreign key (copy_book_id) 
                references books(book_id)
                on update CASCADE 
				on delete CASCADE,
             
                foreign key (copy_branch_id) 
                references library_branch(branch_id)
				on update CASCADE 
				on delete CASCADE,
                constraint chk_number_of_copies check (number_of_copies > 0)
				);           
      
alter table book_copies
add column copies_id int auto_increment primary key first;

create table borrower(
				borrower_card_no int not null primary key,
				borrower_name varchar(50),
				borrower_address varchar(255),
                borrower_phone varchar(50)
                constraint chk_borrower_phone check (borrower_phone regexp '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'),
				constraint chk_borrower_name check (borrower_name <> '')
                );
				
create table book_loans(
				
                loans_book_id int,
				loans_branch_id int,
				loans_card_no int,
				loans_date_out varchar(50),
                loans_due_date varchar(50),
                
				foreign key (loans_book_id) 
                references books(book_id)
                on update CASCADE 
				on delete CASCADE,
             
                foreign key (loans_branch_id) 
                references library_branch(branch_id)
                on update CASCADE 
				on delete CASCADE,
                
                foreign key (loans_card_no) 
                references borrower(borrower_card_no)
				on update CASCADE 
				on delete CASCADE,
                constraint chk_loans_date_out check (str_to_date(loans_date_out, '%m/%d/%Y') is not null),
				constraint chk_loans_due_date check (str_to_date(loans_due_date, '%m/%d/%Y') is not null)
				);        
                
alter table book_loans
add column loan_id int auto_increment primary key first;

/* 1.How many copies of the book titled "The Lost Tribe" are owned by the library branch whose name is "Sharpstown"?
2.How many copies of the book titled "The Lost Tribe" are owned by each library branch?
3.Retrieve the names of all borrowers who do not have any books checked out.
4.For each book that is loaned out from the "Sharpstown" branch and whose DueDate is 2/3/18, 
retrieve the book title, the borrower's name, and the borrower's address. 
5.For each library branch, retrieve the branch name and the total number of books loaned out from that branch.
6.Retrieve the names, addresses, and number of books checked out for all borrowers who have more than five books checked out.
7.For each book authored by "Stephen King", 
retrieve the title and the number of copies owned by the library branch whose name is "Central".*/

select * from book_copies;
select * from library_branch;
select * from books;
select * from book_authors;
select * from book_loans;
select * from borrower;
select * from publisher;

desc book_copies;
desc library_branch;
desc books;
desc book_authors;
desc book_loans;
desc borrower;
desc publisher;


-- 1.How many copies of the book titled "The Lost Tribe" are owned by the library branch whose name is "Sharpstown"?

select bc.number_of_copies as copies
from books b
left join book_copies bc
on b.book_id = bc.copy_book_id
left join library_branch lb
on bc.copy_branch_id = lb.branch_id
where book_title = "The Lost Tribe"
and branch_name  = "Sharpstown"
;

-- 2.How many copies of the book titled "The Lost Tribe" are owned by each library branch?

select lb.branch_name,sum(bc.number_of_copies) as copies
from books b
left join book_copies bc
on b.book_id = bc.copy_book_id
left join library_branch lb
on bc.copy_branch_id = lb.branch_id
where book_title = "The Lost Tribe"
group by lb.branch_name
;

-- 3.Retrieve the names of all borrowers who do not have any books checked out.

select  b.borrower_name
from borrower b 
left join book_loans bl
on b.borrower_card_no = bl.loans_card_no
where b.borrower_card_no not in (select bl.loans_card_no from book_loans bl)
;
select  b.borrower_name
from borrower b
left join book_loans bl 
on b.borrower_card_no = bl.loans_card_no
where bl.loans_card_no is null;

/* 4.For each book that is loaned out from the "Sharpstown" branch and whose DueDate is 2/3/18, 
retrieve the book title, the borrower's name, and the borrower's address.*/

select b.book_title,
br.borrower_name,
br.borrower_address
from books b
left join book_loans bl
on b.book_id = bl.loans_book_id
left join borrower br
on br.borrower_card_no = bl.loans_card_no
left join library_branch lb
on bl.loans_branch_id = lb.branch_id
where lb.branch_name = "Sharpstown" 
and bl.loans_due_date = "2/3/18"
;

-- 5.For each library branch, retrieve the branch name and the total number of books loaned out from that branch.

select lb.branch_name,
count(bl.loans_branch_id) as total_number_of_books
from library_branch lb
left join book_loans bl
on lb.branch_id = bl.loans_branch_id
group by lb.branch_name
order by total_number_of_books desc
;

/* 6.Retrieve the names, addresses, and number of books checked out 
for all borrowers who have more than five books checked out.*/

select br.borrower_name,
br.borrower_address,
count(bl.loans_book_id) as number_of_books
from books b
left join book_loans bl
on b.book_id = bl.loans_book_id
left join borrower br
on bl.loans_card_no = br.borrower_card_no
group by loans_card_no
having number_of_books > 5
order by number_of_books desc
;

/* 7.For each book authored by "Stephen King", 
retrieve the title and the number of copies owned by the library branch whose name is "Central".*/

select b.book_title,
bc.number_of_copies 
from books b
left join book_authors ba
on b.book_id = ba.author_book_id
left join book_copies bc
on b.book_id = bc.copy_book_id
left join library_branch lb
on bc.copy_branch_id = lb.branch_id
where author_name = "Stephen King" 
and branch_name = "Central"
;

-- 8. How can you list all the authors and the number of books they have written that are available in the library?

select  ba.author_name, 
count(b.book_id) as number_of_books
from book_authors ba
left join books b on ba.author_book_id = b.book_id
group by ba.author_name
;

-- 9.How can you find all books that have never been borrowed?

select br.borrower_name
from borrower br
left join book_loans bl
on br.borrower_card_no = bl.loans_card_no
group by br.borrower_name
having count(distinct bl.loans_card_no) <> (select count(*) borrower)
;
select  b.borrower_name
from borrower b
left join book_loans bl 
on b.borrower_card_no = bl.loans_card_no
where bl.loans_card_no is null;
 
-- 10.How can you find the total number of books borrowed per branch in year 2018?

select lb.branch_name, 
count(bl.loan_id) as total_books_borrowed
from book_loans bl
join library_branch lb on bl.loans_branch_id = lb.branch_id
where year(str_to_date(bl.loans_date_out, '%m/%d/%Y')) = 2018
group by lb.branch_name
;

/* 11.How can you list all branches and the count of books borrowed in each branch,
 categorized by whether the count is 'Low', 'Medium', or 'High'? */
 
 with cte as (
    select lb.branch_name, 
	count(bl.loan_id) as total_books_borrowed
    from book_loans bl
    left join library_branch lb 
    on bl.loans_branch_id = lb.branch_id
    group by lb.branch_name
)

select branch_name, 
total_books_borrowed,
case
	when total_books_borrowed < 10 then 'Low'
	when total_books_borrowed between 10 and 20 then 'Medium'
	else 'High'
    end as  borrow_category
from cte;

-- 12.How can you find the most recent loan date for each borrower, along with their name and address?

select borrower_name,
borrower_address,
loans_date_out
from (
    select br.borrower_name,
	br.borrower_address,
	bl.loans_date_out,
	row_number() over (partition by bl.loans_card_no order by str_to_date(bl.loans_date_out, '%m/%d/%Y') desc) as rn
    from borrower br
    left join book_loans bl 
    on br.borrower_card_no = bl.loans_card_no
) subquery
where rn = 1
;

/* 13.How can you find the branch with the highest number of loans for each book,
 along with the branch name and the total number of loans? */ 

select book_id,
book_title,
branch_name,
total_loans
from (
    select
	b.book_id,
	b.book_title,
	lb.branch_name,
	count(bl.loan_id) as total_loans,
	rank() over (partition by bl.loans_book_id order by count(bl.loan_id) desc) as rn
    from books b
    left join book_loans bl on b.book_id = bl.loans_book_id
    left join library_branch lb ON bl.loans_branch_id = lb.branch_id
    group by
        b.book_id,
        b.book_title,
        lb.branch_name
) subquery
where rn = 1
;

/* 14.How can you find the publishers who have published more books 
than the average number of books published by all publishers? */

select p.publisher_name,
count(b.book_id) as total_books_published
from publisher p
left join books b 
on p.publisher_name = b.book_publisher_name
group by p.publisher_name
having 
count(b.book_id) > (
        select avg(total_books)
        from (
           select count(b2.book_id) as total_books
			from books b2
           group by b2.book_publisher_name
        ) subquery
    );

-- 15.How can you find borrowers who have borrowed all the books available in a specific branch?

select br.borrower_name
from borrower br
where not exists (
        select  b.book_id
        from books b
        left join book_copies bc 
        on b.book_id = bc.copy_book_id
        where bc.copy_branch_id = 3
        except
        select bl.loans_book_id
        from book_loans bl
        where bl.loans_card_no = br.borrower_card_no
		and bl.loans_branch_id = 3
    );

