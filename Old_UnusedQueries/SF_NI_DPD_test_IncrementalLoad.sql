/*
Name: NetInvestment

ASPIRE SQLS Table Dependencies:
    - Contract
    - GeneralLedger
    - GeneralLedgerAccountId
    - GenericField
    - cdataGenericValue
    - InvoiceDetail
    - InvoicePaymentHistory

Salesforce Backups Table Dependencies:
    - Accounting_ASPIRE__c_upsert

SF Object Dependencies:
    - Accounting_ASPIRE__c

Last change: 12/5/2023

Other Notes:
    - I believe termatDPD is the only field that needs to be added.
*/

MERGE INTO Accounting_ASPIRE__c_upsert AS Target
USING (SELECT
    NULL AS ID,
    Contract.ContractOid AS ContractOID__c,
    OppIDTable.opportunityID AS OpportunityID__c,
    ISNULL(NIValue.[Balance Remaining] - ISNULL(NIValue.[Unearned Finance], 0) + ISNULL(NIValue.Residual, 0) - ISNULL(NIValue.[Deferred Residual], 0) + ISNULL(NIValue.[Deferred Expense], 0) - ISNULL(NIValue.[Security Deposit], 0),'')  AS Net_Investment__c,
    ISNULL(CASE WHEN CurrentDPD.DPD IS NULL AND Contract.IsTerminated = 0 THEN 0 ELSE CurrentDPD.DPD END,'') AS DPD__c,
    ISNULL(NITerm.[Net Investment],'') AS NI_at_Termination__c,
    ISNULL(CASE WHEN DPDatTerm.DPD IS NULL AND Contract.IsTerminated = 1 THEN 0 ELSE DPDatTerm.DPD END,'') AS DPD_at_Termination__c
FROM            
    [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] Contract
LEFT OUTER JOIN

/* NetInvestment */

    (SELECT GLA.ContractOid,
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
        FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GeneralLedger] GL
                INNER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[GeneralLedgerAccountId] GLA
                            ON GL.GeneralLedgerAccountIdOid = GLA.GeneralLedgerAccountIdOid INNER JOIN
                                Contract C on GLA.ContractOid = c.ContractOid
        WHERE (GL.PostDate <= GETDATE()) AND (c.IsTerminated = 0)
        GROUP BY GLA.ContractOid) AS NIValue ON Contract.ContractOid = NIValue.ContractOid 

LEFT OUTER JOIN

/* NetInvestment at termination */
    (SELECT
	c2.ContractOid,
	((ISNULL(Mytable2.[Balance Remaining],0)
    - ISNULL(Mytable2.[Unearned Finance], 0)
    + ISNULL(Mytable2.Residual, 0)
    - ISNULL(Mytable2.[Deferred Residual], 0)
    + ISNULL(Mytable2.[Deferred Expense], 0)
    - ISNULL(Mytable2.[Security Deposit], 0)) * -1) AS [Net Investment]
FROM
	[ASPIRESQL].[AspireDakotaTest].[dbo].[contract] c2 LEFT OUTER JOIN
(SELECT
		C1.contractOID,
		ISNULL(SUM(CASE WHEN (MyTable.AccountId IN ('01-10089', '01-10090')) THEN ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0) END),0) AS [Balance Remaining], 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10092') THEN (ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0)) END),0) * -1 AS [Unearned Finance], 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10091') THEN ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0) END),0) AS Residual, 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10093') THEN (ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0)) END),0) * -1 AS [Deferred Residual], 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10094') THEN ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0) END),0) AS [Deferred Expense], 
		ISNULL(SUM(CASE WHEN (MyTable.AccountId = '01-10130') THEN (ISNULL(MyTable.Debit, 0) + ISNULL(MyTable.Credit, 0)) END),0) * -1 AS [Security Deposit]
	FROM
	[ASPIRESQL].[AspireDakotaTest].[dbo].[CONTRACT] C1 LEFT OUTER JOIN
	(SELECT GLAD2.ContractOid, GL3.GeneralLedgerOid, GL3.CreatedDateTime, GL3.ProcessOid, GL3.BatchIdentifier, GL3.HeaderIdentifier, GL3.PostDate, GL3.AccountId, GL3.AccountTypeOid, GL3.EffectiveDate, GL3.JournalNumber, GL3.Credit, GL3.Debit
	FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GeneralLedger] GL3 LEFT OUTER JOIN
	[ASPIRESQL].[AspireDakotaTest].[dbo].[GeneralLedgerAccountID] GLAD2 ON GL3.GeneralLedgerAccountIdOid = GLAD2.GeneralLedgerAccountIdOid
	WHERE ProcessOid = 20143) as MyTable ON c1.contractOID = myTable.ContractOid

	WHERE (C1.IsBooked = 1) AND (C1.CompanyOid = 1) AND (C1.IsTerminated = 1)

	GROUP BY C1.ContractOid) as Mytable2 ON c2.contractOID = mytable2.contractOID

	WHERE (c2.IsBooked = 1) AND (c2.CompanyOid = 1) AND (c2.IsTerminated = 1)) AS NITerm ON NITerm.ContractOid = Contract.ContractOid 

LEFT OUTER JOIN

/* Days past due */

    (SELECT        
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
                FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] contr LEFT OUTER JOIN
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
                                    [ASPIRESQL].[AspireDakotaTest].[dbo].[InvoiceDetail] AS InvoiceDetail_1
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
                                    [ASPIRESQL].[AspireDakotaTest].[dbo].[InvoicePaymentHistory] AS InvoicePaymentHistory_1 
                                RIGHT OUTER JOIN
                                    [ASPIRESQL].[AspireDakotaTest].[dbo].[InvoiceDetail] AS InvoiceDetail_5 
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
                        ) AS RentPmntbyInvocie_1 ON contract.contractOID = RentPmntbyInvocie_1.ContractOid
                        WHERE        
                            (RemainingDue > 0) AND (contract.IsTerminated = 0)
                        GROUP BY 
                            contract.ContractOid) AS OldRentDueDtTERM INNER JOIN
                    Contract C ON c.contractOID = OldRentDueDtTERM.ContractOid) AS CurrentDPD ON Contract.ContractOid = CurrentDPD.ContractOid 

LEFT OUTER JOIN

/* Days past due at term */

    (SELECT        
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
                FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] con LEFT OUTER JOIN
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
                                    [ASPIRESQL].[AspireDakotaTest].[dbo].[InvoiceDetail] AS InvoiceDetail_1
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
                                    [ASPIRESQL].[AspireDakotaTest].[dbo].[InvoicePaymentHistory] AS InvoicePaymentHistory_1 
                                RIGHT OUTER JOIN
                                    [ASPIRESQL].[AspireDakotaTest].[dbo].[InvoiceDetail] AS InvoiceDetail_5 
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
                        ) AS RentPmntbyInvocie_1 ON contract.contractOID = RentPmntbyInvocie_1.ContractOid
                        WHERE        
                            (RemainingDue > 0) AND (contract.IsTerminated = 1)
                        GROUP BY 
                            contract.ContractOid) AS OldRentDueDtTERM INNER JOIN
                    [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] C ON c.contractOID = OldRentDueDtTERM.ContractOid) AS DPDatTerm ON con.ContractOID = DPDatTerm.contractOID INNER JOIN

        /* OppID Subqueryy */

        (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
        FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GenericField] GF 
        LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid
        LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
        WHERE GF.oid = 23
        GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppIDTable ON contract.ContractOid = OppIDTable.ContractOID

WHERE 
    (Contract.IsBooked = 1) AND (Contract.CompanyOid = 1)
ORDER BY 
    Contract.ContractOid) AS Source
ON Target.Opportunity__c = Source.Opportunity__c -- Add any additional conditions for matching records

WHEN MATCHED THEN
    UPDATE SET
        Target.Net_Investment__c = Source.Net_Investment__c,
        Target.DPD__c = Source.DPD__c,
        Target.NI_at_Termination__c = Source.NI_at_Termination__c,
        Target.DPD_at_Termination__c = Source.DPD_at_Termination__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        Net_Investment__c,
        DPD__c,
        NI_at_Termination__c,
        DPD_at_Termination__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.Net_Investment__c,
        Source.DPD__c,
        Source.NI_at_Termination__c,
        Source.DPD_at_Termination__c
    );

