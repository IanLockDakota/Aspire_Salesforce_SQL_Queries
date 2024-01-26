SELECT
	GrossNoMod.ContractOid,
	GrossNoMod.[Gross Receivable],
	GrossNoMod.[Gross Receivable2]
FROM
	(SELECT
		C5.contractOID,
		ISNULL(SUM(CASE WHEN MyTable6.AccountId = '01-10089' AND MyTable6.ProcessOid IN (20119, 20126, 20127, 20140, 20141) THEN (ISNULL(MyTable6.Debit, 0) + ISNULL(MyTable6.Credit, 0)) END),0) AS [Gross Receivable],
		ISNULL(SUM(CASE WHEN MyTable6.AccountId = '01-10089' AND MyTable6.ProcessOid IN (20119, 20126, 20127) THEN (ISNULL(MyTable6.Debit, 0) + ISNULL(MyTable6.Credit, 0)) END),0) AS [Gross Receivable2]
	FROM
		CONTRACT C5 LEFT OUTER JOIN
		(SELECT 
			GLAD2.ContractOid, 
			GL3.GeneralLedgerOid, 
			GL3.CreatedDateTime, 
			GL3.ProcessOid, 
			GL3.BatchIdentifier, 
			GL3.HeaderIdentifier, 
			GL3.PostDate, 
			GL3.AccountId, 
			GL3.AccountTypeOid, 
			GL3.EffectiveDate, 
			GL3.JournalNumber, 
			GL3.Credit, 
			GL3.Debit
		FROM 
			GeneralLedger GL3 LEFT OUTER JOIN
			GeneralLedgerAccountID GLAD2 ON GL3.GeneralLedgerAccountIdOid = GLAD2.GeneralLedgerAccountIdOid) as MyTable6 ON c5.contractOID = myTable6.ContractOid
		WHERE 
			(C5.IsBooked = 1) AND (C5.CompanyOid = 1) AND (C5.IsTerminated = 1)
		GROUP BY 
			C5.ContractOid) AS GrossNoMod
WHERE
	GrossNoMod.[Gross Receivable] <> GrossNoMod.[Gross Receivable2]
