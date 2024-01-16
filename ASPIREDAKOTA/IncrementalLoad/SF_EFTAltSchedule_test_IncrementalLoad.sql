/*
Name: EFTAltSchedule

ASPIRE SQLS Table Dependencies:
    - AchBankAccount
    - EftSchedule
    - AchBank
    - Contract
    - EFTBank
    - GenericField
    - cdataGenericValue

Salesforce Backups Table Dependencies:
    - EFT_AltSchedule_ASPIRE__c_upsert

SF Object Dependencies:
    - EFT_AltSchedule_ASPIRE__c

Last change: 11/30/2023

Other Notes:
    - START and END parameters to set timeframe of data to be pulled 
    - MISSING PaymentsProcessed, EFTScheduleOID, OriginatingBank, LastChangeDateTime, LastchangeOperator WITHIN SALESFORCE
*/


-- DATETIME VARIABLES
DECLARE @start DATETIME = DATEADD(HOUR, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

---- MERGE
MERGE INTO EFT_AltSchedule_ASPIRE__c_upsert AS Target
USING (SELECT
NULL AS ID,     
C.ContractOid AS ContractOID__c,
OppIDtable.opportunityID AS opportunity__c,
EFTS.EftScheduleOid  AS EftScheduleOid__c, 
EFTS.StartDate AS StartDate__c,
EFTS.Frequency AS Frequency__c,
EFTS.Amount AS Amount__c,
EFTS.TotalPayments AS TotalPayments__c,
EFTS.PaymentsProcessed AS PaymentsProcessed__c, /* MISSING */
STUFF(ABA.AccountNumber, 1, CASE WHEN LEN(ABA.AccountNumber) < 4 THEN LEN(ABA.AccountNumber) ELSE LEN(ABA.AccountNumber) - 4 END, REPLICATE('x', CASE WHEN LEN(ABA.AccountNumber) 
                         < 4 THEN LEN(ABA.AccountNumber) ELSE LEN(ABA.AccountNumber) - 4 END)) AS AccountNumber__c,
                         AB.BankName AS BankName__c,
                         EFTB.description AS OriginatingBank__c, /* MISSING */
						 EFTS.LastChangeDateTime AS LastChangeDateTime__c, /* MISSING */
                         EFTS.LastChangeOperator AS LastChangeOperator__c /* MISSING */

FROM            [ASPIRESQL].[AspireDakota].[dbo].[AchBankAccount] ABA INNER JOIN
                         [ASPIRESQL].[AspireDakota].[dbo].[EftSchedule] EFTS ON ABA.AchBankAccountOid = EFTS.ReceivingBankAccountOid INNER JOIN
                         [ASPIRESQL].[AspireDakota].[dbo].[AchBank] AB ON ABA.AchBankOid = AB.AchBankOid RIGHT OUTER JOIN
                         [ASPIRESQL].[AspireDakota].[dbo].[Contract] C ON EFTS.ContractOid = C.ContractOid LEFT OUTER JOIN
						 [ASPIRESQL].[AspireDakota].[dbo].[EFTBank] EFTB ON EFTS.OriginatingBankOid = EFTB.EFTBankOID LEFT OUTER JOIN
                                
                                /* Pulling Oppurtunity ID */

                                (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
                                  FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
                                  LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                                  [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
                                  WHERE GF.oid = 23
                                  GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                                ) AS OppIDTable ON c.ContractOid = OppIDTable.ref_oid

/*below is where datetime comparison is done*/
WHERE (C.CompanyOID = 1) AND (C.IsBooked = 1) AND (NOT (EFTS.EftScheduleOid IS NULL)) AND (NOT EFTB.description LIKE '%ATA%') AND (EFTS.LastChangeDateTime BETWEEN @start AND @end)) AS Source
ON Target.EftScheduleOid__c = Source.EftScheduleOid__c

/*Upsert capabilities*/

WHEN MATCHED THEN
    UPDATE SET
        Target.StartDate__c = Source.StartDate__c,
        Target.Frequency__c = Source.Frequency__c,
        Target.Amount__c = Source.Amount__c,
        Target.TotalPayments__c = Source.TotalPayments__c,
        Target.PaymentsProcessed__c = Source.PaymentsProcessed__c,
        Target.AccountNumber__c = Source.AccountNumber__c,
        Target.BankName__c = Source.BankName__c,
        Target.OriginatingBank__c = Source.OriginatingBank__c,
        Target.LastChangeDateTime__c = Source.LastChangeDateTime__c,
        Target.LastChangeOperator__c = Source.LastChangeOperator__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        EftScheduleOid__c,
        StartDate__c,
        Frequency__c,
        Amount__c,
        TotalPayments__c,
        PaymentsProcessed__c,
        AccountNumber__c,
        BankName__c,
        OriginatingBank__c,
        LastChangeDateTime__c,
        LastChangeOperator__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.EftScheduleOid__c,
        Source.StartDate__c,
        Source.Frequency__c,
        Source.Amount__c,
        Source.TotalPayments__c,
        Source.PaymentsProcessed__c,
        Source.AccountNumber__c,
        Source.BankName__c,
        Source.OriginatingBank__c,
        Source.LastChangeDateTime__c,
        Source.LastChangeOperator__c
    );