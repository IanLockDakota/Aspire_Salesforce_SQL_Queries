EXEC dbo.SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','Accounting_ASPIRE__c_upsert','ContractOID__c';

EXEC dbo.SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','EFT_AltSchedule_ASPIRE__c_upsert','EFTScheduleOID__c';

EXEC dbo.SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','EFT_Assignment_ASPIRE__c_upsert','ContractEFTOID__c';

EXEC dbo.SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','Equipment_ASPIRE__c_upsert','EquipmentOID__c';

EXEC dbo.SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','Invoice_ASPIRE__c_upsert','InvoiceDetailOID__c';

EXEC SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','Notes_ASPIRE__c_upsert','CommentOID__c';

EXEC SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','Payment_ASPIRE__c_upsert','CashReceiptDetailOID__C';

EXEC dbo.SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','Scheduled_Billables_ASPIRE__c_upsert','ScheduleDefinitionOID__c';

EXEC dbo.SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','Total_Payments_ASPIRE__c_upsert','ContractOID__c';

EXEC SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','Customer_And_Related_Collections__c_upsert','PhoneOID__c';

EXEC SF_TableLoader 'UPSERT:bulkapi2','SALESFORCE3','Amort_ASPIRE__c_upsert','LineItemOID__c';