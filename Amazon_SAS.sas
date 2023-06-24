libname amazon xlsx '/home/u63320142/Assignment2/amazon.xlsx';
/* cleaning the tables and their formats */
data products;
set AMAZON.products;
proc print data= amazon.products(obs=10);
run;

data products_cleaned;
set products;
    category1 = scan(category, 1, '|');
    category2 = scan(category, 2, '|');
    category3 = scan(category, 3, '|');
    category4 = scan(category, 4, '|');
run;
proc print data=products_cleaned(obs=10);
run;

Proc Contents data=amazon.reviews; RUN;
data reviews;
set AMAZON.reviews;
proc print data=amazon.reviews(obs=10);
run;

data reviews_cleaned;
set reviews;
   length user_id_new $100.;
   length review_id_new $100.;
   length review_title_new $100.;
   length review_content_new $1000.;
   do i = 1 to countw(user_id, ",");
      user_id_new = scan(user_id, i, ",");
      review_id_new = scan(review_id, i, ",");
      review_title_new =  scan(review_title, i, ",");
      review_content_new = scan(review_content, i, ",");
      output;
   end;
   drop review_id;
   drop user_id;
   drop review_title;
   drop review_content;
   drop i;
   rename review_id_new = review_id;
   rename user_id_new = user_id;
   rename review_title_new = review_title;
   rename review_content_new = review_content;
run;
proc print data=reviews_cleaned(obs=10);
run;


Proc Contents data=amazon.Users; RUN;
data users;
set AMAZON.Users;
proc print data=users(obs=10);
run;

data users_cleaned;
set users;
	length user_id_new $100.;
	length user_name_new $100.;
	do i = 1 to countw(user_id, ",");
		user_id_new = scan(user_id, i, ",");
		user_name_new = scan(user_name, i, ",");
		output;
	end;
	drop user_id;
	drop user_name;
	drop i;
	rename user_id_new = user_id;
	rename user_name_new = user_name;
run;
proc print data=users_cleaned(obs=10);
run;
/* creating new labels for the product table */
data products_cleaned;
	set products_cleaned;
label product_id="Product ID"
	product_name = "Product Name"
	category = "Category"
	discounted_price = "Slashed Price"
	actual_price = "Real Price"
	rating = "Rating"
	rating_count= "Rating Count"
	img_link= "Image"
	product_link= "Product Link";
run;
/* Sorting the data */
Proc sort data=products_cleaned
	out=products_cleaned
	NODUPKEY;
	By Product_id product_link;
Run;
Proc sort data=reviews_cleaned
	out=reviews_cleaned
	NODUPKEY;
	By review_id;
Run;
Proc sort data=users_cleaned
	out=users_cleaned
	NODUPKEY;
	By user_id;
Run;
/*Changing rating count into numerical  */
proc contents data= products_cleaned;
run;
/* fixing data types */
data products_cleaned;
set products_cleaned;
if  not missing(rating_count)
and not missing(rating);
actual_price_num = input(compress(actual_price, '₹'),comma10.);
drop actual_price;
rename actual_price_num = actual_price;
discounted_price_num = input(compress(discounted_price, '₹'),comma10.);
drop discounted_price;
rename discounted_price_num = discounted_price;
rating_count_num = input(rating_count,comma10.);
drop rating_count;
rename rating_count_num = rating_count;
proc contents data= products_cleaned;
run;
proc means data= products_cleaned n nmiss median;
var rating_count;
run;
proc means data= products_cleaned n nmiss median;
var actual_price;
run;
data products_cleaned;
	set products_cleaned;
	if rating_count < 0 and rating_count > 100000 then rating_count = '.';
	if missing(rating_count) then rating_count = 4917;
run;
title1 "Statistical data on Review Count";
footnote "all the missing values were changed to the median, which is 4917";
proc means data= products_cleaned ;
	var rating_count;
run;
ods noproctitle;
/* defining categories */
proc freq data=products_cleaned;
	tables category;
	run;
Proc sort data=products_cleaned;
by category;run;
data products_cleaned;
	set products_cleaned;
	if find(category,"Computers&Accessories") = 1 then Sorted_Catergory = "Computers&Accessories";
	else if find(category,"Electronics") = 1 then Sorted_Catergory = "Electronics";
	else if find(category,"Home&Kitchen") = 1 then Sorted_Catergory = "Home&Kitchen";
	else if find(category,"Car&Motorbike") = 1 then Sorted_Catergory ="Car&Motorbike";
	else if find(category,"Health&personalcare") = 1 then Sorted_Catergory ="Health&personalcare";
	else if find(category,"HomeImprovement") = 1 then Sorted_Catergory ="HomeImprovement";
	else if find(category,"MusicalInstrument") = 1 then Sorted_Catergory ="MusicalInstrument";
	else if find(category,"OfficeProducts") = 1 then Sorted_Catergory ="OfficeProducts";
	else if find(category,"Toys&Games") = 1 then Sorted_Catergory ="Toys&Games";
	else Sorted_Catergory = category;
		run;
proc freq data=products_cleaned;
	tables Sorted_Catergory;
	run;
/*creating a column discount percentage  */
data products_cleaned;
  set products_cleaned;
  discount_percentage = (1 - (discounted_price / actual_price)) * 100;
	run;
/* Sort the reviews_nodups dataset by the product_id variable */
proc sort data=reviews_cleaned;
	by product_id;
	run;
proc sort data=products_cleaned;
	by product_id;
	run;


/*  Finding products wuth the highest reviews
 	Merge the products and reviews_nodups datasets */
data prod_rev;
	merge products_cleaned reviews_cleaned;
	by product_id;
	run;

ods pdf file= "/home/u63320142/Assignment2/AMAZON.pdf" style =analysis;
ods graphic / reset width=8in height=4.8in imagemap;
/* Calculate the average rating score for each category */
proc means data=prod_rev mean;
var rating;
class Sorted_catergory;
run;
/* Are higher-rated products more expensive? */
proc means data=products_cleaned;
var rating actual_price;
run;

/* Create a scatter plot of the rating and price variables */
proc sgplot data=products_cleaned;
scatter x=rating y=actual_price;
xaxis label="Rating";
yaxis label="actual_price";
run;
/*How does discount affect the number of ratings and reviews?  */
proc corr data=products_cleaned;
  var discounted_price rating rating_count;
run;
/*Which categories have higher average product prices*/
proc means data=products_cleaned;
  var actual_price;
  class sorted_catergory;
run;
Proc Sort data=products_cleaned;
by actual_price;
run;

proc univariate data=products_cleaned;
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=products_cleaned;
	vbar discounted_price/ group=rating groupdisplay=cluster datalabel;
	yaxis grid;
run;
ods graphics / reset;
/* Determine the average rating per category: */
proc means data=products_cleaned;
  class sorted_catergory;
  var rating;
  output out=average_rating_per_category mean=avg_rating;
run;

proc sort data=average_rating_per_category;
  by descending avg_rating;
run;

proc print data=average_rating_per_category;
  var sorted_catergory avg_rating;
  title 'Average Rating per Category';
run;
/* Create a bar chart of average rating per category */
proc sgplot data=average_rating_per_category;
  vbar sorted_catergory / response=avg_rating
                  stat=mean
                  barwidth=0.5;
  xaxis display=(nolabel);
  yaxis label="Average Rating";
  title 'Average Rating per Category';
run;
proc contents data=products_cleaned; run;
proc means data=products_cleaned;
  class sorted_catergory;
  var discount_percentage;
  output out=avg_discount_per_category mean=avg_discount;
run;

proc print data=avg_discount_per_category;
  var sorted_catergory avg_discount;
  title 'Average Discount Percentage by Category';
run;
/*Visualize the distribution of discount percentages:  */
proc sgplot data=products_cleaned;
  histogram discount_percentage / binwidth=5;
  xaxis label="Discount Percentage";
  yaxis label="Frequency";
  title 'Distribution of Discount Percentages';
run;
/* What words in reviews are associated with higher overall ratings?  */
/* Step 1: Load the data */
data word_ratings;
set products;
/* where rating > 4.5; */
merge reviews_cleaned;
by product_id;
keep rating review_content;
run;

proc print data=word_ratings(obs=10);
run;

/* Step 2: Clean the review content */
data cleaned_reviews;
  set word_ratings;
  review_content = prxchange('s/[^[:alnum:][:blank:]]//', -1, review_content);
run;

/* Step 3: Sort the cleaned_reviews dataset by high_rating */
proc sort data=cleaned_reviews;
  by rating;
run;

/* Step 4: Create a new variable to indicate higher overall ratings */
data cleaned_reviews;
  set cleaned_reviews;
  if rating >= 4 then high_rating = 1;
  else high_rating = 0;
run;

/* Step 5: Tokenize the reviews */
data tokenized_reviews;
  set cleaned_reviews;
  length word $20;
  retain high_rating;
  do i = 1 to countw(review_content);
    word = scan(review_content, i);
    output;
  end;
  drop i review_content;
run;

/* Step 6: Calculate word frequencies for high and low ratings */
proc freq data=tokenized_reviews noprint;
  by high_rating;
  tables word / out=word_freq;
run;

/* Step 7: Sort the word frequencies by high ratings */
proc sort data=word_freq ;
  by descending high_rating count;
run;

/* Step 8: Print the words associated with higher ratings */
data high_rating_words;
  set word_freq;
  where high_rating = 1;
run;

proc sort data=high_rating_words;
	by descending percent count;
run;


proc print data=high_rating_words(obs=20);
  var word count;
  title 'Words Associated with Higher Ratings';
run;
ods pdf close;