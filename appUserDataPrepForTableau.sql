
--Collect total user number in the database and their average actions done
Select license_status, COUNT(Distinct(sender_id)) as user_number, COUNT(Distinct(id))/COUNT(Distinct(sender_id)) as avg_action
From test_wiris.dbo.test_wiris_prepped
group by license_status


-----------------------------------------------------------------------------------------
--Extract total number of actions (in each action type) for active and trial license
Select license_status, type, COUNT(Distinct(id)) as action_count
From test_wiris.dbo.test_wiris_prepped
group by license_status,type
order by 1,2


----------------------------------------------------------------------------------------
--Users who purchased after trial and all trial users
with purchased_license as
	(Select sender_id, COUNT(Distinct(license_status)) as count_license
	From test_wiris.dbo.test_wiris_prepped
	group by sender_id
	having COUNT(Distinct(license_status)) > 1 
	),
	trial_users as
  (Select sender_id From test_wiris.dbo.test_wiris_prepped
	where license_status like 'trial'
	group by sender_id
	)

select count(sender_id) from purchased_license  --number of users purchased the product after trial
union all
select count(sender_id) from trial_users  --total number of trial users


------------------------------------------------------------------------------------------
-- Countries of users who purchased 
with purchased_license as
	(Select sender_id, COUNT(Distinct(license_status)) as count_license, business_area, industry, industry_group, country, COUNT(Distinct(id)) as event_count
	From test_wiris.dbo.test_wiris_prepped
	group by sender_id,business_area, industry, industry_group, country
	having COUNT(Distinct(license_status)) > 1 
	)

select country, count(sender_id) from purchased_license
group by country
order by 2 desc


----------------------------------------------------------------
--Create table with sender_id of purchasers for later use
DROP Table if exists #purchasers
Create Table #purchasers
(
sender_id nvarchar(255)
)

Insert Into #purchasers
Select sender_id
	From test_wiris.dbo.test_wiris_prepped
	group by sender_id
	having COUNT(Distinct(license_status)) > 1 


-----------------------------------------------------------------
--Calculate action count for purchasers in active and trial stages
select sender_id, count(id) as action_count, license_status from test_wiris.dbo.test_wiris_prepped
where sender_id in (select sender_id from #purchasers)
group by license_status,sender_id
order by sender_id


------------------------------------------------------
--Create table with all entries from purchasers
DROP Table if exists #purchased_details
Create Table #purchased_details
(
id nvarchar(255),
sender_id nvarchar(255),
type nvarchar(255),
industry_group nvarchar(255),
--action_count numeric,
license_status nvarchar(255),
trial_start_date dateTime,
date_purchased dateTime
)

Insert Into #purchased_details
Select id, sender_id, type, industry_group, license_status, trial_start_date, date_purchased
	  from test_wiris.dbo.test_wiris_prepped
	  where sender_id in (select sender_id from #purchasers)
      

-------------------------------------------------------------------------------------
--Extract days between trial and purchase
select sender_id, sum(datediff(day,trial_start_date,date_purchased))/count(distinct(id)) as days_between from #purchased_details
where datediff(day,trial_start_date,date_purchased) > -1
group by sender_id
order by 2


-----------------------------------------------------------------------------------------
--Extract average actions before and after purchase
with before_after as
(	select sender_id, count(id) as action_count, license_status, type from #purchased_details
	where datediff(day,trial_start_date,date_purchased) > -1
	group by license_status,sender_id,type
	)

select sum(action_count)/count(sender_id) as action_avg, license_status,type from before_after
group by license_status, type


-----------------------------------------------------------------------------------------
--Extract industry group of purchasers
with sender_industry as
(	select sender_id, industry_group from #purchased_details
	where datediff(day,trial_start_date,date_purchased) > -1
	group by sender_id,industry_group
	)
select count(industry_group),industry_group from sender_industry
group by  industry_group
order by 1 desc
