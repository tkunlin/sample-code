UPDATE bill_master  SET tel = CONCAT(lEFT(tel, 2),'OOOO' , RIGHT(tel, 2)),
                               mobile = CONCAT(lEFT(mobile, 2),'OOOO' , RIGHT(mobile, 2)),
                               email = CONCAT(lEFT(email, 2),'OOOO' , RIGHT(email, 2));

UPDATE bill_customer SET contact = CONCAT(lEFT(contact, 1),'O' , RIGHT(contact, 1)),
                                contact_email = 'billing.rd@ecloudvalley.com',
                                overdue_email = 'billing.rd@ecloudvalley.com',
                                tel = CONCAT(lEFT(tel, 2),'OOOO' , RIGHT(tel, 2)),
                                mobile = CONCAT(lEFT(mobile, 2),'OOOO' , RIGHT(mobile, 2)),
                                email = 'billing.rd@ecloudvalley.com',
                                gui_contact = CONCAT(lEFT(gui_contact, 2),'OOOO' , RIGHT(gui_contact, 2)),
                                gui_tel = CONCAT(lEFT(gui_tel, 2),'OOOO' , RIGHT(gui_tel, 2)),
                                gui_email_invoice1 = 'picard@startrek.enterprise',
                                gui_email_invoice2= 'picard@startrek.enterprise',
                                gui_email_invoice3 = 'picard@startrek.enterprise',
                                gui_email_einv = 'picard@startrek.enterprise',
                                gui_address = CONCAT(lEFT(gui_address, 2),'OOOO' , RIGHT(gui_address, 2)),
                                TaxationAddress = CONCAT(lEFT(TaxationAddress, 2),'OOOO' , RIGHT(TaxationAddress, 2)),
                                cname = CONCAT(lEFT(cname, 1),'OO' , RIGHT(cname, 1)),
                                bank_account_no = CONCAT(lEFT(bank_account_no, 2),'OOOO' , RIGHT(bank_account_no, 2)),
                                bank_account_name = CONCAT(lEFT(bank_account_name, 2),'OOOO' , RIGHT(bank_account_name, 2));