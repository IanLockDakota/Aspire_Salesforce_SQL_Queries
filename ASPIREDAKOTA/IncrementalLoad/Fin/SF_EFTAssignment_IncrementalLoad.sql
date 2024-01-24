/*
- NOTHING IS MISSING
*/

/*datetime start / python script for storing LastRunTime as @start?*/
DECLARE @start DATETIME = DATEADD(DAY, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

MERGE INTO EFT_Assignment_ASPIRE__c_upsert AS Target
USING (SELECT
NULL AS ID,
Contract.ContractOid  AS ContractOID__c, 
OppIDTable.OppurtunityID AS Opportunity__c, 
ContractEFT.ContractEFTOid AS ContractEFTOid__c, 
STUFF(AchBankAccount.AccountNumber, 1, /*length*/CASE WHEN LEN(AchBankAccount.AccountNumber) < 4 THEN LEN(AchBankAccount.AccountNumber) ELSE LEN(AchBankAccount.AccountNumber) - 4 END, 
REPLICATE('x', CASE WHEN LEN(AchBankAccount.AccountNumber) < 4 THEN LEN(AchBankAccount.AccountNumber) ELSE LEN(AchBankAccount.AccountNumber) - 4 END)) AS AccountNumber__c,
AchBank.BankName AS BankName__c, 
ContractEFT.StartDate AS StartDate__c, 
ContractEFT.EndDate AS EndDate__c, 
ContractEFT.ResumeDate AS ResumeDate__c, 
ContractEFT.LastChangeDateTime AS LastChangeDateTime__c,
ContractEFT.LastChangeOperator AS LastChangeOperator__c

FROM            [ASPIRESQL].[AspireDakota].[dbo].[AchBankAccount] INNER JOIN
                         [ASPIRESQL].[AspireDakota].[dbo].[ContractEFT] ON AchBankAccount.AchBankAccountOid = ContractEFT.ACHBankAccountOid INNER JOIN
                         [ASPIRESQL].[AspireDakota].[dbo].[AchBank] ON AchBankAccount.AchBankOid = AchBank.AchBankOid LEFT OUTER JOIN
                         [ASPIRESQL].[AspireDakota].[dbo].[Contract] ON ContractEFT.ContractOid = Contract.ContractOid LEFT OUTER JOIN
                                (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS OppurtunityID
                                  FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
                                  LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                                  [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
                                  WHERE GF.oid = 23
                                  GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                                ) AS OppIDTable ON contract.ContractOid = OppIDTable.ref_oid
WHERE        (Contract.IsBooked = 1) AND (Contract.CompanyOid = 1) AND (ContractEFT.LastChangeDateTime BETWEEN @start AND @end)) AS Source
ON Target.ContractEFTOid__c = Source.ContractEFTOid__c -- Add any additional conditions for matching records

WHEN MATCHED THEN
    UPDATE SET
        Target.Opportunity__c = Source.Opportunity__c,
        Target.AccountNumber__c = Source.AccountNumber__c,
        Target.BankName__c = Source.BankName__c,
        Target.StartDate__c = Source.StartDate__c,
        Target.EndDate__c = Source.EndDate__c,
        Target.ResumeDate__c = Source.ResumeDate__c,
        Target.LastChangeDateTime__c = Source.LastChangeDateTime__c,
        Target.LastChangeOperator__c = Source.LastChangeOperator__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        ContractEFTOid__c,
        AccountNumber__c,
        BankName__c,
        StartDate__c,
        EndDate__c,
        ResumeDate__c,
        LastChangeDateTime__c,
        LastChangeOperator__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.ContractEFTOid__c,
        Source.AccountNumber__c,
        Source.BankName__c,
        Source.StartDate__c,
        Source.EndDate__c,
        Source.ResumeDate__c,
        Source.LastChangeDateTime__c,
        Source.LastChangeOperator__c
    );