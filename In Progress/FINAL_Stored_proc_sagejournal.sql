DECLARE @DATE DATETIME = CONVERT(DATETIME, '2023-10-31', 102)

DECLARE @MAXJOURNAL NUMERIC = 158109

CREATE TABLE SageSUTVendors (SUTState VARCHAR(2), SageVendorID VARCHAR(10))

INSERT INTO SageSUTVendors (SUTState, SageVendorID)
	VALUES ('AK', 'V04002'),
			('AL', 'V04003'),
			('AR', 'V04004'),
			('AZ', 'V04005'),
			('CA', 'V04006'),
			('CO', 'V04007'),
			('CT', 'V04008'),
			('DC', 'V04009'),
			('DE', 'V04010'),
			('FL', 'V04011'),
			('GA', 'V04012'),
			('HI', 'V04013'),
			('IA', 'V04014'),
			('ID', 'V04015'),
			('IL', 'V04016'),
			('IN', 'V04017'),
			('KS', 'V04018'),
			('KY', 'V04019'),
			('LA', 'V04020'),
			('MA', 'V04021'),
			('MD', 'V04022'),
			('ME', 'V04023'),
			('MI', 'V04024'),
			('MN', 'V04025'),
			('MO', 'V04026'),
			('MS', 'V04027'),
			('MT', 'V04028'),
			('NC', 'V04029'),
			('ND', 'V04030'),
			('NE', 'V04031'),
			('NH', 'V04032'),
			('NJ', 'V04033'),
			('NM', 'V04034'),
			('NV', 'V04035'),
			('NY', 'V04036'),
			('OH', 'V04037'),
			('OK', 'V04038'),
			('OR', 'V04039'),
			('PA', 'V04040'),
			('RI', 'V04041'),
			('SC', 'V04042'),
			('SD', 'V04043'),
			('TN', 'V04044'),
			('TX', 'V04045'),
			('UT', 'V04046'),
			('VA', 'V04047'),
			('VT', 'V04048'),
			('WA', 'V04049'),
			('WI', 'V04050'),
			('WV', 'V04051'),
			('WY', 'V04052')

SELECT	
	'' AS DONOTIMPORT, 
	SageJournalType AS JOURNAL, 
	CONVERT(varchar, PostDate, 101) AS DATE, CONCAT('Aspire Journal ', JournalNumber) AS DESCRIPTION,
	ROW_NUMBER() OVER (PARTITION BY JournalNumber ORDER BY PostDate, ContractId, SageAccount) AS LINE_NO, 
	SageAccount AS ACCT_NO, 
	Location AS LOCATION_ID, 
	10 AS DEPT_ID, 
	ContractType + ' #' + ContractId + ' ' + name + ' - ' + TransactionType AS MEMO,
	TransactionType AS TransactionType, 
	CASE WHEN ProcessOid = '20119' AND AccountId IN ('01-10094', '01-10002') THEN 0 ELSE Debit END AS DEBIT, 
	CASE WHEN ProcessOid = '20119' AND AccountId IN ('01-10094', '01-10002') THEN 0 ELSE Credit END AS CREDIT, 
	'USD' AS CURRENCY, 
	CASE 
		WHEN JournalNumber IN (SELECT JournalNumber WHERE AccountId IN ('01-20025', '01-10040')) THEN 'Draft'
		WHEN ProcessOid IN (20119, 20121, 20143) OR ContractID IS NULL OR (TransactionType IN ('Miscellaneous Billing', 'Booking Adjustment')) THEN 'Draft'
		WHEN JournalNumber IN (SELECT JournalNumber WHERE (SageAccount IN ('42001', '42002')) AND NOT (TransactionType IN ('Miscellaneous Billing', 'Booking Adjustment'))) THEN 'Post'
		ELSE 'Post'
	END AS STATE, 
	ContractId AS GLENTRY_PROJECTID, 
	CASE WHEN SageAccount = '20007' THEN 'V00296' ELSE (CASE WHEN SageAccount = '20006' THEN SageVendorID ELSE NULL END) END AS GLENTRY_VENDORID, 
	JournalNumber
FROM            
	(SELECT        
		JournalNumber, 
		PostDate, 
		AccountId, 
		AccountTitle, 
		CASE WHEN SUM(ISNULL(Debit, 0)) + SUM(ISNULL(Credit, 0)) >= 0 THEN SUM(ISNULL(Debit, 0)) + SUM(ISNULL(Credit, 0)) END AS Debit, 
        CASE WHEN SUM(ISNULL(Debit, 0)) + SUM(ISNULL(Credit, 0)) < 0 THEN (SUM(ISNULL(Debit, 0)) + SUM(ISNULL(Credit, 0))) * - 1 END AS Credit, 
		ContractId, name, ContractType, ProcessOid, TransactionType, 
        CASE WHEN state IS NULL AND AccountID NOT IN ('01-10108') THEN 'E-100' ELSE ISNULL(state, 'E-100') END AS Location, 
		CASE 
			WHEN SageAccount = '42001' AND CASE WHEN SUM(ISNULL(Debit, 0)) + SUM(ISNULL(Credit, 0)) < 0 THEN (SUM(ISNULL(Debit, 0)) + SUM(ISNULL(Credit, 0))) * - 1 END IS NULL THEN '14000'
			WHEN SageAccount = '42001' AND Reason IN ('I', 'CO') AND ISNULL(Debit,0) = 0 THEN '42002'
			ELSE SageAccount 
		END AS SageAccount, 
		CASE WHEN ProcessOid IN (20119) THEN 'BKJ' 
			WHEN ProcessOid IN (20120, 20121) THEN 'ASBJ' 
			WHEN ProcessOid IN (20122, 20135, 20134) THEN 'ACRJ' 
			WHEN ProcessOid IN (20123) THEN 'ABAJ' 
			WHEN ProcessOid IN (20126, 20127) THEN 'AMJ' 
			WHEN ProcessOid IN (20140, 20141) THEN 'CMJ' 
			WHEN ProcessOid IN (20128) THEN 'ACJ' 
			WHEN ProcessOid IN (20143) THEN 'DPJ' 
		END AS SageJournalType,
		reason
	FROM
		(SELECT        
			JournalNumber, 
			PostDate, 
			AccountId, 
			AccountTitle, 
			SUM(Debit) AS Debit, 
			SUM(Credit) AS Credit, 
			ContractId, 
			name, 
			ContractType, 
			ProcessOid, 
			TransactionType, 
			state, 
			SageAccount,
			ltidv2 AS reason
		FROM
			(SELECT
				GeneralLedger.JournalNumber, 
				GeneralLedger.PostDate, 
				GeneralLedger.AccountId, 
				GLAccounts.AccountTitle, 
				GeneralLedger.Debit, 
				GeneralLedger.Credit, 
				Contract.ContractId, 
                GeneralLedger.ProcessOid, 
				CASE WHEN Entity.bus_or_ind = 'B' THEN LTRIM(RTRIM(Entity.name)) ELSE RTRIM(CONCAT(NULLIF(LTRIM(RTRIM(entity.fname)) + ' ', ''), NULLIF(LTRIM(RTRIM(entity.mname)) + ' ', ''), NULLIF(LTRIM(RTRIM(entity.lname)) + ' ', ''), NULLIF(LTRIM(RTRIM(suffix)), ''))) END AS name, 
                CASE WHEN Contract.ContractId LIKE '%R%' THEN 'Rebook' ELSE CASE WHEN Contract.ContractId LIKE '%E%' THEN 'EFA' ELSE 'Lease' END END AS ContractType, 
                LTIValues.descr AS TransactionType, 
				CASE WHEN GeneralLedger.AccountId = '01-10108' THEN Location.state ELSE NULL END AS state, 
				LEFT(GLAccounts.AccountTitle, 5) AS SageAccount,
				TermReason.ltidv2
			FROM
				Entity RIGHT OUTER JOIN
                Location RIGHT OUTER JOIN
                InvoiceDetail ON Location.oid = InvoiceDetail.LocationOid RIGHT OUTER JOIN
                GeneralLedgerReference ON InvoiceDetail.InvoiceDetailOid = GeneralLedgerReference.InvoiceDetailOid RIGHT OUTER JOIN
                GeneralLedgerAccountId LEFT OUTER JOIN
                GLAccounts ON GeneralLedgerAccountId.GLAccountsOid = GLAccounts.GLAccountsOid RIGHT OUTER JOIN
                GeneralLedger ON GeneralLedgerAccountId.GeneralLedgerAccountIdOid = GeneralLedger.GeneralLedgerAccountIdOid ON 
                GeneralLedgerReference.GeneralLedgerReferenceOid = GeneralLedger.GeneralLedgerReferenceOid LEFT OUTER JOIN
                LTIValues ON GeneralLedger.ProcessOid = LTIValues.oid LEFT OUTER JOIN
                Contract ON GeneralLedgerAccountId.ContractOid = Contract.ContractOid ON Entity.oid = Contract.EntityOid
				LEFT OUTER JOIN 
					(SELECT 
						MAX(cr.ContractRewriteOid) as MAXContractRewriteOid,
						cr.ContractOID,
						contract.ContractId,
						cr.TypeOid,
						lti1.data_value as ltidv1,
						cr.ReasonCodeOid,
						lti2.data_value as ltidv2 
					FROM 
						ContractRewrite cr
						LEFT OUTER JOIN LTIValues lti1 ON cr.typeoid = lti1.oid
						LEFT OUTER JOIN LTIValues lti2 ON cr.ReasonCodeOid = lti2.oid
						LEFT OUTER JOIN Contract ON cr.ContractOid = contract.Contractoid
					WHERE
						cr.ReasonCodeOid IS NOT NULL
						AND lti2.data_value IN ('EOL', 'ES', 'IC', 'UW', 'I', 'CO')
					GROUP BY
						cr.ContractOID,
						contract.ContractId,
						cr.TypeOid,
						lti1.data_value,
						cr.ReasonCodeOid,
						lti2.data_value) AS TermReason ON Contract.Contractid = TermReason.ContractId
			WHERE
				(GeneralLedgerReference.CompanyOid = 1) 
				AND (GeneralLedger.PostDate > EOMONTH(@DATE,-1)) 
				AND (GeneralLedger.PostDate <= EOMONTH(@DATE,0))) AS GLDetail
            GROUP BY
				JournalNumber, 
				PostDate, 
				AccountId, 
				AccountTitle, 
				ContractId, 
				name, 
				ContractType, 
				ProcessOid, 
				TransactionType, 
				state, 
				SageAccount,
				ltidv2) AS GLExtra
			GROUP BY 
				JournalNumber, 
				PostDate, 
				AccountId, 
				AccountTitle, 
				ContractId, 
				name, 
				ContractType, 
				ProcessOid, 
				TransactionType, 
				state, 
				SageAccount,
				reason,
				debit) AS GLforSage LEFT OUTER JOIN
				(SELECT 
					SUTState, 
					SageVendorID FROM SageSUTVendors) AS SageSUTVendors ON GLforSage.Location = SageSUTVendors.SUTState
WHERE 
	(CASE WHEN ProcessOid = '20119' AND AccountId IN ('01-10094', '01-10002') THEN 0 ELSE Debit END <> 0  OR CASE WHEN ProcessOid = '20119' AND AccountId IN ('01-10094', '01-10002') THEN 0 ELSE Credit END <> 0)
	AND NOT ((TransactionType LIKE '%Adj%' OR TransactionType LIKE '%MOD%' ) AND (SageAccount = '11004' OR SageAccount = '14006'))
	--AND JournalNumber > @MAXJOURNAL
ORDER BY 
	JournalNumber, DATE, ContractId, ACCT_NO
DROP TABLE SageSUTVendors;