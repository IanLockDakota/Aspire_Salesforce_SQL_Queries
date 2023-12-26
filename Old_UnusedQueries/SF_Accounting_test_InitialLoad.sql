/*
Name: Accounting

ASPIRE SQLS Table Dependencies:
    - GeneralLedger
    - GeneralLedgerAccountID
    - AchBank
    - Contract
    - EFTBank
    - GenericField
    - cdataGenericValue

Salesforce Backups Table Dependencies:
    - Accounting_ASPIRE__c_upsert

SF Object Dependencies:
    - Accounting_ASPIRE__c

Last change: 11/30/2023

Other Notes:
    - Does not use parameters to set date frame for data being pulled
*/

/* Pulling all accounting data per contract */

WITH CurrentDaySnapshot AS (
    SELECT GLAD.ContractOid, 
        SUM(CASE WHEN (GL.AccountId = '01-10089') AND (GL.ProcessOid IN (20119, 20126, 20127, 20140, 20141, 20143)) THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) END) AS [Gross Receivable], 
        SUM(CASE WHEN (GL.AccountId IN ('01-10089', '01-10090')) THEN ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0) END) AS [Balance Remaining], 
        SUM(CASE WHEN (GL.AccountId = '01-10092') THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) * - 1 END) AS [Unearned Finance], 
        SUM(CASE WHEN (GL.AccountId = '01-10091') THEN ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0) END) AS Residual, 
        SUM(CASE WHEN (GL.AccountId = '01-10093') THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) * - 1 END) AS [Deferred Residual], 
        SUM(CASE WHEN (GL.AccountId = '01-10094') THEN ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0) END) AS [Deferred Expense], 
        SUM(CASE WHEN (GL.AccountId = '01-10130') THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) * - 1 END) AS [Security Deposit]
        FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GeneralLedger] GL INNER JOIN
            [ASPIRESQL].[AspireDakotaTest].[dbo].[GeneralLedgerAccountID] GLAD ON GL.GeneralLedgerAccountIdOid = GLAD.GeneralLedgerAccountIdOid
            WHERE        (GL.PostDate <= GETDATE())
            GROUP BY GLAD.ContractOid
),

/* Pulling in snapshot of accounting data, currently in SF*/ 

PreviousDaySnapshot AS (
    SELECT ISNULL(ContractOid__c,0) AS ContractOID, 
    SUM(ISNULL(Gross_Receivable__C,0)) AS [Gross Receivable],
    SUM(ISNULL(Balance_Remaining__C,0)) AS [Balance Remaining], 
    SUM(ISNULL(Unearned_Finance__C,0)) AS [Unearned Finance], 
    SUM(ISNULL(Residual__C,0)) AS Residual, 
    SUM(ISNULL(Deferred_Residual__C,0)) AS [Deferred Residual], 
    SUM(ISNULL(Deferred_Expense__C,0)) AS [Deferred Expense], 
    SUM(ISNULL(Security_Deposit__C,0)) AS [Security Deposit]
        FROM [SALESFORCE3].[cdata].[SALESFORCE].[Accounting_ASPIRE__c]
            GROUP BY ContractOid__c
),

/* Pulling Oppurtunity ID */

OppIDTable AS (
    SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
    FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GenericField] GF 
    LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
    [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
    WHERE GF.oid = 23
    GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
), 

/* Subquery determines if data has changed between the two datasets above. Upsert will only update where the ChangeStatus field has 'Data Changed' listed */

Subquery AS (
    SELECT        
        C.ContractOid,
        OppIDTable.opportunityID As opportunityID,
        CASE
            WHEN CurrentDay.[Gross Receivable] <> PreviousDay.[Gross Receivable]
                 OR (CurrentDay.[Gross Receivable] - CurrentDay.[Balance Remaining]) <> (PreviousDay.[Gross Receivable] - PreviousDay.[Balance Remaining])
                 OR CurrentDay.[Balance Remaining] <> PreviousDay.[Balance Remaining]
                 OR CurrentDay.[Unearned Finance] <> PreviousDay.[Unearned Finance]
                 OR CurrentDay.Residual <> PreviousDay.Residual
                 OR CurrentDay.[Deferred Residual] <> PreviousDay.[Deferred Residual]
                 OR CurrentDay.[Deferred Expense] <> PreviousDay.[Deferred Expense]
                 OR CurrentDay.[Security Deposit] <> PreviousDay.[Security Deposit]
            THEN 'Data Changed'
            ELSE 'No Changes'
        END AS ChangeStatus,
        CurrentDay.[Gross Receivable] AS CurrentDay_GrossReceivable,
        CurrentDay.[Gross Receivable] - CurrentDay.[Balance Remaining] AS CurrentDay_PaymentsMade,
        CurrentDay.[Balance Remaining] AS CurrentDay_BalanceRemaining,
        CurrentDay.[Unearned Finance] AS CurrentDay_UnearnedFinance,
        CurrentDay.Residual AS CurrentDay_Residual,
        CurrentDay.[Deferred Residual] AS CurrentDay_DeferredResidual,
        CurrentDay.[Deferred Expense] AS CurrentDay_DeferredExpense,
        CurrentDay.[Security Deposit] AS CurrentDay_SecurityDeposit
    FROM 
        [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] C
    LEFT OUTER JOIN
        CurrentDaySnapshot AS CurrentDay ON c.ContractOid = CurrentDay.ContractOid
    LEFT OUTER JOIN
        PreviousDaySnapshot AS PreviousDay ON c.ContractOid = PreviousDay.ContractOid
    LEFT OUTER JOIN
        OppIDTable AS OppIDTable ON C.ContractOid = OppIDTable.ref_oid
    WHERE
        (C.IsBooked = 1) AND (C.CompanyOid = 1)
) 

---MERGE FUNCTION
MERGE INTO Accounting_ASPIRE__c_upsert AS Target
USING (
    SELECT 
NULL AS ID, 
sbq.contractOID AS ContractOid__c, 
sbq.opportunityID AS Opportunity__c, 
sbq.CurrentDay_GrossReceivable AS Gross_Receivable__c,
sbq.CurrentDay_PaymentsMade AS Payments_Made__c, 
sbq.CurrentDay_BalanceRemaining AS Balance_Remaining__c, 
sbq.CurrentDay_UnearnedFinance AS Unearned_Finance__c, 
ISNULL(sbq.CurrentDay_Residual,0) AS Residual__c, 
ISNULL(sbq.CurrentDay_DeferredResidual,0) AS Deferred_Residual__c, 
sbq.CurrentDay_DeferredExpense AS Deferred_Expense__c, 
ISNULL(sbq.CurrentDay_SecurityDeposit,0) AS Security_Deposit__c
FROM Subquery sbq) AS Source
ON Target.Opportunity__c = Source.Opportunity__c
/* Upsert Capabilities */

WHEN MATCHED THEN
    UPDATE SET
        Target.Gross_Receivable__c = Source.Gross_Receivable__c,
        Target.Payments_Made__c = Source.Payments_Made__c,
        Target.Balance_Remaining__c = Source.Balance_Remaining__c,
        Target.Unearned_Finance__c = Source.Unearned_Finance__c,
        Target.Residual__c = ISNULL(Source.Residual__c, 0),
        Target.Deferred_Residual__c = ISNULL(Source.Deferred_Residual__c, 0),
        Target.Deferred_Expense__c = Source.Deferred_Expense__c,
        Target.Security_Deposit__c = ISNULL(Source.Security_Deposit__c, 0)

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        Gross_Receivable__c,
        Payments_Made__c,
        Balance_Remaining__c,
        Unearned_Finance__c,
        Residual__c,
        Deferred_Residual__c,
        Deferred_Expense__c,
        Security_Deposit__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.Gross_Receivable__c,
        Source.Payments_Made__c,
        Source.Balance_Remaining__c,
        Source.Unearned_Finance__c,
        ISNULL(Source.Residual__c, 0),
        ISNULL(Source.Deferred_Residual__c, 0),
        Source.Deferred_Expense__c,
        ISNULL(Source.Security_Deposit__c, 0)
    );


