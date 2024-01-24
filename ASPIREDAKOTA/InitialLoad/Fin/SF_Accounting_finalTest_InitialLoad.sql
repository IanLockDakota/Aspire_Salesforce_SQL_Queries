/*
Name: Accounting

ASPIRE SQLS Table Dependencies:
    - Contract
    - GeneralLedger
    - GeneralLedgerAccountId
    - GenericField
    - cdataGenericValue
    - InvoiceDetail
    - InvoicePaymentHistory
    - AchBank
    - EFTBank


Salesforce Backups Table Dependencies:
    - Accounting_ASPIRE__c_upsert

SF Object Dependencies:
    - Accounting_ASPIRE__c

Last change: 12/18/2023

Other Notes:
    - Does not use parameters to set date frame for data being pulled
    - Comebine all accounting snapshot w/ DPD, NI, and atTerm info
*/

/* Pulling all accounting data per contract */
WITH CurrentDaySnapshot AS (
    SELECT GLAD.ContractOid, 
        SUM(CASE WHEN (GL.AccountId = '01-10089') AND (GL.ProcessOid IN (20119, 20126, 20127, 20140, 20141, 20143)) THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) END) AS [Gross Receivable],
        ISNULL(SUM(CASE WHEN GL.AccountId = '01-10089' AND GL.ProcessOid IN (20119, 20126, 20127, 20140) THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) END),0) AS [Original Gross Receivable], 
        SUM(CASE WHEN (GL.AccountId IN ('01-10089', '01-10090')) THEN ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0) END) AS [Balance Remaining], 
        SUM(CASE WHEN (GL.AccountId = '01-10092') THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) * - 1 END) AS [Unearned Finance], 
        SUM(CASE WHEN (GL.AccountId = '01-10091') THEN ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0) END) AS Residual, 
        SUM(CASE WHEN (GL.AccountId = '01-10093') THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) * - 1 END) AS [Deferred Residual], 
        SUM(CASE WHEN (GL.AccountId = '01-10094') THEN ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0) END) AS [Deferred Expense], 
        SUM(CASE WHEN (GL.AccountId = '01-10130') THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) * - 1 END) AS [Security Deposit]
        FROM [ASPIRESQL].[AspireDakota].[dbo].[GeneralLedger] GL INNER JOIN
            [ASPIRESQL].[AspireDakota].[dbo].[GeneralLedgerAccountID] GLAD ON GL.GeneralLedgerAccountIdOid = GLAD.GeneralLedgerAccountIdOid
            WHERE        (GL.PostDate <= GETDATE())
            GROUP BY GLAD.ContractOid
),

/* Pulling in snapshot of accounting data, currently in SF*/ 
PreviousDaySnapshot AS (
SELECT
		Opportunity__c, 
		ContractOid__c,
        Original_Gross_Receivable__c, 
		Gross_Receivable__c, 
		Payments_Made__c, 
		Balance_Remaining__c, 
		Unearned_Finance__c, 
		Residual__c, 
		Deferred_Residual__c, 
		Deferred_Expense__c, 
		Security_Deposit__c
    FROM 
		[SALESFORCE3].[cdata].[SALESFORCE].[Accounting_ASPIRE__c]
),

/* Pulling Oppurtunity ID */
OppIDTable AS (
    SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
    FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
    LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
    [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
    WHERE GF.oid = 23
    GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
),

/* NetInvestment */
NetInvest AS (SELECT GLA.ContractOid,
            SUM(CASE
                    WHEN GL.AccountId = '01-10089' AND GL.ProcessOid IN (20119, 20126, 20127, 20140, 20141, 20143)
                    THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0))
                END) AS [Gross Receivable],
            SUM(CASE
                    WHEN GL.AccountId IN ('01-10089', '01-10090')
                    THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0))
                END) AS [Balance Remaining],
            SUM(CASE
                    WHEN GL.AccountId = '01-10092'
                    THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) * -1
                END) AS [Unearned Finance],
            SUM(CASE
                    WHEN GL.AccountId = '01-10091'
                    THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0))
                END) AS Residual,
            SUM(CASE
                    WHEN GL.AccountId = '01-10093'
                    THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) * -1
                END) AS [Deferred Residual],
            SUM(CASE
                    WHEN GL.AccountId = '01-10094'
                    THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0))
                END) AS [Deferred Expense],
            SUM(CASE
                    WHEN GL.AccountId = '01-10130'
                    THEN (ISNULL(GL.Debit, 0) + ISNULL(GL.Credit, 0)) * -1
                END) AS [Security Deposit]
        FROM [ASPIRESQL].[AspireDakota].[dbo].[GeneralLedger] GL
                INNER JOIN [ASPIRESQL].[AspireDakota].[dbo].[GeneralLedgerAccountId] GLA
                            ON GL.GeneralLedgerAccountIdOid = GLA.GeneralLedgerAccountIdOid INNER JOIN
                                [ASPIRESQL].[AspireDakota].[dbo].[Contract] C on GLA.ContractOid = c.ContractOid
        WHERE (GL.PostDate <= GETDATE()) AND (c.IsTerminated = 0)
        GROUP BY GLA.ContractOid),

/* NetInvestment at termination */
NetInvestTerm AS (SELECT
	c2.ContractOid,
    ISNULL(MyTable7.[Gross Receivable] + MyTable2.[Balance Remaining],0) AS [Payments Made at Term],
    ISNULL(MyTable2.[Balance Remaining],0) AS [Balance Remaining at Term],
	((ISNULL(Mytable2.[Balance Remaining],0)
    - ISNULL(Mytable2.[Unearned Finance], 0)
    + ISNULL(Mytable2.Residual, 0)
    - ISNULL(Mytable2.[Deferred Residual], 0)
    + ISNULL(Mytable2.[Deferred Expense], 0)
    - ISNULL(Mytable2.[Security Deposit], 0)) * -1) AS [Net Investment]
FROM
	[ASPIRESQL].[AspireDakota].[dbo].[contract] c2 LEFT OUTER JOIN
(SELECT
		C1.contractOID,
		ISNULL(SUM(CASE WHEN (MyTable.AccountId IN ('01-10089', '01-10090')) THEN ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0) END),0) AS [Balance Remaining], 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10092') THEN (ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0)) END),0) * -1 AS [Unearned Finance], 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10091') THEN ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0) END),0) AS Residual, 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10093') THEN (ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0)) END),0) * -1 AS [Deferred Residual], 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10094') THEN ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0) END),0) AS [Deferred Expense], 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10130') THEN (ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0)) END),0) * -1 AS [Security Deposit]
	FROM
	[ASPIRESQL].[AspireDakota].[dbo].[CONTRACT] C1 LEFT OUTER JOIN
	(SELECT GLAD2.ContractOid, GL3.GeneralLedgerOid, GL3.CreatedDateTime, GL3.ProcessOid, GL3.BatchIdentifier, GL3.HeaderIdentifier, GL3.PostDate, GL3.AccountId, GL3.AccountTypeOid, GL3.EffectiveDate, GL3.JournalNumber, GL3.Credit, GL3.Debit
	FROM [ASPIRESQL].[AspireDakota].[dbo].[GeneralLedger] GL3 LEFT OUTER JOIN
	[ASPIRESQL].[AspireDakota].[dbo].[GeneralLedgerAccountID] GLAD2 ON GL3.GeneralLedgerAccountIdOid = GLAD2.GeneralLedgerAccountIdOid
	WHERE ProcessOid = 20143) as MyTable ON c1.contractOID = myTable.ContractOid
	WHERE (C1.IsBooked = 1) AND (C1.CompanyOid = 1) AND (C1.IsTerminated = 1)
	GROUP BY C1.ContractOid) as Mytable2 ON c2.contractOID = mytable2.contractOID LEFT OUTER JOIN
(SELECT
		C5.contractOID,
        ISNULL(SUM(CASE WHEN MyTable6.AccountId = '01-10089' AND MyTable6.ProcessOid IN (20119, 20126, 20127, 20140, 20141) THEN (ISNULL(MyTable6.Debit, 0) + ISNULL(MyTable6.Credit, 0)) END),0) AS [Gross Receivable]
	FROM
	[ASPIRESQL].[AspireDakota].[dbo].[CONTRACT] C5 LEFT OUTER JOIN
	(SELECT GLAD2.ContractOid, GL3.GeneralLedgerOid, GL3.CreatedDateTime, GL3.ProcessOid, GL3.BatchIdentifier, GL3.HeaderIdentifier, GL3.PostDate, GL3.AccountId, GL3.AccountTypeOid, GL3.EffectiveDate, GL3.JournalNumber, GL3.Credit, GL3.Debit
	FROM [ASPIRESQL].[AspireDakota].[dbo].[GeneralLedger] GL3 LEFT OUTER JOIN
	[ASPIRESQL].[AspireDakota].[dbo].[GeneralLedgerAccountID] GLAD2 ON GL3.GeneralLedgerAccountIdOid = GLAD2.GeneralLedgerAccountIdOid) as MyTable6 ON c5.contractOID = myTable6.ContractOid
	WHERE (C5.IsBooked = 1) AND (C5.CompanyOid = 1) AND (C5.IsTerminated = 1)
	GROUP BY C5.ContractOid) as Mytable7 ON c2.contractOID = mytable7.contractOID
	WHERE (c2.IsBooked = 1) AND (c2.CompanyOid = 1) AND (c2.IsTerminated = 1)),

/* Days past due */
DPD AS (SELECT        
            OldRentDueDtTERM.ContractOid, 
            ISNULL(
                CASE WHEN DATEDIFF(DAY, OldRentDueDtTERM.OldestRentDue, GETDATE()) < 0 
                     THEN 0 
                     ELSE DATEDIFF(DAY, OldRentDueDtTERM.OldestRentDue, GETDATE()) 
                END, 0
            ) AS DPD
        FROM            
            ( SELECT        
                    contr.ContractOid, 
                    MIN(DueDate) AS OldestRentDue
                FROM [ASPIRESQL].[AspireDakota].[dbo].[Contract] contr LEFT OUTER JOIN
                    (
                        SELECT        
                            InvAmountDuebyInvoice_1.ContractOid, 
                            InvAmountDuebyInvoice_1.InvAmountDue, 
                            ISNULL(InvPaymentSummbyInvoice_1.PaymentAmount, 0) AS PaymentAmount, 
                            InvAmountDuebyInvoice_1.InvAmountDue - ISNULL(InvPaymentSummbyInvoice_1.PaymentAmount, 0) AS RemainingDue, 
                            InvAmountDuebyInvoice_1.DueDate
                        FROM
                            (
                                SELECT        
                                    ContractOid, 
                                    SUM(OriginalDueAmount) AS InvAmountDue, 
                                    DueDate, 
                                    InvoiceHeaderOid
                                FROM            
                                    [ASPIRESQL].[AspireDakota].[dbo].[InvoiceDetail] AS InvoiceDetail_1
                                WHERE        
                                    (DueDate <= GETDATE()) 
                                    AND (TransactionCodeOid IN (1, 35, 25, 37, 43)) 
                                    AND (NOT (OpenClosedOid IN (11022, 11023)))
                                GROUP BY 
                                    ContractOid, InvoiceHeaderOid, DueDate
                            ) AS InvAmountDuebyInvoice_1 
                            LEFT OUTER JOIN
                            (
                                SELECT        
                                    InvoiceDetail_5.ContractOid, 
                                    SUM(InvoicePaymentHistory_1.AppliedAmount) AS PaymentAmount, 
                                    InvoiceDetail_5.InvoiceHeaderOid
                                FROM            
                                    [ASPIRESQL].[AspireDakota].[dbo].[InvoicePaymentHistory] AS InvoicePaymentHistory_1 
                                RIGHT OUTER JOIN
                                    [ASPIRESQL].[AspireDakota].[dbo].[InvoiceDetail] AS InvoiceDetail_5 
                                    ON InvoicePaymentHistory_1.InvoiceDetailOid = InvoiceDetail_5.InvoiceDetailOid
                                WHERE        
                                    (InvoicePaymentHistory_1.AppliedDate <= GETDATE()) 
                                    AND (InvoiceDetail_5.TransactionCodeOid IN (1, 35, 25, 37, 43)) 
                                    AND (InvoiceDetail_5.DueDate <= GETDATE()) 
                                    AND (NOT (InvoiceDetail_5.OpenClosedOid IN (11022, 11023)))
                                GROUP BY 
                                    InvoiceDetail_5.ContractOid, InvoiceDetail_5.InvoiceHeaderOid
                            ) AS InvPaymentSummbyInvoice_1 
                            ON InvAmountDuebyInvoice_1.ContractOid = InvPaymentSummbyInvoice_1.ContractOid 
                            AND InvAmountDuebyInvoice_1.InvoiceHeaderOid = InvPaymentSummbyInvoice_1.InvoiceHeaderOid
                        ) AS RentPmntbyInvocie_1 ON contr.contractOID = RentPmntbyInvocie_1.ContractOid
                        WHERE        
                            (RemainingDue > 0) AND (contr.IsTerminated = 0)
                        GROUP BY 
                            contr.ContractOid) AS OldRentDueDtTERM INNER JOIN
                    [ASPIRESQL].[AspireDakota].[dbo].[Contract] C ON c.contractOID = OldRentDueDtTERM.ContractOid),

/* Days past due at term */
DPDTerm AS (SELECT        
            OldRentDueDtTERM.ContractOid, 
            ISNULL(
                CASE WHEN DATEDIFF(DAY, OldRentDueDtTERM.OldestRentDue, c.TerminationDate) < 0 
                     THEN 0 
                     ELSE DATEDIFF(DAY, OldRentDueDtTERM.OldestRentDue, c.TerminationDate) 
                END, 0
            ) AS DPD
        FROM            
            ( SELECT        
                    con.ContractOid, 
                    MIN(DueDate) AS OldestRentDue
                FROM [ASPIRESQL].[AspireDakota].[dbo].[Contract] con LEFT OUTER JOIN
                    (
                        SELECT        
                            InvAmountDuebyInvoice_1.ContractOid, 
                            InvAmountDuebyInvoice_1.InvAmountDue,
                            ISNULL(InvPaymentSummbyInvoice_1.PaymentAmount, 0) AS PaymentAmount, 
                            InvAmountDuebyInvoice_1.InvAmountDue - ISNULL(InvPaymentSummbyInvoice_1.PaymentAmount, 0) AS RemainingDue, 
                            InvAmountDuebyInvoice_1.DueDate
                        FROM
                        (SELECT        
                            InvoiceDetail_1.ContractOid, 
                            SUM(InvoiceDetail_1.OriginalDueAmount) AS InvAmountDue, 
                            InvoiceDetail_1.DueDate, 
                            InvoiceDetail_1.InvoiceHeaderOid
                            FROM            
                                [ASPIRESQL].[AspireDakota].[dbo].[InvoiceDetail] AS InvoiceDetail_1 INNER JOIN
                                [ASPIRESQL].[AspireDakota].[dbo].[Contract] C on InvoiceDetail_1.ContractOID = c.ContractOID
                            WHERE        
                                (InvoiceDetail_1.DueDate <= GETDATE()) 
                                AND (InvoiceDetail_1.TransactionCodeOid IN (1, 35, 25, 37, 43)) 
                                AND (InvoiceDetail_1.OpenClosedOid NOT IN ('11020', '11021', '11024', '11025'))
                                AND (c.isTerminated = 1)
                            GROUP BY 
                                InvoiceDetail_1.ContractOid, InvoiceDetail_1.InvoiceHeaderOid, InvoiceDetail_1.DueDate) AS InvAmountDuebyInvoice_1 LEFT OUTER JOIN
                            (SELECT        
                                InvoiceDetail_5.ContractOid, 
                                SUM(InvoicePaymentHistory_1.AppliedAmount) AS PaymentAmount, 
                                InvoiceDetail_5.InvoiceHeaderOid
                                FROM            
                                    [ASPIRESQL].[AspireDakota].[dbo].[InvoicePaymentHistory] AS InvoicePaymentHistory_1 RIGHT OUTER JOIN
                                    [ASPIRESQL].[AspireDakota].[dbo].[InvoiceDetail] AS InvoiceDetail_5 ON InvoicePaymentHistory_1.InvoiceDetailOid = InvoiceDetail_5.InvoiceDetailOid
                                WHERE        
                                    (InvoicePaymentHistory_1.AppliedDate <= GETDATE()) 
                                    AND (InvoiceDetail_5.TransactionCodeOid IN (1, 35, 25, 37, 43)) 
                                    AND (InvoiceDetail_5.DueDate <= GETDATE())
                                    AND (NOT (InvoiceDetail_5.OpenClosedOid IN (11022, 11023)))
                                GROUP BY 
                                    InvoiceDetail_5.ContractOid, InvoiceDetail_5.InvoiceHeaderOid) AS InvPaymentSummbyInvoice_1 ON InvAmountDuebyInvoice_1.ContractOid = InvPaymentSummbyInvoice_1.ContractOid AND InvAmountDuebyInvoice_1.InvoiceHeaderOid = InvPaymentSummbyInvoice_1.InvoiceHeaderOid
                                ) AS RentPmntbyInvocie_1 ON con.contractOID = RentPmntbyInvocie_1.ContractOid
                        WHERE        
                            (RemainingDue > 0) AND (con.IsTerminated = 1)
                        GROUP BY 
                            con.ContractOid) AS OldRentDueDtTERM INNER JOIN
                    [ASPIRESQL].[AspireDakota].[dbo].[Contract] C ON c.contractOID = OldRentDueDtTERM.ContractOid),

Subquery AS (
    SELECT        
        C.ContractOid,
        OppIDTable.opportunityID As opportunityID,
        CASE
            WHEN CurrentDay.[Gross Receivable] <> PreviousDay.[Gross_Receivable__c]
            OR CurrentDay.[Original Gross Receivable] <> PreviousDay.[Original_Gross_Receivable__c]
            OR (CurrentDay.[Gross Receivable] - CurrentDay.[Balance Remaining]) <> (PreviousDay.[Gross_Receivable__c] - PreviousDay.[Balance_Remaining__c])
            OR CurrentDay.[Balance Remaining] <> PreviousDay.[Balance_Remaining__c]
            OR CurrentDay.[Unearned Finance] <> PreviousDay.[Unearned_Finance__c]
            OR CurrentDay.Residual <> PreviousDay.Residual__c
            OR CurrentDay.[Deferred Residual] <> PreviousDay.[Deferred_Residual__c]
            OR CurrentDay.[Deferred Expense] <> PreviousDay.[Deferred_Expense__c]
            OR CurrentDay.[Security Deposit] <> PreviousDay.[Security_Deposit__c]
            THEN 'Data Changed'
            ELSE 'No Changes'
        END AS ChangeStatus,
        CurrentDay.[Gross Receivable] AS CurrentDay_GrossReceivable,
        CurrentDay.[Original Gross Receivable] AS CurrentDay_OriginalGrossReceivable,
        CurrentDay.[Gross Receivable] - CurrentDay.[Balance Remaining] AS CurrentDay_PaymentsMade,
        CurrentDay.[Balance Remaining] AS CurrentDay_BalanceRemaining,
        CurrentDay.[Unearned Finance] AS CurrentDay_UnearnedFinance,
        CurrentDay.Residual AS CurrentDay_Residual,
        CurrentDay.[Deferred Residual] AS CurrentDay_DeferredResidual,
        CurrentDay.[Deferred Expense] AS CurrentDay_DeferredExpense,
        CurrentDay.[Security Deposit] AS CurrentDay_SecurityDeposit,
        ISNULL(NetInvest.[Balance Remaining] - ISNULL(NetInvest.[Unearned Finance], 0) + ISNULL(NetInvest.Residual, 0) - ISNULL(NetInvest.[Deferred Residual], 0) + ISNULL(NetInvest.[Deferred Expense], 0) - ISNULL(NetInvest.[Security Deposit], 0),'')  AS Net_Investment,
        ISNULL(CASE WHEN DPD.DPD IS NULL AND c.IsTerminated = 0 THEN 0 ELSE DPD.DPD END,'') AS DPD,
        ISNULL(NetInvestTerm.[Net Investment],'') AS NI_at_Termination,
        ISNULL(NetInvestTerm.[Payments Made at Term],0) AS Payments_Made_At_Termination,
        ISNULL(NetInvestTerm.[Balance Remaining at Term]*-1,0) AS Balance_Remaining_At_Termination,
        ISNULL(CASE WHEN DPDTerm.DPD IS NULL AND c.IsTerminated = 1 THEN 0 ELSE DPDTerm.DPD END,'') AS DPD_at_Termination
    FROM 
        [ASPIRESQL].[AspireDakota].[dbo].[Contract] C
    LEFT OUTER JOIN
        CurrentDaySnapshot AS CurrentDay ON c.ContractOid = CurrentDay.ContractOid
    LEFT OUTER JOIN
        PreviousDaySnapshot AS PreviousDay ON c.ContractOid = PreviousDay.ContractOid__c
    LEFT OUTER JOIN
        OppIDTable AS OppIDTable ON C.ContractOid = OppIDTable.ref_oid
    LEFT OUTER JOIN
        NetInvest AS NetInvest ON C.ContractOid = NetInvest.ContractOid
    LEFT OUTER JOIN
        DPD ON C.ContractOid = DPD.ContractOid
    LEFT OUTER JOIN
        NetInvestTerm ON C.ContractOid = NetInvestTerm.ContractOid
    LEFT OUTER JOIN
        DPDTerm ON C.ContractOid = DPDTerm.ContractOid
    WHERE
        (C.IsBooked = 1) AND (C.CompanyOid = 1)) 


MERGE INTO Accounting_ASPIRE__c_upsert AS Target
USING (
SELECT 
NULL AS ID, 
sbq.contractOID AS ContractOid__c, 
sbq.opportunityID AS Opportunity__c, 
sbq.CurrentDay_GrossReceivable AS Gross_Receivable__c,
sbq.CurrentDay_OriginalGrossReceivable AS Original_Gross_Receivable__c,
sbq.CurrentDay_PaymentsMade AS Payments_Made__c, 
sbq.CurrentDay_BalanceRemaining AS Balance_Remaining__c, 
sbq.CurrentDay_UnearnedFinance AS Unearned_Finance__c, 
ISNULL(sbq.CurrentDay_Residual,0) AS Residual__c, 
ISNULL(sbq.CurrentDay_DeferredResidual,0) AS Deferred_Residual__c, 
ISNULL(sbq.CurrentDay_DeferredExpense,0) AS Deferred_Expense__c, 
ISNULL(sbq.CurrentDay_SecurityDeposit,0) AS Security_Deposit__c,
ISNULL(sbq.Net_Investment, 0) AS Net_Investment__c,
ISNULL(sbq.DPD, 0) AS DPD__c,
ISNULL(sbq.NI_at_Termination, 0) AS NI_at_Termination__c,
ISNULL(sbq.DPD_at_Termination, 0) AS DPD_at_Termination__c,
ISNULL(sbq.Payments_Made_At_Termination, 0) AS Payments_Made_At_Termination__c,
ISNULL(sbq.Balance_Remaining_At_Termination, 0) AS Balance_Remaining_At_Termination__c
FROM Subquery sbq) AS Source
ON Target.contractOID__c = Source.contractOID__c

WHEN MATCHED THEN
    UPDATE SET
        Target.Opportunity__c = Source.Opportunity__c,
        Target.Gross_Receivable__c = Source.Gross_Receivable__c,
        Target.Original_Gross_Receivable__c = Source.Original_Gross_Receivable__c,
        Target.Payments_Made__c = Source.Payments_Made__c,
        Target.Balance_Remaining__c = Source.Balance_Remaining__c,
        Target.Unearned_Finance__c = ISNULL(Source.Unearned_Finance__c,0),
        Target.Residual__c = ISNULL(Source.Residual__c, 0),
        Target.Deferred_Residual__c = ISNULL(Source.Deferred_Residual__c, 0),
        Target.Deferred_Expense__c = Source.Deferred_Expense__c,
        Target.Security_Deposit__c = ISNULL(Source.Security_Deposit__c, 0),
        Target.Net_Investment__c = ISNULL(Source.Net_Investment__c, 0),
        Target.DPD__c = ISNULL(Source.DPD__c, 0),
        Target.NI_at_Termination__c = ISNULL(Source.NI_at_Termination__c, 0),
        Target.DPD_at_Termination__c = ISNULL(Source.DPD_at_Termination__c, 0),
        Target.Payments_Made_At_Termination__C = ISNULL(Source.Payments_Made_At_Termination__C,0),
        Target.Balance_Remaining_At_termination__C = ISNULL(Source.Balance_Remaining_At_termination__C,0)

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        contractOID__c,
        Opportunity__c,
        Gross_Receivable__c,
        Original_Gross_Receivable__c,
        Payments_Made__c,
        Balance_Remaining__c,
        Unearned_Finance__c,
        Residual__c,
        Deferred_Residual__c,
        Deferred_Expense__c,
        Security_Deposit__c,
        Net_Investment__c,
        DPD__c,
        NI_at_Termination__c,
        DPD_at_Termination__c,
        Payments_Made_At_Termination__C,
        Balance_Remaining_At_termination__C
    ) VALUES (
        Source.ID,
        Source.contractOID__c,
        Source.Opportunity__c,
        Source.Gross_Receivable__c,
        Source.Original_Gross_Receivable__c,
        Source.Payments_Made__c,
        Source.Balance_Remaining__c,
        ISNULL(Source.Unearned_Finance__c, 0),
        ISNULL(Source.Residual__c, 0),
        ISNULL(Source.Deferred_Residual__c, 0),
        Source.Deferred_Expense__c,
        ISNULL(Source.Security_Deposit__c, 0),
        ISNULL(Source.Net_Investment__c,0),
        ISNULL(Source.DPD__c,0),
        ISNULL(Source.NI_at_Termination__c,0),
        ISNULL(Source.DPD_at_Termination__c,0),
        ISNULL(Source.Payments_Made_At_Termination__C,0),
        ISNULL(Source.Balance_Remaining_At_termination__C,0)
    );

