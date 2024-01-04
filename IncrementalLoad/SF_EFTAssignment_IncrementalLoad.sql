/*
- NOTHING IS MISSING
*/

/*datetime start / python script for storing LastRunTime as @start?*/
DECLARE @start DATETIME = DATEADD(DAY, -1, GETDATE())

/*datetime end*/
DECLARE @end DATETIME = GETDATE()

MERGE INTO EFT_Assignment_ASPIRE__c_upsert AS Target
USING (SELECT
NULL AS ID,
Contract.ContractOid  AS ContractOID__c, 
OppIDTable.OppurtunityID AS Oppurtunity__c, 
ContractEFT.ContractEFTOid AS ContractEFTOid__c, 
STUFF(AchBankAccount.AccountNumber, 1, /*length*/CASE WHEN LEN(AchBankAccount.AccountNumber) < 4 THEN LEN(AchBankAccount.AccountNumber) ELSE LEN(AchBankAccount.AccountNumber) - 4 END, 
REPLICATE('x', CASE WHEN LEN(AchBankAccount.AccountNumber) < 4 THEN LEN(AchBankAccount.AccountNumber) ELSE LEN(AchBankAccount.AccountNumber) - 4 END)) AS Account_Number__c,
AchBank.BankName AS Bank_Name__c, 
ContractEFT.StartDate AS StartDate__c, 
ContractEFT.EndDate AS EndDate__c, 
ContractEFT.ResumeDate AS ResumeDate__c, 
ContractEFT.LastChangeDateTime AS Last_Change_Date_Time__c,
ContractEFT.LastChangeOperator AS Last_Change_Operator__c

FROM            AchBankAccount INNER JOIN
                         ContractEFT ON AchBankAccount.AchBankAccountOid = ContractEFT.ACHBankAccountOid INNER JOIN
                         AchBank ON AchBankAccount.AchBankOid = AchBank.AchBankOid LEFT OUTER JOIN
                         Contract ON ContractEFT.ContractOid = Contract.ContractOid LEFT OUTER JOIN
                                (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS OppurtunityID
                                  FROM GenericField GF 
                                  LEFT OUTER JOIN GenericValue GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                                  Contract c ON c.ContractOid = gv.ref_oid
                                  WHERE GF.oid = 23
                                  GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                                ) AS OppIDTable ON contract.ContractOid = OppIDTable.ref_oid
WHERE        (Contract.IsBooked = 1) AND (Contract.CompanyOid = 1) AND (ContractEFT.LastChangeDateTime BETWEEN @start AND @end)
ORDER BY Contract.ContractOid) AS Source
ON Target.ContractEFTOid__c = Source.ContractEFTOid__c -- Add any additional conditions for matching records

WHEN MATCHED THEN
    UPDATE SET
        Target.Oppurtunity__c = Source.Oppurtunity__c,
        Target.Account_Number__c = Source.Account_Number__c,
        Target.Bank_Name__c = Source.Bank_Name__c,
        Target.StartDate__c = Source.StartDate__c,
        Target.EndDate__c = Source.EndDate__c,
        Target.ResumeDate__c = Source.ResumeDate__c,
        Target.Last_Change_Date_Time__c = Source.Last_Change_Date_Time__c,
        Target.Last_Change_Operator__c = Source.Last_Change_Operator__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Oppurtunity__c,
        ContractEFTOid,
        Account_Number__c,
        Bank_Name__c,
        StartDate__c,
        EndDate__c,
        ResumeDate__c,
        Last_Change_Date_Time__c,
        Last_Change_Operator__c
    ) VALUES (
        Source.ID,
        Source.Oppurtunity__c,
        Source.ContractEFTOid,
        Source.Account_Number__c,
        Source.Bank_Name__c,
        Source.StartDate__c,
        Source.EndDate__c,
        Source.ResumeDate__c,
        Source.Last_Change_Date_Time__c,
        Source.Last_Change_Operator__c
    );