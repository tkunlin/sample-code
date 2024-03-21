-- QA
delete from workflow_permission where `group` ='qa.test.manager';
delete from workflow_permission where `group` ='billing.qa.test';
delete from workflow_permission where `group` ='rd.test.manager';
delete from workflow_permission where `group` ='billing.rd.test';

delete from workflow_permission where user_id in  (select id from bill_master bm where bm.keyname = 'billing.qa.test.manager');
delete from workflow_permission where user_id in  (select id from bill_master bm where bm.keyname = 'billing.qa.test');
delete from workflow_permission where user_id in  (select id from bill_master bm where bm.keyname = 'billing.rd.test.manager');
delete from workflow_permission where user_id in  (select id from bill_master bm where bm.keyname = 'billing.rd.test');

delete from bill_admin_power where bill_master in  (select id from bill_master bm where bm.keyname = 'billing.qa.test');
delete from bill_admin_power where bill_master in  (select id from bill_master bm where bm.keyname = 'billing.rd.test');
delete from bill_admin_power where bill_master in  (select id from bill_master bm where bm.keyname = 'billing.qa.test.manager');
delete from bill_admin_power where bill_master in  (select id from bill_master bm where bm.keyname = 'billing.rd.test.manager');
delete from bill_master_customer where bill_master in  (select id from bill_master bm where bm.keyname = 'billing.qa.test');
delete from bill_master_customer where bill_master in  (select id from bill_master bm where bm.keyname = 'billing.rd.test');
delete from bill_master_customer where bill_master in  (select id from bill_master bm where bm.keyname = 'billing.qa.test.manager');
delete from bill_master_customer where bill_master in  (select id from bill_master bm where bm.keyname = 'billing.rd.test.manager');


delete from bill_master where keyname='billing.qa.test';
INSERT INTO bill_master
(change_time, change_master, add_time, add_master, keyname, keypassword, keypassword_time, family, title, sap_emp_no, name, sex, birthday, tel, mobile, email, address, country, memo, `leave`, hide, role_id)
VALUES(UNIX_TIMESTAMP(), 1, UNIX_TIMESTAMP(), 1, 'billing.qa.test', '67727a41b5b1d4dfca981e4045b1bb2f1e7fef0e3e8825c028949d186cad4c00', UNIX_TIMESTAMP(), '', '', '', 'billing.qa.test', '1', '0000-00-00', '', '', '', '', '', '', 'n', 'n', '');

delete from bill_master where keyname='billing.qa.test.manager';
INSERT INTO bill_master
(change_time, change_master, add_time, add_master, keyname, keypassword, keypassword_time, family, title, sap_emp_no, name, sex, birthday, tel, mobile, email, address, country, memo, `leave`, hide, role_id)
VALUES(UNIX_TIMESTAMP(), 1, UNIX_TIMESTAMP(), 1, 'billing.qa.test.manager', '67727a41b5b1d4dfca981e4045b1bb2f1e7fef0e3e8825c028949d186cad4c00', UNIX_TIMESTAMP(), '', '', '', 'billing.qa.test.manager', '', '0000-00-00', '', '', '', '', '', '', 'n', 'n', '');

delete from bill_master where keyname='billing.rd.test';
INSERT INTO bill_master
(change_time, change_master, add_time, add_master, keyname, keypassword, keypassword_time, family, title, sap_emp_no, name, sex, birthday, tel, mobile, email, address, country, memo, `leave`, hide, role_id)
VALUES(UNIX_TIMESTAMP(), 1, UNIX_TIMESTAMP(), 1, 'billing.rd.test', '67727a41b5b1d4dfca981e4045b1bb2f1e7fef0e3e8825c028949d186cad4c00', UNIX_TIMESTAMP(), '', '', '', 'billing.rd.test', '1', '0000-00-00', '', '', '', '', '', '', 'n', 'n', '');


delete from bill_master where keyname='billing.rd.test.manager';
INSERT INTO bill_master
(change_time, change_master, add_time, add_master, keyname, keypassword, keypassword_time, family, title, sap_emp_no, name, sex, birthday, tel, mobile, email, address, country, memo, `leave`, hide, role_id)
VALUES(UNIX_TIMESTAMP(), 1, UNIX_TIMESTAMP(), 1, 'billing.rd.test.manager', '67727a41b5b1d4dfca981e4045b1bb2f1e7fef0e3e8825c028949d186cad4c00', UNIX_TIMESTAMP(), '', '', '', 'billing.rd.test.manager', '', '0000-00-00', '', '', '', '', '', '', 'n', 'n', '');


INSERT INTO bill_admin_power
(change_time, change_master, bill_master, bill_admin_name, `always`, sort, pageview)
select UNIX_TIMESTAMP(),1,(select id from bill_master bm 
where bm.keyname = 'billing.qa.test'),id,'y',0,10 
from bill_admin_name bwp ;


INSERT INTO bill_admin_power
(change_time, change_master, bill_master, bill_admin_name, `always`, sort, pageview)
select UNIX_TIMESTAMP(),1,(select id from bill_master bm 
where bm.keyname = 'billing.rd.test'),id,'y',0,10 
from bill_admin_name bwp ;


INSERT INTO bill_admin_power
(change_time, change_master, bill_master, bill_admin_name, `always`, sort, pageview)
select UNIX_TIMESTAMP(),1,(select id from bill_master bm 
where bm.keyname = 'billing.qa.test.manager'),id,'y',0,10 
from bill_admin_name bwp ;


INSERT INTO bill_admin_power
(change_time, change_master, bill_master, bill_admin_name, `always`, sort, pageview)
select UNIX_TIMESTAMP(),1,(select id from bill_master bm 
where bm.keyname = 'billing.rd.test.manager'),id,'y',0,10 
from bill_admin_name bwp ;


INSERT bill_master_customer (change_time, change_master, bill_master, bill_customer)
SELECT UNIX_TIMESTAMP(), 1, (select id from bill_master bm 
where bm.keyname = 'billing.qa.test'), id FROM bill_customer WHERE id NOT IN 
(SELECT bill_customer FROM bill_master_customer WHERE bill_master = (select id from bill_master bm 
where bm.keyname = 'billing.qa.test')) AND hide='n';


INSERT bill_master_customer (change_time, change_master, bill_master, bill_customer)
SELECT UNIX_TIMESTAMP(), 1, (select id from bill_master bm 
where bm.keyname = 'billing.rd.test'), id FROM bill_customer WHERE id NOT IN 
(SELECT bill_customer FROM bill_master_customer WHERE bill_master = (select id from bill_master bm 
where bm.keyname = 'billing.rd.test')) AND hide='n';


INSERT bill_master_customer (change_time, change_master, bill_master, bill_customer)
SELECT UNIX_TIMESTAMP(), 1, (select id from bill_master bm 
where bm.keyname = 'billing.qa.test.manager'), id FROM bill_customer WHERE id NOT IN 
(SELECT bill_customer FROM bill_master_customer WHERE bill_master = (select id from bill_master bm 
where bm.keyname = 'billing.qa.test.manager')) AND hide='n';


INSERT bill_master_customer (change_time, change_master, bill_master, bill_customer)
SELECT UNIX_TIMESTAMP(), 1, (select id from bill_master bm 
where bm.keyname = 'billing.rd.test.manager'), id FROM bill_customer WHERE id NOT IN 
(SELECT bill_customer FROM bill_master_customer WHERE bill_master = (select id from bill_master bm 
where bm.keyname = 'billing.rd.test.manager')) AND hide='n';

-- workflow
INSERT INTO workflow_permission (user_id,`group`) VALUES ((select id from bill_master bm where bm.keyname = 'billing.qa.test.manager'),'qa.test.manager');
INSERT INTO workflow_permission (user_id,`group`,approval_group) VALUES((select id from bill_master bm where bm.keyname = 'billing.qa.test'),'billing.qa.test','qa.test.manager');
INSERT INTO workflow_permission (user_id,`group`) VALUES ((select id from bill_master bm where bm.keyname = 'billing.rd.test.manager'),'rd.test.manager');
INSERT INTO workflow_permission (user_id,`group`,approval_group) VALUES((select id from bill_master bm where bm.keyname = 'billing.rd.test'),'billing.rd.test','rd.test.manager');

-- mail 
UPDATE bill_customer SET gui_email_invoice1='ecv.billing.rd@ecloudvalley.com', 
gui_email_invoice2='ecv.billing.rd@ecloudvalley.com', gui_email_invoice3='ecv.billing.rd@ecloudvalley.com', gui_memo='',
contact='', contact_email='ecv.billing.rd@ecloudvalley.com',
overdue_email='ecv.billing.rd@ecloudvalley.com', email='ecv.billing.rd@ecloudvalley.com';

update bill_master SET email='ecv.billing.rd@ecloudvalley.com',memo='';

update bill_code set code_name='' where id =133;

update parameter_details set item_value='Y' where item_type='IsForcedReopen';
update migration_bill_close set status='p' ;