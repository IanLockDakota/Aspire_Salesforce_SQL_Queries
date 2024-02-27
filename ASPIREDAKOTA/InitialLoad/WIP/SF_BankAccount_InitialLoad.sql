-- Need to determine what level ths information is going to...Account? Opportunity?
-- 

SELECT DISTINCT
	AB.ACHBankOID,
	ABA.AchBankAccountOid,
	AB.EntityOid,
	EntityContractInfo.name,
	EntityContractInfo.role_type,
	EntityContractInfo.ref_oid as ContractOID,
	OppIDTable.opportunityID,
	AB.BankName,
	AB.DfiIdentificationNumber as Routing,
	ABA.AccountNumber AS UncensoredBankAccount,
	STUFF(ABA.AccountNumber, 1, /*length*/CASE WHEN LEN(ABA.AccountNumber) < 4 THEN LEN(ABA.AccountNumber) ELSE LEN(ABA.AccountNumber) - 4 END, 
	REPLICATE('x', CASE WHEN LEN(ABA.AccountNumber) < 4 THEN LEN(ABA.AccountNumber) ELSE LEN(ABA.AccountNumber) - 4 END)) AS AccountNumber__c,
	lti1.descr,
	lti2.descr,
	ABA.active,
	ABA.LastChangeOperator,
	ABA.LastChangeDateTime
FROM 
	AchBank AB
	LEFT OUTER JOIN AchBankAccount ABA ON AB.AchBankOid = ABA.AchBankOid
	LEFT OUTER JOIN LTIValues lti1 ON ABA.AccountCategoryOid = lti1.oid
	LEFT OUTER JOIN LTIValues lti2 ON ABA.AccountTypeOid = lti2.oid
	LEFT OUTER JOIN
		(SELECT
			e.oid,
			e.name,
			ce.ref_oid,
			ce.role_type
		FROM
			Entity e
			LEFT OUTER JOIN ChildEntity ce ON e.oid = ce.entt_oid
		WHERE
			role_type = 'cust') AS EntityContractInfo ON AB.EntityOid = EntityContractInfo.oid
	LEFT OUTER JOIN Contract c ON EntityContractInfo.ref_oid = c.ContractOid
	LEFT OUTER JOIN ContractEFT CEFT ON ABA.AchBankAccountOid = CEFT.ACHBankAccountOid AND EntityContractInfo.ref_oid = CEFT.ContractOid
	LEFT OUTER JOIN (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
                            FROM GenericField GF 
                            LEFT OUTER JOIN cdataGenericValue GV ON GF.oid = GV.genf_oid
                            LEFT OUTER JOIN Contract c ON c.ContractOid = gv.ref_oid
                            WHERE GF.oid = 23
                            GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                        ) AS OppIDTable ON EntityContractInfo.ref_oid = OppIDTable.ContractOID
WHERE
	(ABA.AchBankAccountOid IS NOT NULL) AND (c.isbooked = 1) AND (c.CompanyOid = 1) AND (OppIDTable.opportunityID IS NOT NULL)
ORDER BY
	AB.EntityOid, EntityContractInfo.ref_oid